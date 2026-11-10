from datetime import date, datetime, time, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest

from app.modules.availability.rules import (
    OpeningHours,
    SlotGrid,
    duration_error,
    slot_grid,
    validate_booking,
    validate_query,
    validate_range,
)
from app.modules.availability.use_cases import available_slots
from app.shared.errors import InvalidData, Unavailable

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")
ALL_DAYS = (1, 2, 3, 4, 5, 6, 7)
THURSDAY = date(2026, 11, 12)


def _at(day: date, hour: int) -> datetime:
    return datetime.combine(day, time(hour), tzinfo=ZONE)


def _starts(g: SlotGrid) -> list[str]:
    return [f"{f.start:%H}" for f in g.slots]


def test_from_opening_to_closing_in_whole_hours() -> None:
    g = slot_grid(
        OpeningHours(time(8), time(23), ALL_DAYS), THURSDAY, 1, _at(THURSDAY - timedelta(1), 9), []
    )
    assert _starts(g)[0] == "08" and _starts(g)[-1] == "22"
    assert len(g.slots) == 15 and g.unavailable == 0


def test_with_more_hours_the_last_slot_ends_at_closing() -> None:
    g = slot_grid(
        OpeningHours(time(8), time(23), ALL_DAYS), THURSDAY, 3, _at(THURSDAY - timedelta(1), 9), []
    )
    assert _starts(g)[-1] == "20"
    assert g.slots[-1].end == _at(THURSDAY, 23)


def test_a_midnight_closing_leaves_the_23_slot() -> None:
    g = slot_grid(
        OpeningHours(time(20), time(0), ALL_DAYS), THURSDAY, 1, _at(THURSDAY - timedelta(1), 9), []
    )
    assert _starts(g) == ["20", "21", "22", "23"]


def test_today_does_not_offer_the_hour_that_already_started() -> None:
    now = datetime.combine(THURSDAY, time(14, 0), tzinfo=ZONE)
    g = slot_grid(OpeningHours(time(8), time(23), ALL_DAYS), THURSDAY, 1, now, [])
    assert _starts(g)[0] == "15"


def test_a_booking_leaves_the_slots_it_overlaps_unavailable() -> None:
    taken = [(_at(THURSDAY, 11), _at(THURSDAY, 12))]
    g = slot_grid(
        OpeningHours(time(8), time(23), ALL_DAYS),
        THURSDAY,
        2,
        _at(THURSDAY - timedelta(1), 9),
        taken,
    )
    free = {f"{f.start:%H}": f.available for f in g.slots}
    assert (free["09"], free["10"], free["11"], free["12"]) == (True, False, False, True)
    assert g.unavailable == 2


def test_the_venue_is_closed_that_day() -> None:
    g = slot_grid(
        OpeningHours(time(8), time(23), (1, 2, 3)), THURSDAY, 1, _at(THURSDAY - timedelta(1), 9), []
    )
    assert not g.opens and g.slots == ()


@pytest.mark.parametrize(
    ("days", "hours", "fields"),
    [(0, 1, set()), (6, 4, set()), (7, 1, {"date"}), (-1, 1, {"date"}), (0, 5, {"hours"})],
)
def test_the_query_covers_today_to_six_days_ahead_and_1_to_4_hours(
    days: int, hours: int, fields: set[str]
) -> None:
    assert set(validate_query(THURSDAY + timedelta(days), THURSDAY, hours)) == fields


class _Hours:
    def __init__(self, schedule: OpeningHours | None) -> None:
        self._schedule = schedule
        self.requested: tuple[datetime, datetime] | None = None

    def opening_hours(self, space_id: UUID) -> OpeningHours | None:
        return self._schedule

    def taken(
        self,
        space_id: UUID,
        since: datetime,
        until: datetime,
        excluding: tuple[UUID, UUID] | None = None,
    ) -> list[tuple[datetime, datetime]]:
        self.requested = (since, until)
        return []


