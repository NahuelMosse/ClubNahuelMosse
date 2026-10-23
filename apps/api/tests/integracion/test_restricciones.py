"""Restricciones del esquema que no cubre ningún escenario de la card."""

import uuid
from collections.abc import Callable
from datetime import datetime, timedelta, timezone
from typing import Any

import pytest
from sqlalchemy import Connection, text
from sqlalchemy.exc import DBAPIError

AR = timezone(timedelta(hours=-3))


def _usuario(db: Connection, correo: str | None = None, dni: str | None = None) -> int:
    s = uuid.uuid4().hex[:8]
    return db.execute(
        text(
            "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni, fecha_nacimiento)"
            " VALUES (:uid, :correo, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {
            "uid": f"uid-{s}",
            "correo": correo or f"{s}@correo.com",
            "dni": dni or str(int(s, 16) % 90_000_000 + 10_000_000),
        },
    ).scalar_one()


def _sede(
    db: Connection, apertura: str = "08:00", cierre: str = "23:00", dias: str = "{1,2,3}"
) -> int:
    return db.execute(
        text(
            "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
            " VALUES ('Sede X', 'Av. X', 1, :a, :c, CAST(:d AS smallint[])) RETURNING id"
        ),
        {"a": apertura, "c": cierre, "d": dias},
    ).scalar_one()


def _espacio(db: Connection) -> int:
    return db.execute(
        text(
            "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada, iluminada,"
            " precio_por_hora) VALUES (:s, 'Futbol', 'F5', 1, :n, false, true, 38000) RETURNING id"
        ),
        {"s": _sede(db), "n": f"X_{uuid.uuid4().hex[:8]}"},
    ).scalar_one()


def _falla(db: Connection, sql: str, params: dict[str, object] | None = None) -> None:
    with pytest.raises(DBAPIError), db.begin_nested():
        db.execute(text(sql), params or {})


def test_la_hora_completa_no_depende_de_la_zona_de_la_sesion(db: Connection) -> None:
    uid, eid = _usuario(db), _espacio(db)
    db.execute(text("SET LOCAL TimeZone = 'Asia/Kolkata'"))
    inicio = datetime(2030, 11, 14, 18, 30, tzinfo=AR)
    _falla(
        db,
        "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
        " VALUES (:u, :e, :i, :f, 38000, 38000)",
        {"u": uid, "e": eid, "i": inicio, "f": inicio + timedelta(hours=1)},
    )


def test_el_total_es_el_precio_por_las_horas(db: Connection) -> None:
    uid, eid = _usuario(db), _espacio(db)
    inicio = datetime(2030, 11, 14, 18, tzinfo=AR)
    _falla(
        db,
        "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
        " VALUES (:u, :e, :i, :f, 38000, 38000)",
        {"u": uid, "e": eid, "i": inicio, "f": inicio + timedelta(hours=2)},
    )


def test_la_anulacion_exige_motivo(db: Connection) -> None:
    uid, eid = _usuario(db), _espacio(db)
    inicio = datetime(2030, 11, 14, 18, tzinfo=AR)
    rid: Any = db.execute(
        text(
            "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
            " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
        ),
        {"u": uid, "e": eid, "i": inicio, "f": inicio + timedelta(hours=1)},
    ).scalar_one()
    _falla(db, "UPDATE reserva SET estado = 'anulada' WHERE id = :id", {"id": rid})


def test_una_sede_puede_cerrar_a_medianoche(db: Connection) -> None:
    _sede(db, "18:00", "00:00")
    _falla(
        db,
        "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
        " VALUES ('S', 'C', 1, '22:00', '08:00', '{1}')",
    )


@pytest.mark.parametrize("dias", ["{{1,2},{3,4}}", "{}", "{0}", "{8}"])
def test_los_dias_son_una_lista_de_uno_a_siete(db: Connection, dias: str) -> None:
    _falla(
        db,
        "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
        " VALUES ('S', 'C', 1, '08:00', '23:00', CAST(:d AS smallint[]))",
        {"d": dias},
    )


@pytest.mark.parametrize("tabla", ["usuario", "sede", "espacio"])
def test_nada_se_borra(db: Connection, tabla: str) -> None:
    ids: dict[str, Callable[[Connection], int]] = {
        "usuario": _usuario,
        "sede": _sede,
        "espacio": _espacio,
    }
    fila = ids[tabla](db)
    _falla(db, f"DELETE FROM {tabla} WHERE id = :id", {"id": fila})


def test_el_nombre_del_espacio_no_cambia(db: Connection) -> None:
    eid = _espacio(db)
    _falla(db, "UPDATE espacio SET nombre = 'Otro' WHERE id = :id", {"id": eid})
    _falla(db, "UPDATE espacio SET numero = 9 WHERE id = :id", {"id": eid})
    db.execute(text("UPDATE espacio SET precio_por_hora = 40000 WHERE id = :id"), {"id": eid})


def test_creado_en_no_cambia_y_modificado_en_se_actualiza(db: Connection) -> None:
    uid = _usuario(db)
    antes = db.execute(
        text("SELECT creado_en, modificado_en FROM usuario WHERE id = :id"), {"id": uid}
    ).one()
    db.execute(text("SELECT pg_sleep(0.01)"))
    db.execute(
        text("UPDATE usuario SET nombre = 'Eva', creado_en = '2001-01-01' WHERE id = :id"),
        {"id": uid},
    )
    despues = db.execute(
        text("SELECT creado_en, modificado_en FROM usuario WHERE id = :id"), {"id": uid}
    ).one()
    assert despues.creado_en == antes.creado_en
    assert despues.modificado_en > antes.modificado_en


def test_activo_y_fecha_de_baja_van_juntos(db: Connection) -> None:
    uid = _usuario(db)
    _falla(db, "UPDATE usuario SET activo = false WHERE id = :id", {"id": uid})
