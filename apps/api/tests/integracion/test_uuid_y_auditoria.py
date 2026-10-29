"""DAT-01: claves UUIDv7 y columnas de auditoría en las 9 tablas (la migración 0010)."""

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

RAIZ_API = Path(__file__).resolve().parents[2]

TABLAS_CON_ID = (
    "user",
    "venue",
    "space",
    "booking",
    "enlace_recuperacion",
    "correo_saliente",
    "dispositivo",
    "notificacion",
)

REFERENCIAS = {
    ("venue", "creado_por", "user"),
    ("venue", "modificado_por", "user"),
    ("venue", "dado_de_baja_por", "user"),
    ("space", "venue_id", "venue"),
    ("space", "creado_por", "user"),
    ("space", "modificado_por", "user"),
    ("space", "dado_de_baja_por", "user"),
    ("booking", "user_id", "user"),
    ("booking", "space_id", "space"),
    ("booking", "cancelada_por", "user"),
    ("enlace_recuperacion", "user_id", "user"),
    ("dispositivo", "user_id", "user"),
    ("notificacion", "user_id", "user"),
    ("notificacion", "booking_id", "booking"),
    ("notificacion", "reemplazada_por", "notificacion"),
    ("notificacion_reserva", "notificacion_id", "notificacion"),
    ("notificacion_reserva", "booking_id", "booking"),
}

TABLAS_CON_ID_ACTUAL = (
    "app_user",
    "venue",
    "space",
    "booking",
    "recovery_link",
    "outgoing_email",
    "device",
    "notification",
)
TABLAS_ACTUAL = (*TABLAS_CON_ID_ACTUAL, "notification_booking")

