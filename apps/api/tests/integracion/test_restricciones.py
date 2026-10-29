"""Restricciones del esquema que no cubre ningún escenario de la card."""

import uuid
from collections.abc import Callable
from datetime import datetime, timedelta, timezone
from typing import Any

import pytest
from sqlalchemy import Connection, text
from sqlalchemy.exc import DBAPIError

AR = timezone(timedelta(hours=-3))


def _usuario(db: Connection, correo: str | None = None, dni: str | None = None) -> uuid.UUID:
    s = uuid.uuid4().hex[:8]
    return db.execute(
        text(
            "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni, birth_date)"
            " VALUES (:uid, :email, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {
            "uid": f"uid-{s}",
            "email": correo or f"{s}@correo.com",
            "dni": dni or str(int(s, 16) % 90_000_000 + 10_000_000),
        },
    ).scalar_one()


def _sede(
    db: Connection, apertura: str = "08:00", cierre: str = "23:00", dias: str = "{1,2,3}"
) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
            " VALUES ('Sede X', 'Av. X', 1, :a, :c, CAST(:d AS smallint[])) RETURNING id"
        ),
        {"a": apertura, "c": cierre, "d": dias},
    ).scalar_one()


def _espacio(db: Connection) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO space (venue_id, sport, kind, number, name, covered, lit,"
            " price_per_hour) VALUES (:s, 'Futbol', 'F5', 1, :n, false, true, 38000) RETURNING id"
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
        "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
        " VALUES (:u, :e, :i, :f, 38000, 38000)",
        {"u": uid, "e": eid, "i": inicio, "f": inicio + timedelta(hours=1)},
    )


def test_el_total_es_el_precio_por_las_horas(db: Connection) -> None:
    uid, eid = _usuario(db), _espacio(db)
    inicio = datetime(2030, 11, 14, 18, tzinfo=AR)
    _falla(
        db,
        "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
        " VALUES (:u, :e, :i, :f, 38000, 38000)",
        {"u": uid, "e": eid, "i": inicio, "f": inicio + timedelta(hours=2)},
    )


def test_la_anulacion_exige_motivo(db: Connection) -> None:
    uid, eid = _usuario(db), _espacio(db)
    inicio = datetime(2030, 11, 14, 18, tzinfo=AR)
    rid: Any = db.execute(
        text(
            "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
            " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
        ),
        {"u": uid, "e": eid, "i": inicio, "f": inicio + timedelta(hours=1)},
    ).scalar_one()
    _falla(db, "UPDATE booking SET status = 'voided' WHERE id = :id", {"id": rid})


def test_una_sede_puede_cerrar_a_medianoche(db: Connection) -> None:
    _sede(db, "18:00", "00:00")
    _falla(
        db,
        "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
        " VALUES ('S', 'C', 1, '22:00', '08:00', '{1}')",
    )


@pytest.mark.parametrize("dias", ["{{1,2},{3,4}}", "{}", "{0}", "{8}"])
def test_los_dias_son_una_lista_de_uno_a_siete(db: Connection, dias: str) -> None:
    _falla(
        db,
        "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
        " VALUES ('S', 'C', 1, '08:00', '23:00', CAST(:d AS smallint[]))",
        {"d": dias},
    )


@pytest.mark.parametrize("tabla", ["app_user", "venue", "space"])
def test_nada_se_borra(db: Connection, tabla: str) -> None:
    ids: dict[str, Callable[[Connection], uuid.UUID]] = {
        "app_user": _usuario,
        "venue": _sede,
        "space": _espacio,
    }
    fila = ids[tabla](db)
    _falla(db, f"DELETE FROM {tabla} WHERE id = :id", {"id": fila})


def test_el_nombre_del_espacio_no_cambia(db: Connection) -> None:
    eid = _espacio(db)
    _falla(db, "UPDATE space SET name = 'Otro' WHERE id = :id", {"id": eid})
    _falla(db, "UPDATE space SET number = 9 WHERE id = :id", {"id": eid})
    db.execute(text("UPDATE space SET price_per_hour = 40000 WHERE id = :id"), {"id": eid})


def test_creado_en_no_cambia_y_modificado_en_se_actualiza(db: Connection) -> None:
    uid = _usuario(db)
    antes = db.execute(
        text("SELECT created_at, updated_at FROM app_user WHERE id = :id"), {"id": uid}
    ).one()
    db.execute(text("SELECT pg_sleep(0.01)"))
    db.execute(
        text("UPDATE app_user SET first_name = 'Eva', created_at = '2001-01-01' WHERE id = :id"),
        {"id": uid},
    )
    despues = db.execute(
        text("SELECT created_at, updated_at FROM app_user WHERE id = :id"), {"id": uid}
    ).one()
    assert despues.created_at == antes.created_at
    assert despues.updated_at > antes.updated_at


def test_activo_y_fecha_de_baja_van_juntos(db: Connection) -> None:
    uid = _usuario(db)
    _falla(db, "UPDATE app_user SET active = false WHERE id = :id", {"id": uid})
