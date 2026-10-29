import uuid
from uuid import UUID
from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from sqlalchemy import Engine, create_engine, text

from app.modules.bookings.repository import BookingsSql
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
                "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni,"
                " birth_date) VALUES (:uid, :email, 'Ana', 'Pérez', :dni, '2000-03-14')"
                " RETURNING id"
            ),
            {
                "uid": f"uid-{s}",
                "email": f"ana.{s}@correo.com",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            },
        ).scalar_one()
        sede = conn.execute(
            text(
                "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Rivadavia', 19850, '08:00', '23:00',"
                " '{1,2,3,4,5,6,7}') RETURNING id"
            ),
            {"n": f"Sede Propia {s}"},
        ).scalar_one()
        espacio = conn.execute(
            text(
                "INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour) VALUES (:venue, 'Futbol', 'F5', 1, :n, false,"
                " true, 38000) RETURNING id"
            ),
            {"venue": sede, "n": f"Propia{s}_Rivadavia_19850_Futbol_F5_1"},
        ).scalar_one()
    return {"user": usuario, "venue": sede, "space": espacio}


def _reserva(
    motor: Engine, mundo: dict[str, UUID], inicio: datetime, creada: datetime | None = None
) -> UUID:
    with motor.begin() as conn:
        return conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                " total, created_at, updated_at) VALUES (:u, :e, :i, :f, 38000, 38000,"
                " coalesce(:c, now()), coalesce(:c, now())) RETURNING id"
            ),
            {
                "u": mundo["user"],
                "e": mundo["space"],
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
        assert UsersSql(conn).deactivate(mundo["user"]) is True
    assert _uno(motor, "SELECT status FROM booking WHERE id = :i", i=reserva) == "canceled"
    assert not _uno(motor, "SELECT active FROM app_user WHERE id = :i", i=mundo["user"])


def test_cancelar_una_reserva_deja_su_aviso(motor: Engine) -> None:
    """cancelar una reserva sigue dejando su aviso @REV-06-S6 @assumption:REV-06-ASM-05"""
    mundo = _mundo(motor)
    reserva = _reserva(motor, mundo, _hora(dias=3))
    with motor.connect() as conn:
        BookingsSql(conn).cancel(mundo["user"], reserva)
    assert (
        _uno(
            motor,
            "SELECT count(*) FROM notification WHERE booking_id = :i"
            " AND kind = 'user_cancellation'",
            i=reserva,
        )
        == 1
    )


def test_baja_de_sede_da_de_baja_sus_espacios(motor: Engine) -> None:
    """dar de baja una sede sigue dando de baja sus espacios @REV-06-S6 @assumption:REV-06-ASM-05"""
    mundo = _mundo(motor)
    with motor.connect() as conn:
        VenuesSql(conn).deactivate(mundo["venue"], mundo["user"])
    assert not _uno(motor, "SELECT active FROM venue WHERE id = :i", i=mundo["venue"])
    assert not _uno(motor, "SELECT active FROM space WHERE id = :i", i=mundo["space"])


def test_la_baja_de_sede_sobrevive_al_reinicio(motor: Engine) -> None:
    """la baja de una sede y de sus espacios sobrevive al reinicio de la app sobre la misma base @REV-06-S6 @assumption:REV-06-ASM-05"""
    mundo = _mundo(motor)
    with motor.connect() as conn:
        VenuesSql(conn).deactivate(mundo["venue"], mundo["user"])
    nuevo = create_engine(motor.url)
    try:
        assert not _uno(nuevo, "SELECT active FROM venue WHERE id = :i", i=mundo["venue"])
        assert not _uno(nuevo, "SELECT active FROM space WHERE id = :i", i=mundo["space"])
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
        VenuesSql(conn).deactivate(mundo["venue"], mundo["user"])
    assert _uno(motor, "SELECT active FROM venue WHERE id = :i", i=mundo["venue"])
    assert _uno(motor, "SELECT active FROM space WHERE id = :i", i=mundo["space"])
