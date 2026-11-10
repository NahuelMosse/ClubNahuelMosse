from datetime import UTC, datetime
from uuid import UUID

from app.modules.notifications.rules import VoidedBooking, forced_cancellation_message


def _voided(booking_number: int = 7, reason: str = "mantenimiento de la cancha") -> VoidedBooking:
    return VoidedBooking(
        booking_id=UUID(int=booking_number),
        # Wed 11 at 20:00 at the club (UTC−3)
        starts_at=datetime(2026, 11, 11, 23, 0, tzinfo=UTC),
        sport="Futbol",
        kind="F5",
        venue="Sede Ramos Mejía",
        reason=reason,
    )


def test_one_booking_states_sport_venue_day_time_and_reason() -> None:
    notice = forced_cancellation_message([_voided()])

    assert notice.title == "The club voided your booking"
    assert notice.body == (
        "Football 5 · Sede Ramos Mejía · Wed 11, 20:00. Reason: mantenimiento de la cancha."
    )
    assert notice.data == {"kind": "forced_cancellation", "booking_id": str(UUID(int=7))}


def test_several_bookings_state_how_many_and_do_not_point_to_one() -> None:
    notice = forced_cancellation_message([_voided(1), _voided(2), _voided(3)])

    assert notice.title == "The club voided 3 of your bookings"
    assert notice.body == "You have 3 bookings voided by the club. See the detail in your history."
    assert notice.data == {"kind": "forced_cancellation"}


def test_a_reason_longer_than_two_hundred_characters_is_trimmed() -> None:
    reason = "x" * 200

    body = forced_cancellation_message([_voided(reason=reason)]).body
    assert body.endswith(f"Reason: {reason}.")

    body = forced_cancellation_message([_voided(reason=reason + "y")]).body
    assert body.endswith(f"Reason: {'x' * 199}….")