def test_without_a_date_it_queries_today() -> None:
    hours = _Hours(OpeningHours(time(8), time(23), ALL_DAYS))
    g = available_slots(hours, UUID(int=1), None, 1, _at(THURSDAY, 9))
    assert g.day == THURSDAY
    assert hours.requested == (_at(THURSDAY, 0), _at(THURSDAY, 0) + timedelta(days=2))


def test_a_space_that_is_not_active_is_not_queried() -> None:
    with pytest.raises(Unavailable):
        available_slots(_Hours(None), UUID(int=1), THURSDAY, 1, _at(THURSDAY, 9))


def test_a_date_outside_the_week_is_rejected() -> None:
    with pytest.raises(InvalidData):
        available_slots(
            _Hours(OpeningHours(time(8), time(23), ALL_DAYS)),
            UUID(int=1),
            THURSDAY + timedelta(8),
            1,
            _at(THURSDAY, 9),
        )


@pytest.mark.parametrize(
    ("since", "until", "errors"),
    [
        (10, 12, {}),
        (22, 0, {"until": "The venue closes at 23:00"}),
        (18, 18, {"until": "The minimum duration is one hour"}),
        (20, 18, {"until": "The minimum duration is one hour"}),
        (10, 15, {"until": "The maximum duration is 4 hours"}),
        (7, 9, {"start_hour": "The venue opens at 08:00"}),
    ],
)
def test_a_range_is_validated_against_the_venue_hours(
    since: int, until: int, errors: dict[str, str]
) -> None:
    schedule = OpeningHours(time(8), time(23), ALL_DAYS)
    assert validate_range(
        schedule, THURSDAY, time(since), time(until), _at(THURSDAY - timedelta(1), 9)
    ) == (errors)


def test_a_range_that_already_started_or_is_on_another_day_is_not_queried() -> None:
    schedule = OpeningHours(time(8), time(23), (1, 2, 3, 4))
    now = datetime.combine(THURSDAY, time(18, 20), tzinfo=ZONE)
    assert validate_range(schedule, THURSDAY, time(18), time(19), now) == {
        "start_hour": "The time must be in the future"
    }
    assert validate_range(schedule, THURSDAY - timedelta(1), time(18), time(19), now) == {
        "date": "The date must be in the future"
    }
    assert validate_range(schedule, THURSDAY + timedelta(1), time(18), time(19), now) == {
        "date": "The venue is closed that day"
    }
    assert validate_range(schedule, THURSDAY + timedelta(7), time(18), time(19), now) == {
        "date": "Choose a day within the next 7"
    }
    assert validate_range(schedule, THURSDAY, time(19, 30), time(21), now) == {
        "start_hour": "Choose an on-the-hour time"
    }


@pytest.mark.parametrize(
    ("since", "hours", "field", "message"),
    [
        (10, 0, "until", "The minimum duration is one hour"),
        (10, 5, "until", "The maximum duration is 4 hours"),
        (22, 3, "until", "The venue closes at 23:00"),
        (21, 2, None, None),
    ],
)
def test_a_booking_is_validated_by_its_start_and_its_duration(
    since: int, hours: int, field: str | None, message: str | None
) -> None:
    errors = validate_booking(
        OpeningHours(time(8), time(23), ALL_DAYS),
        THURSDAY,
        time(since),
        hours,
        _at(THURSDAY - timedelta(1), 9),
    )
    assert errors == ({} if field is None else {field: message})


@pytest.mark.parametrize(
    ("hours", "message"),
    [
        (-1, "The minimum duration is one hour"),
        (0, "The minimum duration is one hour"),
        (1, None),
        (4, None),
        (5, "The maximum duration is 4 hours"),
        (10**12, "The maximum duration is 4 hours"),
    ],
)
def test_a_duration_is_bookable_from_one_to_four_hours(hours: int, message: str | None) -> None:
    assert duration_error(hours) == message
