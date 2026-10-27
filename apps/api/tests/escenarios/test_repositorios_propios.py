import uuid
from uuid import UUID
from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from sqlalchemy import Connection, Engine, create_engine, text

from app.modules.bookings.repository import BookingsSql
from app.modules.notifications.repository import NotificationsSql
from app.modules.spaces.repository import SpacesSql
from app.modules.users.repository import UsersSql
from app.modules.venues.repository import VenuesSql


def _hora(dias: int = 0, minutos: int = 0) -> datetime:
    base = datetime.now(UTC).replace(minute=0, second=0, microsecond=0)
    return base + timedelta(days=dias, minutes=minutos)


def _mundo(motor: Engine) -> dict[str, UUID]:
    """Una cuenta, una sede con un espacio, todo confirmado en la base."""
    s = uuid.uuid4().hex[:8]
    with motor.begin() as conn:
        usuario = conn.execute(
            text(
                "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni,"
                " fecha_nacimiento) VALUES (:uid, :correo, 'Ana', 'Pérez', :dni, '2000-03-14')"
                " RETURNING id"
            ),
            {
                "uid": f"uid-{s}",
                "correo": f"ana.{s}@correo.com",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            },
        ).scalar_one()
        sede = conn.execute(
            text(
                "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES (:n, 'Av. Rivadavia', 19850, '08:00', '23:00',"
                " '{1,2,3,4,5,6,7}') RETURNING id"
            ),
            {"n": f"Sede Propia {s}"},
        ).scalar_one()
        espacio = conn.execute(
            text(
                "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora) VALUES (:sede, 'Futbol', 'F5', 1, :n, false,"
                " true, 38000) RETURNING id"
            ),
            {"sede": sede, "n": f"Propia{s}_Rivadavia_19850_Futbol_F5_1"},
        ).scalar_one()
    return {"usuario": usuario, "sede": sede, "espacio": espacio}


def _reserva(
    motor: Engine, mundo: dict[str, UUID], inicio: datetime, creada: datetime | None = None
) -> UUID:
    with motor.begin() as conn:
        return conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                " total, creado_en, modificado_en) VALUES (:u, :e, :i, :f, 38000, 38000,"
                " coalesce(:c, now()), coalesce(:c, now())) RETURNING id"
            ),
            {
                "u": mundo["usuario"],
                "e": mundo["espacio"],
                "i": inicio,
                "f": inicio + timedelta(hours=1),
                "c": creada,
            },
        ).scalar_one()


def _uno(motor: Engine, sql: str, **datos: Any) -> Any:
    with motor.connect() as conn:
        return conn.execute(text(sql), datos).scalar_one()


def test_baja_de_cuenta_cancela_reservas_futuras(motor: Engine) -> None:
    """dar de baja una cuenta sigue cancelando sus reservas futuras @REV-06-S6 @assumption:REV-06-ASM-05"""
    mundo = _mundo(motor)
    reserva = _reserva(motor, mundo, _hora(dias=3))
    with motor.connect() as conn:
        assert UsersSql(conn).deactivate(mundo["usuario"]) is True
    assert _uno(motor, "SELECT estado FROM reserva WHERE id = :i", i=reserva) == "cancelada"
    assert not _uno(motor, "SELECT activo FROM usuario WHERE id = :i", i=mundo["usuario"])


def test_cancelar_una_reserva_deja_su_aviso(motor: Engine) -> None:
    """cancelar una reserva sigue dejando su aviso @REV-06-S6 @assumption:REV-06-ASM-05"""
    mundo = _mundo(motor)
    reserva = _reserva(motor, mundo, _hora(dias=3))
    with motor.connect() as conn:
        BookingsSql(conn).cancel(mundo["usuario"], reserva)
    assert (
        _uno(
            motor,
            "SELECT count(*) FROM notificacion WHERE reserva_id = :i"
            " AND tipo = 'cancelacion_usuario'",
            i=reserva,
        )
        == 1
    )


def test_baja_de_sede_da_de_baja_sus_espacios(motor: Engine) -> None:
    """dar de baja una sede sigue dando de baja sus espacios @REV-06-S6 @assumption:REV-06-ASM-05"""
    mundo = _mundo(motor)
    with motor.connect() as conn:
        VenuesSql(conn).deactivate(mundo["sede"], mundo["usuario"])
    assert not _uno(motor, "SELECT activa FROM sede WHERE id = :i", i=mundo["sede"])
    assert not _uno(motor, "SELECT activo FROM espacio WHERE id = :i", i=mundo["espacio"])


def test_la_baja_de_sede_sobrevive_al_reinicio(motor: Engine) -> None:
    """la baja de una sede y de sus espacios sobrevive al reinicio de la app sobre la misma base @REV-06-S6 @assumption:REV-06-ASM-05"""
    mundo = _mundo(motor)
    with motor.connect() as conn:
        VenuesSql(conn).deactivate(mundo["sede"], mundo["usuario"])
    nuevo = create_engine(motor.url)
    try:
        assert not _uno(nuevo, "SELECT activa FROM sede WHERE id = :i", i=mundo["sede"])
        assert not _uno(nuevo, "SELECT activo FROM espacio WHERE id = :i", i=mundo["espacio"])
    finally:
        nuevo.dispose()


def test_si_la_baja_de_sede_falla_no_queda_nada(
    motor: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """si la baja de una sede falla a mitad de camino no queda ni la sede dada de baja ni sus espacios @REV-06-S6 @assumption:REV-06-ASM-11"""
    mundo = _mundo(motor)
    original = SpacesSql.deactivate_venue_spaces

    def escribe_y_cae(self: SpacesSql, venue_id: UUID, author: UUID) -> None:
        original(self, venue_id, author)
        raise RuntimeError("falla después de escribir los espacios")

    monkeypatch.setattr(SpacesSql, "deactivate_venue_spaces", escribe_y_cae)
    with motor.connect() as conn, pytest.raises(RuntimeError):
        VenuesSql(conn).deactivate(mundo["sede"], mundo["usuario"])
    assert _uno(motor, "SELECT activa FROM sede WHERE id = :i", i=mundo["sede"])
    assert _uno(motor, "SELECT activo FROM espacio WHERE id = :i", i=mundo["espacio"])


def test_el_recordatorio_sale_una_hora_antes(
    motor: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """el recordatorio sale una hora antes del inicio, con la anticipación de dominio @REV-06-S9 @assumption:REV-06-ASM-08"""
    mundo = _mundo(motor)
    base = _hora(dias=9)
    ahora = base - timedelta(minutes=50)
    creada = base - timedelta(days=30)
    cerca = _reserva(motor, mundo, base, creada=creada)
    lejos = _reserva(motor, mundo, base + timedelta(hours=1), creada=creada)

    def ids(conn: Connection) -> list[UUID]:
        return [r.booking_id for r in NotificationsSql(conn).due(ahora, mundo["usuario"])]

    with motor.connect() as conn:
        assert ids(conn) == [cerca]
    monkeypatch.setattr("app.modules.notifications.repository.LEAD_TIME", timedelta(hours=2))
    with motor.connect() as conn:
        assert ids(conn) == [cerca, lejos]
