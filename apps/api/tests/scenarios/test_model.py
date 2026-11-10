"""El modelo de datos que fija el enunciado, verificado contra la base real."""

import uuid
from datetime import date, datetime, time, timedelta, timezone

import pytest
from sqlalchemy import Connection, text
from sqlalchemy.exc import DBAPIError, IntegrityError

AR = timezone(timedelta(hours=-3))


def _unico() -> str:
    return uuid.uuid4().hex[:8]


def _usuario(db: Connection, sufijo: str) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni, birth_date)"
            " VALUES (:uid, :email, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {
            "uid": f"uid-{sufijo}",
            "email": f"ana.{sufijo}@correo.com",
            "dni": str(int(sufijo, 16) % 90_000_000 + 10_000_000),
        },
    ).scalar_one()


def _sede(db: Connection, sufijo: str) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
            " VALUES (:name, 'Av. Rivadavia', 19850, '08:00', '23:00', '{1,2,3,4,5,6,7}') RETURNING id"
        ),
        {"name": f"Sede Prueba {sufijo}"},
    ).scalar_one()


def _espacio(db: Connection, sede_id: uuid.UUID, sufijo: str, numero: int = 1) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO space (venue_id, sport, kind, number, name, covered, lit, price_per_hour)"
            " VALUES (:venue, 'Futbol', 'F5', :number, :name, false, true, 38000) RETURNING id"
        ),
        {
            "venue": sede_id,
            "number": numero,
            "name": f"Prueba{sufijo}_Rivadavia_19850_Futbol_F5_{numero}",
        },
    ).scalar_one()


def _reserva(
    db: Connection, usuario_id: uuid.UUID, espacio_id: uuid.UUID, inicio: datetime, horas: int = 1
) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
            " VALUES (:u, :e, :starts_at, :ends_at, 38000, :total) RETURNING id"
        ),
        {
            "u": usuario_id,
            "e": espacio_id,
            "starts_at": inicio,
            "ends_at": inicio + timedelta(hours=horas),
            "total": 38000 * horas,
        },
    ).scalar_one()


def test_el_usuario_se_guarda_con_sus_datos_y_el_correo_no_cambia(db: Connection) -> None:
    """el usuario se guarda con correo, nombre, apellido y fecha de nacimiento, y el correo no cambia @MOD-01-H01-01

    Verifica: los cuatro datos mínimos del perfil quedan guardados y la fecha de alta se estampa
    sola. Si falla, un perfil queda incompleto o un correo se reescribe y la cuenta cambia de dueño.
    """
    sufijo = _unico()
    uid = _usuario(db, sufijo)
    fila = db.execute(
        text(
            "SELECT email, first_name, last_name, birth_date, created_at FROM app_user WHERE id = :id"
        ),
        {"id": uid},
    ).one()
    assert fila.email == f"ana.{sufijo}@correo.com"
    assert (fila.first_name, fila.last_name, fila.birth_date) == (
        "Ana",
        "Pérez",
        date(2000, 3, 14),
    )
    assert fila.created_at is not None

    with pytest.raises(DBAPIError, match="email"):
        with db.begin_nested():
            db.execute(
                text("UPDATE app_user SET email = 'otro@correo.com' WHERE id = :id"), {"id": uid}
            )


def test_la_sede_se_guarda_con_nombre_direccion_y_horario(db: Connection) -> None:
    """una sede se guarda con nombre, dirección y horario de funcionamiento @MOD-01-H01-02

    Verifica: la sede guarda nombre, calle y altura, apertura, cierre y los días que abre. Si falla,
    las reservas no tienen contra qué horario validarse.
    """
    sufijo = _unico()
    sid = _sede(db, sufijo)
    fila = db.execute(
        text(
            "SELECT name, street, street_number, opens_at, closes_at, open_days, active FROM venue WHERE id = :id"
        ),
        {"id": sid},
    ).one()
    assert fila.name == f"Sede Prueba {sufijo}"
    assert (fila.street, fila.street_number) == ("Av. Rivadavia", 19850)
    assert (fila.opens_at, fila.closes_at) == (time(8), time(23))
    assert list(fila.open_days) == [1, 2, 3, 4, 5, 6, 7]
    assert fila.active is True


