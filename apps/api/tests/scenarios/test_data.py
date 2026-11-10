"""Data: indexes, batched histories, stranded notices and safe migrations."""

import os
import threading
from collections.abc import Callable, Iterator
from pathlib import Path
from typing import Any

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from fastapi.testclient import TestClient
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.exc import OperationalError
from test_reminder import FakeChannel, Member, at_time, a_member

from app.modules.notifications.use_cases import dispatch_pending, send_reminders
from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.push import push_channel
from app.modules.users.seed_admin import main as seed_admin

API_ROOT = Path(__file__).resolve().parents[2]
# conftest.py leaves the test database here before importing the tests.
TEST_DATABASE_URL = os.environ["DATABASE_URL"]
PASSWORD = "ClubNahuel1"
MIGRATIONS_URL = TEST_DATABASE_URL.rsplit("/", 1)[0] + "/club_rev03_migraciones_test"
REVISIONS = ["0002", "0003", "0004", "0005", "0006", "0007", "0008"]


@pytest.fixture
def channel(api: TestClient) -> Iterator[FakeChannel]:
    channel = FakeChannel()
    api.app.dependency_overrides[push_channel] = lambda: channel
    yield channel
    api.app.dependency_overrides.pop(push_channel, None)


@pytest.fixture
def member(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> Member:
    return a_member(api, engine, sign_in, unique)


@pytest.fixture
def admin_token(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> str:
    s = unique()
    monkeypatch.setenv("ADMIN_CONTRASENA", PASSWORD)
    args = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert seed_admin(args) == 0
    token = sign_in(f"admin.{s}@club.com", PASSWORD)
    assert token is not None
    return token


def _past(member: Member, count: int) -> None:
    """[count] already played bookings of the member, one per day going backwards."""
    with member.engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, :e, h - make_interval(days => n), h - make_interval(days => n)"
                " + interval '1 hour', 38000, 38000"
                " FROM generate_series(1, :c) AS n,"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires') AS h) AS t"
            ),
            {"u": member.user_id, "e": member.space_id, "c": count},
        )


def _indexes(engine: Engine, table: str) -> list[str]:
    with engine.connect() as conn:
        return [
            str(f.indexdef)
            for f in conn.execute(
                text("SELECT indexdef FROM pg_indexes WHERE tablename = :t"), {"t": table}
            )
        ]


def test_the_own_history_has_an_index_per_member(engine: Engine) -> None:
    """the own history is resolved with an index per member @REV-03-S1"""
    indexes = _indexes(engine, "booking")

    assert any("(user_id" in i for i in indexes)


def _tie(member: Member) -> None:
    """One more booking, on another court of the same venue, with the same start as the twentieth."""
    with member.engine.begin() as conn:
        conn.execute(
            text(
                "WITH e AS (INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour) SELECT venue_id, sport, kind, number + 1,"
                " name || '_bis', covered, lit, price_per_hour FROM space"
                " WHERE id = :e RETURNING id)"
                " INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, e.id, h - interval '20 days', h - interval '20 days'"
                " + interval '1 hour', 38000, 38000 FROM e,"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires') AS h) AS t"
            ),
            {"u": member.user_id, "e": member.space_id},
        )


INVALID_MARKERS = ["no-es", "", "AAAA", "eyJ4IjoxfQ", "MjAyNi0xMS0xMlQwMDowMDowMHxhYmM"]


def test_the_global_history_has_an_index_per_date(engine: Engine) -> None:
    """the global history is ordered by a start index @REV-03-S3"""
    indexes = _indexes(engine, "booking")

    assert any("(starts_at DESC, id DESC)" in i for i in indexes)


def test_who_cancelled_and_which_notice_replaced_another_have_an_index(engine: Engine) -> None:
    """who cancelled and which notice replaced another are queried by index @REV-03-S4"""
    assert any("(canceled_by" in i for i in _indexes(engine, "booking"))
    assert any("(replaced_by" in i for i in _indexes(engine, "notification"))


def _deliveries(member: Member) -> list[str]:
    with member.engine.connect() as conn:
        return [
            str(f.delivery)
            for f in conn.execute(
                text("SELECT delivery FROM notification WHERE user_id = :u ORDER BY id"),
                {"u": member.user_id},
            )
        ]


def _strand(member: Member, ago: str, attempts: int = 1) -> None:
    with member.engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET envio = 'enviando', enviada_en = NULL,"
                " tomada_en = now() - CAST(:hace AS interval), intentos = :i"
                " WHERE usuario_id = :u"
            ),
            {"u": member.user_id, "hace": ago, "i": attempts},
        )


def _cancel(member: Member, start: str) -> None:
    booking = member.book(start)
    r = member.api.post(f"/bookings/{booking['id']}/cancel", headers=member.session)
    assert r.status_code == 200


def _dispatch(member: Member, channel: FakeChannel) -> None:
    with member.engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), channel, member.user_id)


class _ChannelThatCrashes(FakeChannel):
    """The process dies right after taking the notice, before knowing whether it went out."""

    def send(self, tokens: list[str], aviso: Any) -> Any:
        raise SystemExit("el proceso se cayó")