REFERENCIAS_ACTUAL = {
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

CLAVES_ACTUAL = {
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


def heredado(viejo: int) -> uuid.UUID:
    """El UUID versión 7 con marca de tiempo cero que la migración arma con el id viejo."""
    return uuid.UUID(int=(7 << 76) | (2 << 62) | viejo)


def _sembrar_0009(conn: Connection) -> dict[str, Any]:
    """Una fila en cada una de las 9 tablas, con todas las referencias usadas."""
    s = uuid.uuid4().hex[:8]
    usuario: Any = conn.execute(
        text(
            "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni, fecha_nacimiento)"
            " VALUES (:uid, :correo, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {
            "uid": f"uid-{s}",
            "email": f"{s}@correo.com",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        },
    ).scalar_one()
    sede: Any = conn.execute(
        text(
            "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias, creado_por,"
            " modificado_por, dado_de_baja_por)"
            " VALUES (:n, 'Av. X', 1, '08:00', '23:00', '{1,2,3}', :u, :u, :u) RETURNING id"
        ),
        {"n": f"Sede {s}", "u": usuario},
    ).scalar_one()
    espacio: Any = conn.execute(
        text(
            "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada, iluminada,"
            " precio_por_hora, creado_por, modificado_por, dado_de_baja_por)"
            " VALUES (:sede, 'Tenis', 'Polvo', 1, :n, true, true, 1000, :u, :u, :u) RETURNING id"
        ),
        {"venue": sede, "n": f"Cancha {s}", "u": usuario},
    ).scalar_one()
    reserva: Any = conn.execute(
        text(
            "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total,"
            " cancelada_por)"
            " VALUES (:u, :e, '2030-01-01 10:00-03', '2030-01-01 11:00-03', 1000, 1000, :u)"
            " RETURNING id"
        ),
        {"u": usuario, "e": espacio},
    ).scalar_one()
    enlace: Any = conn.execute(
        text(
            "INSERT INTO enlace_recuperacion (usuario_id, codigo_hash, vence_en)"
            " VALUES (:u, :h, now() + interval '1 hour') RETURNING id"
        ),
        {"u": usuario, "h": f"hash-{s}"},
    ).scalar_one()
    correo: Any = conn.execute(
        text(
            "INSERT INTO correo_saliente (para, asunto, cuerpo)"
            " VALUES ('a@b.c', 'x', 'y') RETURNING id"
        )
    ).scalar_one()
    dispositivo: Any = conn.execute(
        text(
            "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
            " VALUES (:u, :t, 'android', true) RETURNING id"
        ),
        {"u": usuario, "t": f"token-{s}"},
    ).scalar_one()
    insertar = (
        "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio{extra})"
        " VALUES (:u, 'cancelacion_forzosa', 't', 'c', 'pendiente'{valor}) RETURNING id"
    )
    nuevo: Any = conn.execute(
        text(insertar.format(extra="", valor="")), {"u": usuario}
    ).scalar_one()
    notificacion: Any = conn.execute(
        text(insertar.format(extra=", reserva_id, reemplazada_por", valor=", :r, :n")),
        {"u": usuario, "r": reserva, "n": nuevo},
    ).scalar_one()
    conn.execute(
        text("INSERT INTO notificacion_reserva (notificacion_id, reserva_id) VALUES (:n, :r)"),
        {"n": notificacion, "r": reserva},
    )
    return {
        "user": usuario,
        "venue": sede,
        "space": espacio,
        "booking": reserva,
        "enlace": enlace,
        "email": correo,
        "dispositivo": dispositivo,
        "notificacion": notificacion,
    }


def _sembrar(conn: Connection) -> dict[str, Any]:
    """Una fila en cada una de las 9 tablas de la base actual, con todas las referencias usadas."""
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
    insertar = (
        "INSERT INTO notification (user_id, kind, title, body, delivery{extra})"
        " VALUES (:u, 'forced_cancellation', 't', 'c', 'pending'{valor}) RETURNING id"
    )
    nuevo: Any = conn.execute(
        text(insertar.format(extra="", valor="")), {"u": user}
    ).scalar_one()
    notification: Any = conn.execute(
        text(insertar.format(extra=", booking_id, replaced_by", valor=", :r, :n")),
        {"u": user, "r": booking, "n": nuevo},
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


def _foto(conn: Connection) -> dict[tuple[str, str], set[Any]]:
    """Los ids y las 17 referencias tal como están guardados."""
    columnas = [(t, "id") for t in TABLAS_CON_ID] + [(t, c) for t, c, _ in REFERENCIAS]
    return {
        (t, c): {
            fila[0] for fila in conn.execute(text(f"SELECT {c} FROM {t} WHERE {c} IS NOT NULL"))
        }
        for t, c in columnas
    }


@pytest.fixture
def base_nueva() -> Iterator[tuple[AlembicConfig, str]]:
    """Una base vacía sólo para este test, para correr la migración hacia arriba y hacia abajo."""
    nombre = f"club_dat01_{uuid.uuid4().hex[:10]}_test"
    url = make_url(os.environ["DATABASE_URL"])
    admin = create_engine(url.set(database="postgres"), isolation_level="AUTOCOMMIT")
    with admin.connect() as c:
        c.execute(text(f'CREATE DATABASE "{nombre}"'))
    destino = url.set(database=nombre).render_as_string(hide_password=False)
    config = AlembicConfig(str(RAIZ_API / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", destino.replace("%", "%%"))
    try:
        yield config, destino
    finally:
        with admin.connect() as c:
            c.execute(text(f'DROP DATABASE IF EXISTS "{nombre}" WITH (FORCE)'))
        admin.dispose()


def test_clave_uuid_con_valor_por_defecto(db: Connection) -> None:
    """después de la migración 0010 la clave de usuario, sede, espacio, reserva, enlace_recuperacion, correo_saliente, dispositivo y notificacion es uuid con valor por defecto uuid_v7() @DAT-01-S1 @assumption:DAT-01-ASM-01"""
    filas = db.execute(
        text(
            "SELECT table_name, data_type, column_default FROM information_schema.columns"
            " WHERE table_schema = 'public' AND column_name = 'id' AND table_name = ANY(:t)"
        ),
        {"t": list(TABLAS_CON_ID_ACTUAL)},
    ).all()
    assert {f.table_name for f in filas} == set(TABLAS_CON_ID_ACTUAL)
    for f in filas:
        assert f.data_type == "uuid", f.table_name
        assert f.column_default == "uuid_v7()", f.table_name


def test_las_17_referencias_son_uuid(db: Connection) -> None:
    """las 17 referencias entre tablas, también las de notificacion_reserva, son uuid y apuntan a la tabla correcta @DAT-01-S1 @assumption:DAT-01-ASM-04"""
    filas = db.execute(
        text(
            "SELECT c.conrelid::regclass::text AS tabla, a.attname AS columna,"
            " c.confrelid::regclass::text AS destino, format_type(a.atttypid, a.atttypmod) AS tipo"
            " FROM pg_constraint c JOIN pg_attribute a"
            " ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]"
            " WHERE c.contype = 'f' AND c.connamespace = 'public'::regnamespace"
        )
    ).all()
    assert {(f.tabla, f.columna, f.destino) for f in filas} == REFERENCIAS_ACTUAL
    assert {f.tipo for f in filas} == {"uuid"}
    clave: Any = db.execute(
        text(
            "SELECT a.attname FROM pg_index i JOIN pg_attribute a"
            " ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)"
            " WHERE i.indisprimary AND i.indrelid = 'notification_booking'::regclass"
        )
    ).scalars()
    assert set(clave) == {"notification_id", "booking_id"}


def test_ids_nuevos_version_7_y_en_orden(db: Connection) -> None:
    """los ids nuevos son versión 7 y salen en el orden en que se crean @DAT-01-S1"""
    ids: list[uuid.UUID] = [
        db.execute(text("INSERT INTO outgoing_email (recipient, subject, body)"
                        " VALUES ('a@b.c', 'x', 'y') RETURNING id")).scalar_one()
        for _ in range(40)
    ]  # fmt: skip
    assert {i.version for i in ids} == {7}
    assert ids == sorted(ids)
    assert len(set(ids)) == 40


def test_migracion_con_filas_existentes(base_nueva: tuple[AlembicConfig, str]) -> None:
    """la migración 0010 da a las filas existentes un UUID versión 7 con sus relaciones intactas y vuelve atrás si no hay filas nuevas @assumption:DAT-01-ASM-02"""
    config, url = base_nueva
    motor = create_engine(url)
    command.upgrade(config, "0009")
    with motor.begin() as conn:
        _sembrar_0009(conn)
        antes = _foto(conn)
    assert all(isinstance(v, int) for valores in antes.values() for v in valores)

    command.upgrade(config, "0010")
    with motor.begin() as conn:
        despues = _foto(conn)
        for clave, valores in antes.items():
            assert despues[clave] == {heredado(v) for v in valores}, clave
        assert {u.version for u in despues[("user", "id")]} == {7}
        vista: Any = conn.execute(text("SELECT estado_actual FROM reserva_con_estado")).scalar_one()
        assert vista == "active"
        assert conn.execute(text("SELECT to_regproc('id_heredado')")).scalar_one() is None
        nuevo: Any = conn.execute(
            text(
                "INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES ('a', 'b', 'c')"
                " RETURNING id"
            )
        ).scalar_one()
        assert nuevo > max(despues[("correo_saliente", "id")])
        conn.execute(text("DELETE FROM correo_saliente WHERE id = :i"), {"i": nuevo})

    command.downgrade(config, "0009")
    with motor.begin() as conn:
        assert _foto(conn) == antes
        siguiente: Any = conn.execute(
            text(
                "INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES ('a', 'b', 'c')"
                " RETURNING id"
            )
        ).scalar_one()
        assert siguiente > max(antes[("correo_saliente", "id")])
        assert conn.execute(text("SELECT estado_actual FROM reserva_con_estado")).scalar_one()

    command.upgrade(config, "0010")
    with motor.begin() as conn:
        conn.execute(
            text("INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES ('a', 'b', 'c')")
        )
    with pytest.raises(Exception, match="hay filas creadas después de la migración 0010"):
        command.downgrade(config, "0009")
    with motor.begin() as conn:
        version = conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
    assert version == "0010"
    motor.dispose()


def test_auditoria_en_las_9_tablas(db: Connection) -> None:
    """cada una de las 9 tablas tiene creado_en y modificado_en y la base actualiza modificado_en @DAT-01-S2 @assumption:DAT-01-ASM-03 @assumption:DAT-01-ASM-04"""
    columnas = db.execute(
        text(
            "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns"
            " WHERE table_schema = 'public' AND column_name IN ('created_at', 'updated_at')"
            " AND table_name = ANY(:t)"
        ),
        {"t": list(TABLAS_ACTUAL)},
    ).all()
    assert {(c.table_name, c.column_name) for c in columnas} == {
        (t, c) for t in TABLAS_ACTUAL for c in ("created_at", "updated_at")
    }
    assert {(c.data_type, c.is_nullable) for c in columnas} == {("timestamp with time zone", "NO")}
    viejas = db.execute(
        text(
            "SELECT table_name, column_name FROM information_schema.columns"
            " WHERE table_schema = 'public' AND column_name IN"
            " ('creada_en', 'registrado_en', 'actualizado_en', 'emitido_en')"
        )
    ).all()
    assert viejas == []

    ids = _sembrar(db)
    for tabla in TABLAS_ACTUAL:
        donde = CLAVES_ACTUAL[tabla]
        antes = db.execute(
            text(f"SELECT created_at, updated_at FROM {tabla} WHERE {donde}"), ids
        ).one()
        db.execute(text(f"UPDATE {tabla} SET created_at = created_at WHERE {donde}"), ids)
        despues = db.execute(
            text(f"SELECT created_at, updated_at FROM {tabla} WHERE {donde}"), ids
        ).one()
        assert despues.created_at == antes.created_at, tabla
        assert despues.updated_at > antes.updated_at, tabla


def test_filas_existentes_conservan_su_fecha(base_nueva: tuple[AlembicConfig, str]) -> None:
    """las filas existentes conservan su fecha en creado_en y modificado_en arranca igual @assumption:DAT-01-ASM-07"""
    config, url = base_nueva
    motor = create_engine(url)
    command.upgrade(config, "0009")
    viejas = {
        "enlace_recuperacion": ("emitido_en", datetime(2020, 1, 1, tzinfo=UTC)),
        "correo_saliente": ("created_at", datetime(2020, 2, 1, tzinfo=UTC)),
        "notificacion": ("created_at", datetime(2020, 3, 1, tzinfo=UTC)),
        "dispositivo": ("registrado_en", datetime(2020, 4, 1, tzinfo=UTC)),
    }
    with motor.begin() as conn:
        _sembrar_0009(conn)
        for tabla, (columna, fecha) in viejas.items():
            conn.execute(text(f"UPDATE {tabla} SET {columna} = :f"), {"f": fecha})
        conn.execute(text("UPDATE dispositivo SET actualizado_en = registrado_en"))
        antes: Any = conn.execute(text("SELECT now()")).scalar_one()

    command.upgrade(config, "0010")
    with motor.begin() as conn:
        despues: Any = conn.execute(text("SELECT now()")).scalar_one()
        for tabla, (_, fecha) in viejas.items():
            fila = conn.execute(text(f"SELECT DISTINCT creado_en, modificado_en FROM {tabla}"))
            for creado, modificado in fila:
                assert creado == fecha, tabla
                assert modificado == fecha, tabla
        creado, modificado = conn.execute(
            text("SELECT creado_en, modificado_en FROM notificacion_reserva")
        ).one()
        assert antes <= creado <= despues
        assert modificado == creado
    motor.dispose()