def test_el_espacio_pertenece_a_una_sede_y_tiene_nombre_compuesto(db: Connection) -> None:
    """un espacio se guarda asociado a una sede, con tipo y un nombre compuesto por sede, dirección, tipo y número @MOD-01-H01-03

    Verifica: el nombre sale de la sede, la calle sin su prefijo, la altura, el deporte, el tipo y el
    número, sin tildes ni espacios, como en el prototipo; y no hay dos espacios con el mismo número
    del mismo tipo en una sede. Si falla, dos canchas se confunden en una reserva.
    """
    from app.modules.spaces.rules import composite_name

    assert composite_name("Sede Morón", "Av. Rivadavia", 19850, "Fútbol", "F5", 1) == (
        "Moron_Rivadavia_19850_Futbol_F5_1"
    )
    assert composite_name("Sede Ramos Mejía", "Calle Belgrano", 1240, "Hockey", "H7", 1) == (
        "RamosMejia_Belgrano_1240_Hockey_H7_1"
    )
    assert composite_name("Sede San Justo", "Av. Casanova", 320, "Golf", "CORTO", 2) == (
        "SanJusto_Casanova_320_Golf_CORTO_2"
    )

    sufijo = _unico()
    sid = _sede(db, sufijo)
    eid = _espacio(db, sid, sufijo)
    fila = db.execute(
        text("SELECT venue_id, kind, name FROM space WHERE id = :id"), {"id": eid}
    ).one()
    assert (fila.venue_id, fila.kind) == (sid, "F5")
    assert fila.name == f"Prueba{sufijo}_Rivadavia_19850_Futbol_F5_1"

    with pytest.raises(IntegrityError):
        with db.begin_nested():
            _espacio(db, sid, sufijo)


def test_la_reserva_tiene_usuario_espacio_fecha_inicio_y_fin(db: Connection) -> None:
    """una reserva se guarda con usuario, espacio, fecha, hora de inicio y hora de fin @MOD-01-H01-04

    Verifica: la reserva guarda de quién es, qué espacio, cuándo empieza y termina, y el precio del
    momento. Si falla, no se puede listar ni cobrar lo que se reservó.
    """
    sufijo = _unico()
    uid = _usuario(db, sufijo)
    eid = _espacio(db, _sede(db, sufijo), sufijo)
    inicio = datetime(2030, 11, 14, 18, tzinfo=AR)
    rid = _reserva(db, uid, eid, inicio, horas=2)
    fila = db.execute(
        text(
            "SELECT user_id, space_id, starts_at, ends_at, price_per_hour, total, status, created_at FROM booking WHERE id = :id"
        ),
        {"id": rid},
    ).one()
    assert (fila.user_id, fila.space_id) == (uid, eid)
    assert fila.starts_at == inicio and fila.ends_at == inicio + timedelta(hours=2)
    assert (fila.price_per_hour, fila.total) == (38000, 76000)
    assert fila.status == "active"
    assert fila.created_at is not None


def test_la_base_rechaza_dos_reservas_superpuestas_del_mismo_espacio(db: Connection) -> None:
    """la base rechaza dos reservas superpuestas del mismo espacio en la misma fecha @MOD-01-H01-05

    Verifica: una reserva que se pisa en parte con otra activa del mismo espacio no entra, una
    pegada a continuación sí, y una cancelada libera el horario. Si falla, dos personas llegan a la
    misma cancha a la misma hora.
    """
    sufijo = _unico()
    uid = _usuario(db, sufijo)
    eid = _espacio(db, _sede(db, sufijo), sufijo)
    inicio = datetime(2030, 11, 14, 18, tzinfo=AR)
    primera = _reserva(db, uid, eid, inicio, horas=2)

    with pytest.raises(IntegrityError):
        with db.begin_nested():
            _reserva(db, uid, eid, inicio + timedelta(hours=1))

    _reserva(db, uid, eid, inicio + timedelta(hours=2))

    db.execute(text("UPDATE booking SET status = 'canceled' WHERE id = :id"), {"id": primera})
    _reserva(db, uid, eid, inicio + timedelta(hours=1))


def test_la_reserva_finalizada_sigue_existiendo(db: Connection) -> None:
    """una reserva finalizada sigue existiendo y aparece en el historial @MOD-01-H01-06

    Verifica: una reserva cuyo horario ya pasó se conserva y figura entre las del usuario, con el
    estado completada. Si falla, el historial pierde lo que ya se jugó.
    """
    sufijo = _unico()
    uid = _usuario(db, sufijo)
    eid = _espacio(db, _sede(db, sufijo), sufijo)
    inicio = datetime.now(AR).replace(minute=0, second=0, microsecond=0) - timedelta(days=3)
    rid = _reserva(db, uid, eid, inicio)
    filas = db.execute(
        text("SELECT id, current_status FROM booking_with_status WHERE user_id = :u"), {"u": uid}
    ).all()
    assert [(f.id, f.current_status) for f in filas] == [(rid, "completed")]