def _reminder(member: Member, delivery: str, ago: str) -> None:
    booking: dict[str, Any] = member.book("20:00")
    with member.engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                " reserva_inicio, envio, creado_en, tomada_en, intentos)"
                " SELECT :u, 'recordatorio', 'Tu turno es en una hora', 'Fútbol 5 en la sede',"
                " id, inicio, :envio, now() - CAST(:hace AS interval),"
                " CASE WHEN :envio = 'enviando' THEN now() - CAST(:hace AS interval) END,"
                " CASE WHEN :envio = 'enviando' THEN 1 ELSE 0 END"
                " FROM reserva WHERE id = :r"
            ),
            {"u": member.user_id, "r": booking["id"], "envio": delivery, "hace": ago},
        )


def _sweep(member: Member, channel: FakeChannel) -> None:
    with member.engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), channel, member.user_id)
        send_reminders(NotificationsSql(conn), channel, at_time(19, 10), member.user_id)


@pytest.fixture
def migrations_db(engine: Engine) -> Iterator[tuple[Engine, AlembicConfig]]:
    """A separate, empty database to migrate up and down without touching the suite's one."""
    admin = create_engine(
        TEST_DATABASE_URL.rsplit("/", 1)[0] + "/postgres", isolation_level="AUTOCOMMIT"
    )
    with admin.connect() as conn:
        conn.execute(text("DROP DATABASE IF EXISTS club_rev03_migraciones_test WITH (FORCE)"))
        conn.execute(text("CREATE DATABASE club_rev03_migraciones_test"))
    admin.dispose()
    db = create_engine(MIGRATIONS_URL)
    alembic = AlembicConfig(str(API_ROOT / "alembic.ini"))
    alembic.set_main_option("sqlalchemy.url", MIGRATIONS_URL.replace("%", "%%"))
    yield db, alembic
    db.dispose()


def _seed(db: Engine) -> None:
    with db.begin() as conn:
        conn.execute(
            text(
                "WITH u AS (INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni,"
                " fecha_nacimiento) VALUES ('uid-ana', 'ana@correo.com', 'Ana', 'Rios',"
                " '30111222', '1990-01-01') RETURNING id),"
                " s AS (INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES ('Sede Haedo', 'Av. Vergara', 1850, '08:00', '23:00',"
                " ARRAY[1,2,3,4,5,6,7]) RETURNING id),"
                " e AS (INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora) SELECT id, 'Futbol', 'F5', 1,"
                " 'Haedo_Vergara_1850_Futbol_F5_1', false, true, 38000 FROM s RETURNING id)"
                " INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT u.id, e.id, h, h + interval '1 hour', 38000, 38000 FROM u, e,"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
                " + interval '1 day' AS h) AS t"
            )
        )


def _bookings(db: Engine) -> int:
    with db.connect() as conn:
        return int(conn.execute(text("SELECT count(*) FROM reserva")).scalar_one())


def test_the_new_migration_does_not_wait_on_a_lock(
    migrations_db: tuple[Engine, AlembicConfig],
) -> None:
    """the new migration does not lock the tables while the previous version serves @REV-03-S7"""
    db, alembic = migrations_db
    command.upgrade(alembic, "0007")
    _seed(db)
    lock = db.connect()
    lock.execute(text("LOCK TABLE reserva IN ACCESS EXCLUSIVE MODE"))
    result: list[BaseException] = []
    thread = threading.Thread(
        target=lambda: _capture(result, lambda: command.upgrade(alembic, "0008"))
    )

    thread.start()
    thread.join(timeout=60)
    lock.rollback()
    lock.close()

    assert not thread.is_alive()
    assert isinstance(result[0], OperationalError)
    assert "lock timeout" in str(result[0])
    command.upgrade(alembic, "0008")
    with db.connect() as conn:
        invalid = conn.execute(
            text("SELECT count(*) FROM pg_index WHERE NOT indisvalid")
        ).scalar_one()
    assert invalid == 0
    assert _bookings(db) == 1


def _capture(result: list[BaseException], action: Callable[[], None]) -> None:
    try:
        action()
    except BaseException as e:  # noqa: BLE001 — the test asserts on the error that is stored
        result.append(e)


def _schema(db: Engine) -> set[tuple[str, ...]]:
    with db.connect() as conn:
        columns = conn.execute(
            text(
                "SELECT table_name, column_name, data_type, is_nullable"
                " FROM information_schema.columns WHERE table_schema = 'public'"
            )
        )
        indexes = conn.execute(
            text("SELECT tablename, indexdef, '', '' FROM pg_indexes WHERE schemaname = 'public'")
        )
        return {tuple(str(c) for c in f) for f in [*columns, *indexes]}


@pytest.mark.parametrize(
    ("previous", "revision"), list(zip(["0001", *REVISIONS], REVISIONS, strict=False))
)
def test_each_migration_goes_up_and_back_with_data(
    migrations_db: tuple[Engine, AlembicConfig], previous: str, revision: str
) -> None:
    """the suite watches the migrations' round trip with data
    @REV-03-S8 @assumption:REV-03-ASM-06
    """
    db, alembic = migrations_db
    command.upgrade(alembic, "0001")
    _seed(db)
    command.upgrade(alembic, previous)
    before = _schema(db)

    command.upgrade(alembic, revision)
    after = _schema(db)
    command.downgrade(alembic, "-1")
    back = _schema(db)
    command.upgrade(alembic, revision)

    assert back == before
    assert _schema(db) == after
    assert _bookings(db) == 1
