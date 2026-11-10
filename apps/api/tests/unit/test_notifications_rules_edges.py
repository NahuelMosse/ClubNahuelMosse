"""Edges of the notice rules: unknown kind, a single voided booking and the reason limit."""

from datetime import UTC, datetime
from uuid import uuid4

from app.modules.notifications.rules import (
    REASON_LIMIT,
    VoidedBooking,
    forced_cancellation_message,
    forced_cancellations_message,
    short_kind,
)
from app.modules.spaces import CATALOG

START = datetime(2026, 5, 4, 15, 0, tzinfo=UTC)


def _voided(reason: str) -> VoidedBooking:
    sport = CATALOG[0]
    return VoidedBooking(
        booking_id=uuid4(),
        starts_at=START,
        sport=sport.key,
        kind=sport.kinds[0].key,
        venue="Sede Centro",
        reason=reason,
    )


def test_an_unknown_kind_of_the_sport_names_the_sport_and_does_not_fail() -> None:  # @ENG-14-S1
    sport = CATALOG[0]
    unknown = "no-existe"
    assert short_kind(sport.key, unknown) == sport.key
    assert short_kind(unknown, unknown) == unknown


def test_a_single_voided_booking_carries_its_booking_and_several_only_the_count() -> (
    None
):  # @ENG-14-S1
    one = forced_cancellation_message([_voided("Lluvia")])
    assert one.title == "The club voided your booking"
    assert one.data["booking_id"]

    two = forced_cancellation_message([_voided("Lluvia"), _voided("Lluvia")])
    assert two == forced_cancellations_message(2)
    assert two.title == "The club voided 2 of your bookings"
    assert two.data == {"kind": "forced_cancellation"}


def test_a_reason_at_the_exact_limit_is_not_trimmed() -> None:  # @ENG-14-S1
    exact = "m" * REASON_LIMIT
    assert f"Reason: {exact}." in forced_cancellation_message([_voided(exact)]).body

    over = forced_cancellation_message([_voided("m" * (REASON_LIMIT + 1))]).body
    assert "…" in over
