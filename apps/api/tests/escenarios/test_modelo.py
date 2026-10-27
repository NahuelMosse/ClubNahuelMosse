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
            "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni, fecha_nacimiento)"
            " VALUES (:uid, :correo, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {"uid": f"uid-{sufijo}", "correo": f"ana.{sufijo}@correo.com", "dni": str(int(sufijo, 16) % 90_000_000 + 10_000_000)},
    ).scalar_one()


def _sede(db: Connection, sufijo: str) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
            " VALUES (:nombre, 'Av. Rivadavia', 19850, '08:00', '23:00', '{1,2,3,4,5,6,7}') RETURNING id"
        ),
        {"nombre": f"Sede Prueba {sufijo}"},
    ).scalar_one()


def _espacio(db: Connection, sede_id: uuid.UUID, sufijo: str, numero: int = 1) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada, iluminada, precio_por_hora)"
            " VALUES (:sede, 'Futbol', 'F5', :numero, :nombre, false, true, 38000) RETURNING id"
        ),
        {"sede": sede_id, "numero": numero, "nombre": f"Prueba{sufijo}_Rivadavia_19850_Futbol_F5_{numero}"},
    ).scalar_one()


def _reserva(db: Connection, usuario_id: uuid.UUID, espacio_id: uuid.UUID, inicio: datetime, horas: int = 1) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
            " VALUES (:u, :e, :inicio, :fin, 38000, :total) RETURNING id"
        ),
        {"u": usuario_id, "e": espacio_id, "inicio": inicio, "fin": inicio + timedelta(hours=horas), "total": 38000 * horas},
    ).scalar_one()


def test_el_usuario_se_guarda_con_sus_datos_y_el_correo_no_cambia(db: Connection) -> None:
    """el usuario se guarda con correo, nombre, apellido y fecha de nacimiento, y el correo no cambia @MOD-01-H01-01

    Verifica: los cuatro datos mínimos del perfil quedan guardados y la fecha de alta se estampa
    sola. Si falla, un perfil queda incompleto o un correo se reescribe y la cuenta cambia de dueño.
    """
    sufijo = _unico()
    uid = _usuario(db, sufijo)
    fila = db.execute(
        text("SELECT correo, nombre, apellido, fecha_nacimiento, creado_en FROM usuario WHERE id = :id"),
        {"id": uid},
    ).one()
    assert fila.correo == f"ana.{sufijo}@correo.com"
    assert (fila.nombre, fila.apellido, fila.fecha_nacimiento) == ("Ana", "Pérez", date(2000, 3, 14))
    assert fila.creado_en is not None

    with pytest.raises(DBAPIError, match="correo"):
        with db.begin_nested():
            db.execute(text("UPDATE usuario SET correo = 'otro@correo.com' WHERE id = :id"), {"id": uid})


def test_la_sede_se_guarda_con_nombre_direccion_y_horario(db: Connection) -> None:
    """una sede se guarda con nombre, dirección y horario de funcionamiento @MOD-01-H01-02

    Verifica: la sede guarda nombre, calle y altura, apertura, cierre y los días que abre. Si falla,
    las reservas no tienen contra qué horario validarse.
    """
    sufijo = _unico()
    sid = _sede(db, sufijo)
    fila = db.execute(
        text("SELECT nombre, calle, altura, apertura, cierre, dias, activa FROM sede WHERE id = :id"),
        {"id": sid},
    ).one()
    assert fila.nombre == f"Sede Prueba {sufijo}"
    assert (fila.calle, fila.altura) == ("Av. Rivadavia", 19850)
    assert (fila.apertura, fila.cierre) == (time(8), time(23))
    assert list(fila.dias) == [1, 2, 3, 4, 5, 6, 7]
    assert fila.activa is True


def test_el_espacio_pertenece_a_una_sede_y_tiene_nombre_compuesto(db: Connection) -> None:
    """un espacio se guarda asociado a una sede, con tipo y un nombre compuesto por sede, dirección, tipo y número @MOD-01-H01-03

    Verifica: el nombre sale de la sede, la calle sin su prefijo, la altura, el deporte, el tipo y el
    número, sin tildes ni espacios, como en el prototipo; y no hay dos espacios con el mismo número
    del mismo tipo en una sede. Si falla, dos canchas se confunden en una reserva.
    """
    from app.modules.espacios.reglas import nombre_compuesto

    assert nombre_compuesto("Sede Morón", "Av. Rivadavia", 19850, "Fútbol", "F5", 1) == (
        "Moron_Rivadavia_19850_Futbol_F5_1"
    )
    assert nombre_compuesto("Sede Ramos Mejía", "Calle Belgrano", 1240, "Hockey", "H7", 1) == (
        "RamosMejia_Belgrano_1240_Hockey_H7_1"
    )
    assert nombre_compuesto("Sede San Justo", "Av. Casanova", 320, "Golf", "CORTO", 2) == (
        "SanJusto_Casanova_320_Golf_CORTO_2"
    )

    sufijo = _unico()
    sid = _sede(db, sufijo)
    eid = _espacio(db, sid, sufijo)
    fila = db.execute(text("SELECT sede_id, tipo, nombre FROM espacio WHERE id = :id"), {"id": eid}).one()
    assert (fila.sede_id, fila.tipo) == (sid, "F5")
    assert fila.nombre == f"Prueba{sufijo}_Rivadavia_19850_Futbol_F5_1"

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
        text("SELECT usuario_id, espacio_id, inicio, fin, precio_por_hora, total, estado, creado_en FROM reserva WHERE id = :id"),
        {"id": rid},
    ).one()
    assert (fila.usuario_id, fila.espacio_id) == (uid, eid)
    assert fila.inicio == inicio and fila.fin == inicio + timedelta(hours=2)
    assert (fila.precio_por_hora, fila.total) == (38000, 76000)
    assert fila.estado == "activa"
    assert fila.creado_en is not None


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

    db.execute(text("UPDATE reserva SET estado = 'cancelada' WHERE id = :id"), {"id": primera})
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
        text("SELECT id, estado_actual FROM reserva_con_estado WHERE usuario_id = :u"), {"u": uid}
    ).all()
    assert [(f.id, f.estado_actual) for f in filas] == [(rid, "completada")]
