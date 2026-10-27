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


def _usuario(api: TestClient, motor: Engine, token: str) -> UUID:
    correo = api.get("/yo", headers={"Authorization": f"Bearer {token}"}).json()["correo"]
    with motor.connect() as conn:
        fila = conn.execute(text("SELECT id FROM usuario WHERE correo = :c"), {"c": correo})
        return UUID(str(fila.scalar_one()))


def _cancha(api: TestClient, token_admin: str, sede_id: str) -> str:
    r = api.post(
        "/espacios",
        headers={"Authorization": f"Bearer {token_admin}"},
        json={"sede_id": sede_id, "deporte": "Futbol", "tipo": "F5", "techada": False,
              "iluminada": True, "precio_por_hora": 38000},
    )  # fmt: skip
    return str(r.json()["id"])


def _a_las(dias: int, hora: int) -> datetime:
    return datetime.combine(date.today() + timedelta(days=dias), time(hora), tzinfo=CLUB)


def _agenda(motor: Engine, espacio: UUID) -> OpeningHours:
    with motor.connect() as conn:
        agenda = BookingsSql(conn).opening_hours(espacio)
    assert agenda is not None
    return agenda


def _dar_de_baja(motor: Engine, tabla: str, columna: str, id_: UUID) -> None:
    with motor.begin() as conn:
        conn.execute(
            text(f"UPDATE {tabla} SET {columna} = false, dado_de_baja_en = now() WHERE id = :id"),
            {"id": id_},
        )


@pytest.fixture
def cancha(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> tuple[str, str, UUID]:
    """La sede, una cancha suya y quien reserva."""
    return sede[0], _cancha(api, token_admin, sede[0]), _usuario(api, motor, token_usuario)


def test_una_reserva_ajena_o_inexistente_no_se_encuentra(
    motor: Engine, cancha: tuple[str, str, UUID]
) -> None:
    """una reserva ajena o inexistente no se encuentra @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, espacio_api, yo = cancha
    espacio = UUID(espacio_api)
    with motor.connect() as conn:
        reserva = BookingsSql(conn).insert(
            yo, espacio, _a_las(1, 10), _a_las(1, 11), _agenda(motor, espacio)
        )
        repositorio = BookingsSql(conn)

        assert repositorio.own(uuid.uuid4(), reserva.id) is None
        assert repositorio.any_one(uuid.uuid4()) is None


def test_mover_con_el_horario_viejo_de_la_sede_no_cambia_nada(
    motor: Engine, cancha: tuple[str, str, UUID]
) -> None:
    """mover con el horario viejo de la sede no cambia nada @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    sede_id, espacio_api, yo = cancha
    espacio = UUID(espacio_api)
    vieja = _agenda(motor, espacio)
    with motor.connect() as conn:
        reserva = BookingsSql(conn).insert(yo, espacio, _a_las(1, 10), _a_las(1, 11), vieja)
    with motor.begin() as conn:
        conn.execute(text("UPDATE sede SET apertura = '09:00' WHERE id = :s"), {"s": sede_id})

    with motor.connect() as conn, pytest.raises(OpeningHoursChanged):
        BookingsSql(conn).move(
            yo, reserva.id, (espacio, reserva.inicio), espacio, _a_las(1, 12), _a_las(1, 13), vieja
        )


def test_una_reserva_cancelada_no_se_mueve(motor: Engine, cancha: tuple[str, str, UUID]) -> None:
    """una reserva cancelada no se mueve @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, espacio_api, yo = cancha
    espacio = UUID(espacio_api)
    agenda = _agenda(motor, espacio)
    with motor.connect() as conn:
        reserva = BookingsSql(conn).insert(yo, espacio, _a_las(1, 10), _a_las(1, 11), agenda)
        BookingsSql(conn).cancel(yo, reserva.id)

    with motor.connect() as conn, pytest.raises(ConcurrentChange):
        BookingsSql(conn).move(
            yo, reserva.id, (espacio, reserva.inicio), espacio, _a_las(1, 12), _a_las(1, 13), agenda
        )


@pytest.mark.parametrize("de_baja", ["sede", "espacio"])
def test_no_se_reserva_ni_se_mueve_a_una_cancha_de_baja(
    motor: Engine, cancha: tuple[str, str, UUID], de_baja: str
) -> None:
    """no se reserva ni se mueve a una cancha cuya sede o ella misma está de baja
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    sede_id, espacio_api, yo = cancha
    espacio = UUID(espacio_api)
    agenda = _agenda(motor, espacio)
    with motor.connect() as conn:
        reserva = BookingsSql(conn).insert(yo, espacio, _a_las(1, 10), _a_las(1, 11), agenda)
    if de_baja == "sede":
        _dar_de_baja(motor, "sede", "activa", UUID(sede_id))
    else:
        _dar_de_baja(motor, "espacio", "activo", espacio)

    with motor.connect() as conn:
        with pytest.raises(Unavailable):
            BookingsSql(conn).insert(yo, espacio, _a_las(2, 10), _a_las(2, 11), agenda)
        with pytest.raises(Unavailable):
            BookingsSql(conn).move(
                yo, reserva.id, (espacio, reserva.inicio), espacio, _a_las(1, 12), _a_las(1, 13),
                agenda,
            )  # fmt: skip
