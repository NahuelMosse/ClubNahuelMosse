"""Lo que `ReservasSql` decide dentro de `en_transaccion`, contra la base real."""

from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.horarios.reglas import Agenda
from app.modules.reservas.repositorio import ReservasSql
from app.shared.errores import AgendaCambiada, Cambiado, NoDisponible

CLUB = ZoneInfo("America/Argentina/Buenos_Aires")


def _usuario(api: TestClient, motor: Engine, token: str) -> int:
    correo = api.get("/yo", headers={"Authorization": f"Bearer {token}"}).json()["correo"]
    with motor.connect() as conn:
        fila = conn.execute(text("SELECT id FROM usuario WHERE correo = :c"), {"c": correo})
        return int(fila.scalar_one())


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


def _agenda(motor: Engine, espacio: int) -> Agenda:
    with motor.connect() as conn:
        agenda = ReservasSql(conn).agenda(espacio)
    assert agenda is not None
    return agenda


def _dar_de_baja(motor: Engine, tabla: str, columna: str, id_: int) -> None:
    with motor.begin() as conn:
        conn.execute(
            text(f"UPDATE {tabla} SET {columna} = false, dado_de_baja_en = now() WHERE id = :id"),
            {"id": id_},
        )


@pytest.fixture
def cancha(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> tuple[int, int, int]:
    """La sede, una cancha suya y quien reserva."""
    return sede[0], _cancha(api, token_admin, sede[0]), _usuario(api, motor, token_usuario)


def test_una_reserva_ajena_o_inexistente_no_se_encuentra(
    motor: Engine, cancha: tuple[int, int, int]
) -> None:
    """una reserva ajena o inexistente no se encuentra @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, espacio, yo = cancha
    with motor.connect() as conn:
        reserva = ReservasSql(conn).insertar(
            yo, espacio, _a_las(1, 10), _a_las(1, 11), _agenda(motor, espacio)
        )
        repositorio = ReservasSql(conn)

        assert repositorio.propia(yo + 1_000_000, reserva.id) is None
        assert repositorio.una_de_cualquiera(reserva.id + 1_000_000) is None


def test_mover_con_el_horario_viejo_de_la_sede_no_cambia_nada(
    motor: Engine, cancha: tuple[int, int, int]
) -> None:
    """mover con el horario viejo de la sede no cambia nada @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    sede_id, espacio, yo = cancha
    vieja = _agenda(motor, espacio)
    with motor.connect() as conn:
        reserva = ReservasSql(conn).insertar(yo, espacio, _a_las(1, 10), _a_las(1, 11), vieja)
    with motor.begin() as conn:
        conn.execute(text("UPDATE sede SET apertura = '09:00' WHERE id = :s"), {"s": sede_id})

    with motor.connect() as conn, pytest.raises(AgendaCambiada):
        ReservasSql(conn).mover(
            yo, reserva.id, (espacio, reserva.inicio), espacio, _a_las(1, 12), _a_las(1, 13), vieja
        )


def test_una_reserva_cancelada_no_se_mueve(motor: Engine, cancha: tuple[int, int, int]) -> None:
    """una reserva cancelada no se mueve @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, espacio, yo = cancha
    agenda = _agenda(motor, espacio)
    with motor.connect() as conn:
        reserva = ReservasSql(conn).insertar(yo, espacio, _a_las(1, 10), _a_las(1, 11), agenda)
        ReservasSql(conn).cancelar(yo, reserva.id)

    with motor.connect() as conn, pytest.raises(Cambiado):
        ReservasSql(conn).mover(
            yo, reserva.id, (espacio, reserva.inicio), espacio, _a_las(1, 12), _a_las(1, 13), agenda
        )


@pytest.mark.parametrize("de_baja", ["sede", "espacio"])
def test_no_se_reserva_ni_se_mueve_a_una_cancha_de_baja(
    motor: Engine, cancha: tuple[int, int, int], de_baja: str
) -> None:
    """no se reserva ni se mueve a una cancha cuya sede o ella misma está de baja
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    sede_id, espacio, yo = cancha
    agenda = _agenda(motor, espacio)
    with motor.connect() as conn:
        reserva = ReservasSql(conn).insertar(yo, espacio, _a_las(1, 10), _a_las(1, 11), agenda)
    if de_baja == "sede":
        _dar_de_baja(motor, "sede", "activa", sede_id)
    else:
        _dar_de_baja(motor, "espacio", "activo", espacio)

    with motor.connect() as conn:
        with pytest.raises(NoDisponible):
            ReservasSql(conn).insertar(yo, espacio, _a_las(2, 10), _a_las(2, 11), agenda)
        with pytest.raises(NoDisponible):
            ReservasSql(conn).mover(
                yo, reserva.id, (espacio, reserva.inicio), espacio, _a_las(1, 12), _a_las(1, 13),
                agenda,
            )  # fmt: skip
