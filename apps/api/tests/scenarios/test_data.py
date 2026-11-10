"""Datos: índices, historiales por tandas, avisos varados y migraciones seguras."""

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
from app.modules.users.seed_admin import main as sembrar

API_ROOT = Path(__file__).resolve().parents[2]
# conftest.py deja acá la base de pruebas antes de importar los tests.
TEST_DATABASE_URL = os.environ["DATABASE_URL"]
CONTRASENA = "ClubNahuel1"
URL_MIGRACIONES = TEST_DATABASE_URL.rsplit("/", 1)[0] + "/club_rev03_migraciones_test"
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
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = sign_in(f"admin.{s}@club.com", CONTRASENA)
    assert token is not None
    return token


def _past(member: Member, cantidad: int) -> None:
    """[cantidad] reservas ya jugadas del socio, una por día hacia atrás."""
    with member.engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, :e, h - make_interval(days => n), h - make_interval(days => n)"
                " + interval '1 hour', 38000, 38000"
                " FROM generate_series(1, :c) AS n,"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires') AS h) AS t"
            ),
            {"u": member.user_id, "e": member.space_id, "c": cantidad},
        )


def _indices(engine: Engine, tabla: str) -> list[str]:
    with engine.connect() as conn:
        return [
            str(f.indexdef)
            for f in conn.execute(
                text("SELECT indexdef FROM pg_indexes WHERE tablename = :t"), {"t": tabla}
            )
        ]


def test_el_historial_propio_tiene_un_indice_por_socio(engine: Engine) -> None:
    """el historial propio se resuelve con un índice por socio @REV-03-S1"""
    indices = _indices(engine, "booking")

    assert any("(user_id" in i for i in indices)


def _tie(member: Member) -> None:
    """Una reserva más, en otra cancha de la misma sede, con el mismo inicio que la vigésima."""
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


MARCADORES_INVALIDOS = ["no-es", "", "AAAA", "eyJ4IjoxfQ", "MjAyNi0xMS0xMlQwMDowMDowMHxhYmM"]


def test_el_historial_global_tiene_un_indice_por_fecha(engine: Engine) -> None:
    """el historial global se ordena por un índice de inicio @REV-03-S3"""
    indices = _indices(engine, "booking")

    assert any("(starts_at DESC, id DESC)" in i for i in indices)


def test_quien_cancelo_y_que_aviso_reemplazo_tienen_indice(engine: Engine) -> None:
    """quién canceló y qué aviso reemplazó a otro se consultan por índice @REV-03-S4"""
    assert any("(canceled_by" in i for i in _indices(engine, "booking"))
    assert any("(replaced_by" in i for i in _indices(engine, "notification"))


def _deliveries(member: Member) -> list[str]:
    with member.engine.connect() as conn:
        return [
            str(f.delivery)
            for f in conn.execute(
                text("SELECT delivery FROM notification WHERE user_id = :u ORDER BY id"),
                {"u": member.user_id},
            )
        ]


def _strand(member: Member, hace: str, intentos: int = 1) -> None:
    with member.engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET envio = 'enviando', enviada_en = NULL,"
                " tomada_en = now() - CAST(:hace AS interval), intentos = :i"
                " WHERE usuario_id = :u"
            ),
            {"u": member.user_id, "hace": hace, "i": intentos},
        )


def _cancel(member: Member, desde: str) -> None:
    reserva = member.book(desde)
    r = member.api.post(f"/bookings/{reserva['id']}/cancel", headers=member.session)
    assert r.status_code == 200


def _dispatch(member: Member, channel: FakeChannel) -> None:
    with member.engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), channel, member.user_id)


class _CanalQueSeCae(FakeChannel):
    """El proceso muere justo después de tomar el aviso, antes de saber si salió."""

    def send(self, tokens: list[str], aviso: Any) -> Any:
        raise SystemExit("el proceso se cayó")


def _reminder(member: Member, envio: str, hace: str) -> None:
    reserva: dict[str, Any] = member.book("20:00")
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
            {"u": member.user_id, "r": reserva["id"], "envio": envio, "hace": hace},
        )


