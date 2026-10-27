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
    "usuario",
    "sede",
    "espacio",
    "reserva",
    "enlace_recuperacion",
    "correo_saliente",
    "dispositivo",
    "notificacion",
)
TABLAS = (*TABLAS_CON_ID, "notificacion_reserva")

REFERENCIAS = {
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

CLAVES = {
    "usuario": "id = :usuario",
    "sede": "id = :sede",
    "espacio": "id = :espacio",
    "reserva": "id = :reserva",
    "enlace_recuperacion": "id = :enlace",
    "correo_saliente": "id = :correo",
    "dispositivo": "id = :dispositivo",
    "notificacion": "id = :notificacion",
    "notificacion_reserva": "notificacion_id = :notificacion AND reserva_id = :reserva",
}


def heredado(viejo: int) -> uuid.UUID:
    """El UUID versión 7 con marca de tiempo cero que la migración arma con el id viejo."""
    return uuid.UUID(int=(7 << 76) | (2 << 62) | viejo)


def _sembrar(conn: Connection) -> dict[str, Any]:
    """Una fila en cada una de las 9 tablas, con todas las referencias usadas."""
    s = uuid.uuid4().hex[:8]
    usuario: Any = conn.execute(
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
        {"sede": sede, "n": f"Cancha {s}", "u": usuario},
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
        "usuario": usuario,
        "sede": sede,
        "espacio": espacio,
        "reserva": reserva,
        "enlace": enlace,
        "correo": correo,
        "dispositivo": dispositivo,
        "notificacion": notificacion,
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
        {"t": list(TABLAS_CON_ID)},
    ).all()
    assert {f.table_name for f in filas} == set(TABLAS_CON_ID)
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
    assert {(f.tabla, f.columna, f.destino) for f in filas} == REFERENCIAS
    assert {f.tipo for f in filas} == {"uuid"}
    clave: Any = db.execute(
        text(
            "SELECT a.attname FROM pg_index i JOIN pg_attribute a"
            " ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)"
            " WHERE i.indisprimary AND i.indrelid = 'notificacion_reserva'::regclass"
        )
    ).scalars()
    assert set(clave) == {"notificacion_id", "reserva_id"}


def test_ids_nuevos_version_7_y_en_orden(db: Connection) -> None:
    """los ids nuevos son versión 7 y salen en el orden en que se crean @DAT-01-S1"""
    ids: list[uuid.UUID] = [
        db.execute(text("INSERT INTO correo_saliente (para, asunto, cuerpo)"
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
        _sembrar(conn)
        antes = _foto(conn)
    assert all(isinstance(v, int) for valores in antes.values() for v in valores)

    command.upgrade(config, "0010")
    with motor.begin() as conn:
        despues = _foto(conn)
        for clave, valores in antes.items():
            assert despues[clave] == {heredado(v) for v in valores}, clave
        assert {u.version for u in despues[("usuario", "id")]} == {7}
        vista: Any = conn.execute(text("SELECT estado_actual FROM reserva_con_estado")).scalar_one()
        assert vista == "activa"
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
            " WHERE table_schema = 'public' AND column_name IN ('creado_en', 'modificado_en')"
            " AND table_name = ANY(:t)"
        ),
        {"t": list(TABLAS)},
    ).all()
    assert {(c.table_name, c.column_name) for c in columnas} == {
        (t, c) for t in TABLAS for c in ("creado_en", "modificado_en")
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
    for tabla in TABLAS:
        donde = CLAVES[tabla]
        antes = db.execute(
            text(f"SELECT creado_en, modificado_en FROM {tabla} WHERE {donde}"), ids
        ).one()
        db.execute(text(f"UPDATE {tabla} SET creado_en = creado_en WHERE {donde}"), ids)
        despues = db.execute(
            text(f"SELECT creado_en, modificado_en FROM {tabla} WHERE {donde}"), ids
        ).one()
        assert despues.creado_en == antes.creado_en, tabla
        assert despues.modificado_en > antes.modificado_en, tabla


def test_filas_existentes_conservan_su_fecha(base_nueva: tuple[AlembicConfig, str]) -> None:
    """las filas existentes conservan su fecha en creado_en y modificado_en arranca igual @assumption:DAT-01-ASM-07"""
    config, url = base_nueva
    motor = create_engine(url)
    command.upgrade(config, "0009")
    viejas = {
        "enlace_recuperacion": ("emitido_en", datetime(2020, 1, 1, tzinfo=UTC)),
        "correo_saliente": ("creado_en", datetime(2020, 2, 1, tzinfo=UTC)),
        "notificacion": ("creada_en", datetime(2020, 3, 1, tzinfo=UTC)),
        "dispositivo": ("registrado_en", datetime(2020, 4, 1, tzinfo=UTC)),
    }
    with motor.begin() as conn:
        _sembrar(conn)
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
