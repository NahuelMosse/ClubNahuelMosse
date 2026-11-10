"""Lo que `BookingsSql` decide dentro de `en_transaccion`, contra la base real."""

import uuid
from datetime import date, datetime, time, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.availability.rules import OpeningHours
from app.modules.bookings.repository import BookingsSql
from app.shared.errors import ConcurrentChange, OpeningHoursChanged, Unavailable

CLUB = ZoneInfo("America/Argentina/Buenos_Aires")


def _usuario(api: TestClient, engine: Engine, token: str) -> UUID:
    correo = api.get("/me", headers={"Authorization": f"Bearer {token}"}).json()["email"]
    with engine.connect() as conn:
        fila = conn.execute(text("SELECT id FROM app_user WHERE email = :c"), {"c": correo})
        return UUID(str(fila.scalar_one()))


def _cancha(api: TestClient, admin_token: str, sede_id: str) -> str:
    r = api.post(
        "/spaces",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"venue_id": sede_id, "sport": "Futbol", "kind": "F5", "covered": False,
              "lit": True, "price_per_hour": 38000},
    )  # fmt: skip
    return str(r.json()["id"])


def _at_hour(dias: int, hora: int) -> datetime:
    return datetime.combine(date.today() + timedelta(days=dias), time(hora), tzinfo=CLUB)


def _schedule(engine: Engine, espacio: UUID) -> OpeningHours:
    with engine.connect() as conn:
        agenda = BookingsSql(conn).opening_hours(espacio)
    assert agenda is not None
    return agenda


def _dar_de_baja(engine: Engine, tabla: str, columna: str, id_: UUID) -> None:
    with engine.begin() as conn:
        conn.execute(
            text(f"UPDATE {tabla} SET {columna} = false, deactivated_at = now() WHERE id = :id"),
            {"id": id_},
        )


@pytest.fixture
def court(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> tuple[str, str, UUID]:
    """La sede, una cancha suya y quien reserva."""
    return venue[0], _cancha(api, admin_token, venue[0]), _usuario(api, engine, user_token)


def test_una_reserva_ajena_o_inexistente_no_se_encuentra(
    engine: Engine, court: tuple[str, str, UUID]
) -> None:
    """una reserva ajena o inexistente no se encuentra @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, espacio_api, yo = court
    espacio = UUID(espacio_api)
    with engine.connect() as conn:
        reserva = BookingsSql(conn).insert(
            yo, espacio, _at_hour(1, 10), _at_hour(1, 11), _schedule(engine, espacio)
        )
        repositorio = BookingsSql(conn)

        assert repositorio.own(uuid.uuid4(), reserva.id) is None
        assert repositorio.any_one(uuid.uuid4()) is None


def test_mover_con_el_horario_viejo_de_la_sede_no_cambia_nada(
    engine: Engine, court: tuple[str, str, UUID]
) -> None:
    """mover con el horario viejo de la sede no cambia nada @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    sede_id, espacio_api, yo = court
    espacio = UUID(espacio_api)
    vieja = _schedule(engine, espacio)
    with engine.connect() as conn:
        reserva = BookingsSql(conn).insert(yo, espacio, _at_hour(1, 10), _at_hour(1, 11), vieja)
    with engine.begin() as conn:
        conn.execute(text("UPDATE venue SET opens_at = '09:00' WHERE id = :s"), {"s": sede_id})

    with engine.connect() as conn, pytest.raises(OpeningHoursChanged):
        BookingsSql(conn).move(
            yo,
            reserva.id,
            (espacio, reserva.starts_at),
            espacio,
            _at_hour(1, 12),
            _at_hour(1, 13),
            vieja,
        )


def test_una_reserva_cancelada_no_se_mueve(engine: Engine, court: tuple[str, str, UUID]) -> None:
    """una reserva cancelada no se mueve @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, espacio_api, yo = court
    espacio = UUID(espacio_api)
    agenda = _schedule(engine, espacio)
    with engine.connect() as conn:
        reserva = BookingsSql(conn).insert(yo, espacio, _at_hour(1, 10), _at_hour(1, 11), agenda)
        BookingsSql(conn).cancel(yo, reserva.id)

    with engine.connect() as conn, pytest.raises(ConcurrentChange):
        BookingsSql(conn).move(
            yo,
            reserva.id,
            (espacio, reserva.starts_at),
            espacio,
            _at_hour(1, 12),
            _at_hour(1, 13),
            agenda,
        )


@pytest.mark.parametrize("de_baja", ["venue", "space"])
def test_no_se_reserva_ni_se_mueve_a_una_cancha_de_baja(
    engine: Engine, court: tuple[str, str, UUID], de_baja: str
) -> None:
    """no se reserva ni se mueve a una cancha cuya sede o ella misma está de baja
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    sede_id, espacio_api, yo = court
    espacio = UUID(espacio_api)
    agenda = _schedule(engine, espacio)
    with engine.connect() as conn:
        reserva = BookingsSql(conn).insert(yo, espacio, _at_hour(1, 10), _at_hour(1, 11), agenda)
    if de_baja == "venue":
        _dar_de_baja(engine, "venue", "active", UUID(sede_id))
    else:
        _dar_de_baja(engine, "space", "active", espacio)

    with engine.connect() as conn:
        with pytest.raises(Unavailable):
            BookingsSql(conn).insert(yo, espacio, _at_hour(2, 10), _at_hour(2, 11), agenda)
        with pytest.raises(Unavailable):
            BookingsSql(conn).move(
                yo,
                reserva.id,
                (espacio, reserva.starts_at),
                espacio,
                _at_hour(1, 12),
                _at_hour(1, 13),
                agenda,
            )  # fmt: skip