def _sweep(member: Member, channel: FakeChannel) -> None:
    with member.engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), channel, member.user_id)
        send_reminders(NotificationsSql(conn), channel, at_time(19, 10), member.user_id)


@pytest.fixture
def migrations_db(engine: Engine) -> Iterator[tuple[Engine, AlembicConfig]]:
    """Una base aparte, vacía, para subir y bajar migraciones sin tocar la de la suite."""
    admin = create_engine(TEST_DATABASE_URL.rsplit("/", 1)[0] + "/postgres", isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        conn.execute(text("DROP DATABASE IF EXISTS club_rev03_migraciones_test WITH (FORCE)"))
        conn.execute(text("CREATE DATABASE club_rev03_migraciones_test"))
    admin.dispose()
    base = create_engine(URL_MIGRACIONES)
    alembic = AlembicConfig(str(API_ROOT / "alembic.ini"))
    alembic.set_main_option("sqlalchemy.url", URL_MIGRACIONES.replace("%", "%%"))
    yield base, alembic
    base.dispose()


def _seed(base: Engine) -> None:
    with base.begin() as conn:
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


def _bookings(base: Engine) -> int:
    with base.connect() as conn:
        return int(conn.execute(text("SELECT count(*) FROM reserva")).scalar_one())


def test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo(
    migrations_db: tuple[Engine, AlembicConfig],
) -> None:
    """la migración nueva no bloquea las tablas mientras la versión anterior atiende @REV-03-S7"""
    base, alembic = migrations_db
    command.upgrade(alembic, "0007")
    _seed(base)
    bloqueo = base.connect()
    bloqueo.execute(text("LOCK TABLE reserva IN ACCESS EXCLUSIVE MODE"))
    resultado: list[BaseException] = []
    hilo = threading.Thread(
        target=lambda: _capture(resultado, lambda: command.upgrade(alembic, "0008"))
    )

    hilo.start()
    hilo.join(timeout=60)
    bloqueo.rollback()
    bloqueo.close()

    assert not hilo.is_alive()
    assert isinstance(resultado[0], OperationalError)
    assert "lock timeout" in str(resultado[0])
    command.upgrade(alembic, "0008")
    with base.connect() as conn:
        invalidos = conn.execute(
            text("SELECT count(*) FROM pg_index WHERE NOT indisvalid")
        ).scalar_one()
    assert invalidos == 0
    assert _bookings(base) == 1


def _capture(resultado: list[BaseException], accion: Callable[[], None]) -> None:
    try:
        accion()
    except BaseException as e:  # noqa: BLE001 — el test afirma sobre el error que se guarda
        resultado.append(e)


def _schema(base: Engine) -> set[tuple[str, ...]]:
    with base.connect() as conn:
        columnas = conn.execute(
            text(
                "SELECT table_name, column_name, data_type, is_nullable"
                " FROM information_schema.columns WHERE table_schema = 'public'"
            )
        )
        indices = conn.execute(
            text("SELECT tablename, indexdef, '', '' FROM pg_indexes WHERE schemaname = 'public'")
        )
        return {tuple(str(c) for c in f) for f in [*columnas, *indices]}


@pytest.mark.parametrize(
    ("anterior", "revision"), list(zip(["0001", *REVISIONS], REVISIONS, strict=False))
)
def test_cada_migracion_va_y_vuelve_con_datos(
    migrations_db: tuple[Engine, AlembicConfig], anterior: str, revision: str
) -> None:
    """la suite vigila la ida y vuelta de las migraciones con datos
    @REV-03-S8 @assumption:REV-03-ASM-06
    """
    base, alembic = migrations_db
    command.upgrade(alembic, "0001")
    _seed(base)
    command.upgrade(alembic, anterior)
    antes = _schema(base)

    command.upgrade(alembic, revision)
    despues = _schema(base)
    command.downgrade(alembic, "-1")
    vuelta = _schema(base)
    command.upgrade(alembic, revision)

    assert vuelta == antes
    assert _schema(base) == despues
    assert _bookings(base) == 1
