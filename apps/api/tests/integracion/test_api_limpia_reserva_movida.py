"""Una reserva se mueve sólo desde donde está, contra la base real."""

import pytest
from sqlalchemy import Engine

from app.infraestructura.reservas import ReservasSql
from app.shared.errores import Cambiado
from tests.integracion.test_api_limpia_reservas import _a_las, _agenda, cancha

__all__ = ["cancha"]


def test_una_reserva_que_ya_se_movio_no_se_vuelve_a_mover_desde_donde_estaba(
    motor: Engine, cancha: tuple[int, int, int]
) -> None:
    """una reserva que ya se movió no se vuelve a mover desde donde estaba
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, espacio, yo = cancha
    agenda = _agenda(motor, espacio)
    with motor.connect() as conn:
        reserva = ReservasSql(conn).insertar(yo, espacio, _a_las(1, 10), _a_las(1, 11), agenda)

    with motor.connect() as conn, pytest.raises(Cambiado):
        ReservasSql(conn).mover(
            yo, reserva.id, (espacio, _a_las(1, 9)), espacio, _a_las(1, 12), _a_las(1, 13), agenda
        )
