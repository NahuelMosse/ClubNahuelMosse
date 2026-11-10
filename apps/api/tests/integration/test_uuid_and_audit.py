"""DAT-01: UUIDv7 keys and audit columns on the 9 tables (migration 0010)."""

import os
import uuid
from collections.abc import Iterator
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Connection, create_engine, text
from sqlalchemy.engine import make_url

API_ROOT = Path(__file__).resolve().parents[2]

TABLES_WITH_ID = (
    "usuario",
    "sede",
    "espacio",
    "reserva",
    "enlace_recuperacion",
    "correo_saliente",
    "dispositivo",
    "notificacion",
)

REFERENCES = {
    ("sede", "creado_por", "usuario"),
    ("sede", "modificado_por", "usuario"),
    ("sede", "dado_de_baja_por", "usuario"),
    ("espacio", "sede_id", "sede"),
    ("espacio", "creado_por", "usuario"),
    ("espacio", "modificado_por", "usuario"),
    ("espacio", "dado_de_baja_por", "usuario"),
    ("reserva", "usuario_id", "usuario"),
    ("reserva", "espacio_id", "espacio"),
    ("reserva", "cancelada_por", "usuario"),
    ("enlace_recuperacion", "usuario_id", "usuario"),
    ("dispositivo", "usuario_id", "usuario"),
    ("notificacion", "usuario_id", "usuario"),
    ("notificacion", "reserva_id", "reserva"),
    ("notificacion", "reemplazada_por", "notificacion"),
    ("notificacion_reserva", "notificacion_id", "notificacion"),
    ("notificacion_reserva", "reserva_id", "reserva"),
}

CURRENT_TABLES_WITH_ID = (
    "app_user",
    "venue",
    "space",
    "booking",
    "recovery_link",
    "outgoing_email",
    "device",
    "notification",
)
CURRENT_TABLES = (*CURRENT_TABLES_WITH_ID, "notification_booking")

CURRENT_REFERENCES = {
    ("venue", "created_by", "app_user"),
    ("venue", "updated_by", "app_user"),
    ("venue", "deactivated_by", "app_user"),
    ("space", "venue_id", "venue"),
    ("space", "created_by", "app_user"),
    ("space", "updated_by", "app_user"),
    ("space", "deactivated_by", "app_user"),
    ("booking", "user_id", "app_user"),
    ("booking", "space_id", "space"),
    ("booking", "canceled_by", "app_user"),
    ("recovery_link", "user_id", "app_user"),
    ("device", "user_id", "app_user"),
    ("notification", "user_id", "app_user"),
    ("notification", "booking_id", "booking"),
    ("notification", "replaced_by", "notification"),
    ("notification_booking", "notification_id", "notification"),
    ("notification_booking", "booking_id", "booking"),
}

CURRENT_KEYS = {
    "app_user": "id = :user",
    "venue": "id = :venue",
    "space": "id = :space",
    "booking": "id = :booking",
    "recovery_link": "id = :link",
    "outgoing_email": "id = :email",
    "device": "id = :device",
    "notification": "id = :notification",
    "notification_booking": "notification_id = :notification AND booking_id = :booking",
}


def inherited(old: int) -> uuid.UUID:
    """The version 7 UUID with a zero timestamp that the migration builds from the old id."""
    return uuid.UUID(int=(7 << 76) | (2 << 62) | old)


