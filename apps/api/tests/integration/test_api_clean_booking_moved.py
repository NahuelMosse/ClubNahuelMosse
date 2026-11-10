"""A booking moves only from where it is, against the real database."""

from uuid import UUID

import pytest
from sqlalchemy import Engine

from app.modules.bookings.repository import BookingsSql
from app.shared.errors import ConcurrentChange
from tests.integration.test_api_clean_bookings import _at_hour, _schedule, court

__all__ = ["court"]


def test_a_booking_that_already_moved_is_not_moved_again_from_where_it_was(
    engine: Engine, court: tuple[str, str, UUID]
) -> None:
    """a booking that already moved is not moved again from where it was
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, space_api, me = court
    space = UUID(space_api)
    schedule = _schedule(engine, space)
    with engine.connect() as conn:
        booking = BookingsSql(conn).insert(me, space, _at_hour(1, 10), _at_hour(1, 11), schedule)

    with engine.connect() as conn, pytest.raises(ConcurrentChange):
        BookingsSql(conn).move(
            me,
            booking.id,
            (space, _at_hour(1, 9)),
            space,
            _at_hour(1, 12),
            _at_hour(1, 13),
            schedule,
        )
