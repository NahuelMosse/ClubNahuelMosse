"""Una reserva se mueve sólo desde donde está, contra la base real."""

from uuid import UUID

import pytest
from sqlalchemy import Engine

from app.modules.bookings.repository import BookingsSql
from app.shared.errors import ConcurrentChange
from tests.integration.test_api_clean_bookings import _at_hour, _schedule, court

__all__ = ["court"]


def test_una_reserva_que_ya_se_movio_no_se_vuelve_a_mover_desde_donde_estaba(
    engine: Engine, court: tuple[str, str, UUID]
) -> None:
    """una reserva que ya se movió no se vuelve a mover desde donde estaba
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, espacio_api, yo = court
    espacio = UUID(espacio_api)
    agenda = _schedule(engine, espacio)
    with engine.connect() as conn:
        reserva = BookingsSql(conn).insert(yo, espacio, _at_hour(1, 10), _at_hour(1, 11), agenda)

    with engine.connect() as conn, pytest.raises(ConcurrentChange):
        BookingsSql(conn).move(
            yo,
            reserva.id,
            (espacio, _at_hour(1, 9)),
            espacio,
            _at_hour(1, 12),
            _at_hour(1, 13),
            agenda,
        )