def _seed_0009(conn: Connection) -> dict[str, Any]:
    """One row in each of the 9 tables, with every reference used."""
    s = uuid.uuid4().hex[:8]
    user: Any = conn.execute(
        text(
            "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni, fecha_nacimiento)"
            " VALUES (:uid, :correo, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {
            "uid": f"uid-{s}",
            "correo": f"{s}@correo.com",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        },
    ).scalar_one()
    venue: Any = conn.execute(
        text(
            "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias, creado_por,"
            " modificado_por, dado_de_baja_por)"
            " VALUES (:n, 'Av. X', 1, '08:00', '23:00', '{1,2,3}', :u, :u, :u) RETURNING id"
        ),
        {"n": f"Sede {s}", "u": user},
    ).scalar_one()
    space: Any = conn.execute(
        text(
            "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada, iluminada,"
            " precio_por_hora, creado_por, modificado_por, dado_de_baja_por)"
            " VALUES (:sede, 'Tenis', 'Polvo', 1, :n, true, true, 1000, :u, :u, :u) RETURNING id"
        ),
        {"sede": venue, "n": f"Cancha {s}", "u": user},
    ).scalar_one()
    booking: Any = conn.execute(
        text(
            "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total,"
            " cancelada_por)"
            " VALUES (:u, :e, '2030-01-01 10:00-03', '2030-01-01 11:00-03', 1000, 1000, :u)"
            " RETURNING id"
        ),
        {"u": user, "e": space},
    ).scalar_one()
    link: Any = conn.execute(
        text(
            "INSERT INTO enlace_recuperacion (usuario_id, codigo_hash, vence_en)"
            " VALUES (:u, :h, now() + interval '1 hour') RETURNING id"
        ),
        {"u": user, "h": f"hash-{s}"},
    ).scalar_one()
    email: Any = conn.execute(
        text(
            "INSERT INTO correo_saliente (para, asunto, cuerpo)"
            " VALUES ('a@b.c', 'x', 'y') RETURNING id"
        )
    ).scalar_one()
    device: Any = conn.execute(
        text(
            "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
            " VALUES (:u, :t, 'android', true) RETURNING id"
        ),
        {"u": user, "t": f"token-{s}"},
    ).scalar_one()
    insert = (
        "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio{extra})"
        " VALUES (:u, 'cancelacion_forzosa', 't', 'c', 'pendiente'{value}) RETURNING id"
    )
    new: Any = conn.execute(text(insert.format(extra="", value="")), {"u": user}).scalar_one()
    notification: Any = conn.execute(
        text(insert.format(extra=", reserva_id, reemplazada_por", value=", :r, :n")),
        {"u": user, "r": booking, "n": new},
    ).scalar_one()
    conn.execute(
        text("INSERT INTO notificacion_reserva (notificacion_id, reserva_id) VALUES (:n, :r)"),
        {"n": notification, "r": booking},
    )
    return {
        "user": user,
        "venue": venue,
        "space": space,
        "booking": booking,
        "link": link,
        "email": email,
        "device": device,
        "notification": notification,
    }


def _seed(conn: Connection) -> dict[str, Any]:
    """One row in each of the 9 tables of the current database, with every reference used."""
    s = uuid.uuid4().hex[:8]
    user: Any = conn.execute(
        text(
            "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni, birth_date)"
            " VALUES (:uid, :email, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {
            "uid": f"uid-{s}",
            "email": f"{s}@correo.com",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        },
    ).scalar_one()
    venue: Any = conn.execute(
        text(
            "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days,"
            " created_by, updated_by, deactivated_by)"
            " VALUES (:n, 'Av. X', 1, '08:00', '23:00', '{1,2,3}', :u, :u, :u) RETURNING id"
        ),
        {"n": f"Sede {s}", "u": user},
    ).scalar_one()
    space: Any = conn.execute(
        text(
            "INSERT INTO space (venue_id, sport, kind, number, name, covered, lit,"
            " price_per_hour, created_by, updated_by, deactivated_by)"
            " VALUES (:venue, 'Tenis', 'Polvo', 1, :n, true, true, 1000, :u, :u, :u) RETURNING id"
        ),
        {"venue": venue, "n": f"Cancha {s}", "u": user},
    ).scalar_one()
    booking: Any = conn.execute(
        text(
            "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total,"
            " canceled_by)"
            " VALUES (:u, :e, '2030-01-01 10:00-03', '2030-01-01 11:00-03', 1000, 1000, :u)"
            " RETURNING id"
        ),
        {"u": user, "e": space},
    ).scalar_one()
    link: Any = conn.execute(
        text(
            "INSERT INTO recovery_link (user_id, code_hash, expires_at)"
            " VALUES (:u, :h, now() + interval '1 hour') RETURNING id"
        ),
        {"u": user, "h": f"hash-{s}"},
    ).scalar_one()
    email: Any = conn.execute(
        text(
            "INSERT INTO outgoing_email (recipient, subject, body)"
            " VALUES ('a@b.c', 'x', 'y') RETURNING id"
        )
    ).scalar_one()
    device: Any = conn.execute(
        text(
            "INSERT INTO device (user_id, token, platform, permission_granted)"
            " VALUES (:u, :t, 'android', true) RETURNING id"
        ),
        {"u": user, "t": f"token-{s}"},
    ).scalar_one()
    insert = (
        "INSERT INTO notification (user_id, kind, title, body, delivery{extra})"
        " VALUES (:u, 'forced_cancellation', 't', 'c', 'pending'{value}) RETURNING id"
    )
    new: Any = conn.execute(text(insert.format(extra="", value="")), {"u": user}).scalar_one()
    notification: Any = conn.execute(
        text(insert.format(extra=", booking_id, replaced_by", value=", :r, :n")),
        {"u": user, "r": booking, "n": new},
    ).scalar_one()
    conn.execute(
        text("INSERT INTO notification_booking (notification_id, booking_id) VALUES (:n, :r)"),
        {"n": notification, "r": booking},
    )
    return {
        "user": user,
        "venue": venue,
        "space": space,
        "booking": booking,
        "link": link,
        "email": email,
        "device": device,
        "notification": notification,
    }


def _snapshot(conn: Connection) -> dict[tuple[str, str], set[Any]]:
    """The ids and the 17 references as they are stored."""
    columns = [(t, "id") for t in TABLES_WITH_ID] + [(t, c) for t, c, _ in REFERENCES]
    return {
        (t, c): {row[0] for row in conn.execute(text(f"SELECT {c} FROM {t} WHERE {c} IS NOT NULL"))}
        for t, c in columns
    }


@pytest.fixture
def new_db() -> Iterator[tuple[AlembicConfig, str]]:
    """An empty database just for this test, to run the migration up and down."""
    name = f"club_dat01_{uuid.uuid4().hex[:10]}_test"
    url = make_url(os.environ["DATABASE_URL"])
    admin = create_engine(url.set(database="postgres"), isolation_level="AUTOCOMMIT")
    with admin.connect() as c:
        c.execute(text(f'CREATE DATABASE "{name}"'))
    target = url.set(database=name).render_as_string(hide_password=False)
    config = AlembicConfig(str(API_ROOT / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", target.replace("%", "%%"))
    try:
        yield config, target
    finally:
        with admin.connect() as c:
            c.execute(text(f'DROP DATABASE IF EXISTS "{name}" WITH (FORCE)'))
        admin.dispose()


def test_uuid_key_with_default_value(db: Connection) -> None:
    """after migration 0010 the key of app_user, venue, space, booking, recovery_link, outgoing_email, device and notification is uuid with default value uuid_v7() @DAT-01-S1 @assumption:DAT-01-ASM-01"""
    rows = db.execute(
        text(
            "SELECT table_name, data_type, column_default FROM information_schema.columns"
            " WHERE table_schema = 'public' AND column_name = 'id' AND table_name = ANY(:t)"
        ),
        {"t": list(CURRENT_TABLES_WITH_ID)},
    ).all()
    assert {f.table_name for f in rows} == set(CURRENT_TABLES_WITH_ID)
    for f in rows:
        assert f.data_type == "uuid", f.table_name
        assert f.column_default == "uuid_v7()", f.table_name


def test_the_17_references_are_uuid(db: Connection) -> None:
    """the 17 references between tables, including those of notification_booking, are uuid and point to the right table @DAT-01-S1 @assumption:DAT-01-ASM-04"""
    rows = db.execute(
        text(
            "SELECT c.conrelid::regclass::text AS table_name, a.attname AS column_name,"
            " c.confrelid::regclass::text AS target, format_type(a.atttypid, a.atttypmod) AS type_name"
            " FROM pg_constraint c JOIN pg_attribute a"
            " ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]"
            " WHERE c.contype = 'f' AND c.connamespace = 'public'::regnamespace"
        )
    ).all()
    assert {(f.table_name, f.column_name, f.target) for f in rows} == CURRENT_REFERENCES
    assert {f.type_name for f in rows} == {"uuid"}
    key: Any = db.execute(
        text(
            "SELECT a.attname FROM pg_index i JOIN pg_attribute a"
            " ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)"
            " WHERE i.indisprimary AND i.indrelid = 'notification_booking'::regclass"
        )
    ).scalars()
    assert set(key) == {"notification_id", "booking_id"}


def test_new_ids_are_version_7_and_ordered(db: Connection) -> None:
    """new ids are version 7 and come out in the order they are created @DAT-01-S1"""
    ids: list[uuid.UUID] = [
        db.execute(text("INSERT INTO outgoing_email (recipient, subject, body)"
                        " VALUES ('a@b.c', 'x', 'y') RETURNING id")).scalar_one()
        for _ in range(40)
    ]  # fmt: skip
    assert {i.version for i in ids} == {7}
    assert ids == sorted(ids)
    assert len(set(ids)) == 40


def test_migration_with_existing_rows(new_db: tuple[AlembicConfig, str]) -> None:
    """migration 0010 gives existing rows a version 7 UUID with their relations intact and rolls back if there are no new rows @assumption:DAT-01-ASM-02"""
    config, url = new_db
    engine = create_engine(url)
    command.upgrade(config, "0009")
    with engine.begin() as conn:
        _seed_0009(conn)
        before = _snapshot(conn)
    assert all(isinstance(v, int) for values in before.values() for v in values)

    command.upgrade(config, "0010")
    with engine.begin() as conn:
        after = _snapshot(conn)
        for key, values in before.items():
            assert after[key] == {inherited(v) for v in values}, key
        assert {u.version for u in after[("usuario", "id")]} == {7}
        view: Any = conn.execute(text("SELECT estado_actual FROM reserva_con_estado")).scalar_one()
        assert view == "activa"
        assert conn.execute(text("SELECT to_regproc('id_heredado')")).scalar_one() is None
        new: Any = conn.execute(
            text(
                "INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES ('a', 'b', 'c')"
                " RETURNING id"
            )
        ).scalar_one()
        assert new > max(after[("correo_saliente", "id")])
        conn.execute(text("DELETE FROM correo_saliente WHERE id = :i"), {"i": new})

    command.downgrade(config, "0009")
    with engine.begin() as conn:
        assert _snapshot(conn) == before
        following: Any = conn.execute(
            text(
                "INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES ('a', 'b', 'c')"
                " RETURNING id"
            )
        ).scalar_one()
        assert following > max(before[("correo_saliente", "id")])
        assert conn.execute(text("SELECT estado_actual FROM reserva_con_estado")).scalar_one()

    command.upgrade(config, "0010")
    with engine.begin() as conn:
        conn.execute(
            text("INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES ('a', 'b', 'c')")
        )
    with pytest.raises(Exception, match="hay filas creadas después de la migración 0010"):
        command.downgrade(config, "0009")
    with engine.begin() as conn:
        version = conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
    assert version == "0010"
    engine.dispose()


def test_audit_on_the_9_tables(db: Connection) -> None:
    """each of the 9 tables has created_at and updated_at and the database updates updated_at @DAT-01-S2 @assumption:DAT-01-ASM-03 @assumption:DAT-01-ASM-04"""
    columns = db.execute(
        text(
            "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns"
            " WHERE table_schema = 'public' AND column_name IN ('created_at', 'updated_at')"
            " AND table_name = ANY(:t)"
        ),
        {"t": list(CURRENT_TABLES)},
    ).all()
    assert {(c.table_name, c.column_name) for c in columns} == {
        (t, c) for t in CURRENT_TABLES for c in ("created_at", "updated_at")
    }
    assert {(c.data_type, c.is_nullable) for c in columns} == {("timestamp with time zone", "NO")}
    old = db.execute(
        text(
            "SELECT table_name, column_name FROM information_schema.columns"
            " WHERE table_schema = 'public' AND column_name IN"
            " ('creada_en', 'registrado_en', 'actualizado_en', 'emitido_en')"
        )
    ).all()
    assert old == []

    ids = _seed(db)
    for table in CURRENT_TABLES:
        where = CURRENT_KEYS[table]
        before = db.execute(
            text(f"SELECT created_at, updated_at FROM {table} WHERE {where}"), ids
        ).one()
        db.execute(text(f"UPDATE {table} SET created_at = created_at WHERE {where}"), ids)
        after = db.execute(
            text(f"SELECT created_at, updated_at FROM {table} WHERE {where}"), ids
        ).one()
        assert after.created_at == before.created_at, table
        assert after.updated_at > before.updated_at, table


def test_existing_rows_keep_their_date(new_db: tuple[AlembicConfig, str]) -> None:
    """existing rows keep their date in «creado_en» and «modificado_en» starts the same @assumption:DAT-01-ASM-07"""
    config, url = new_db
    engine = create_engine(url)
    command.upgrade(config, "0009")
    old = {
        "enlace_recuperacion": ("emitido_en", datetime(2020, 1, 1, tzinfo=UTC)),
        "correo_saliente": ("creado_en", datetime(2020, 2, 1, tzinfo=UTC)),
        "notificacion": ("creada_en", datetime(2020, 3, 1, tzinfo=UTC)),
        "dispositivo": ("registrado_en", datetime(2020, 4, 1, tzinfo=UTC)),
    }
    with engine.begin() as conn:
        _seed_0009(conn)
        for table, (column, date) in old.items():
            conn.execute(text(f"UPDATE {table} SET {column} = :f"), {"f": date})
        conn.execute(text("UPDATE dispositivo SET actualizado_en = registrado_en"))
        before: Any = conn.execute(text("SELECT now()")).scalar_one()

    command.upgrade(config, "0010")
    with engine.begin() as conn:
        after: Any = conn.execute(text("SELECT now()")).scalar_one()
        for table, (_, date) in old.items():
            rows = conn.execute(text(f"SELECT DISTINCT creado_en, modificado_en FROM {table}"))
            for created, modified in rows:
                assert created == date, table
                assert modified == date, table
        created, modified = conn.execute(
            text("SELECT creado_en, modificado_en FROM notificacion_reserva")
        ).one()
        assert before <= created <= after
        assert modified == created
    engine.dispose()
