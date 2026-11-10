"""Bookings use cases with an in-memory repository: no database or emulator."""

from dataclasses import replace
from datetime import date, datetime, time, timedelta, timezone
from uuid import UUID

import pytest

from app.modules.availability.rules import OpeningHours
from app.modules.bookings.rules import (
    Booking,
    BookingHistory,
    BookingHistoryEntry,
    Counters,
    HistoryFilters,
)
from app.modules.bookings.use_cases import (
    MAX_REASON_LENGTH,
    admin_detail,
    book,
    cancel_booking,
    global_history,
    modify_booking,
    my_bookings,
    void_booking,
)
from app.modules.session.profile import Profile
from app.shared.errors import (
    ConcurrentChange,
    Forbidden,
    InvalidData,
    NotFound,
    OpeningHoursChanged,
    SlotTaken,
    Unavailable,
)

ZONE = timezone(timedelta(hours=-3))
NOW = datetime(2026, 3, 2, 10, 0, tzinfo=ZONE)  # Monday
TOMORROW = date(2026, 3, 3)
SCHEDULE = OpeningHours(opens_at=time(8, 0), closes_at=time(23, 0), open_days=(1, 2, 3, 4, 5, 6, 7))


def _id(number: int) -> UUID:
    return UUID(int=number)


def _profile(id: int = 1, role: str = "user") -> Profile:
    return Profile(
        id=_id(id), uid=f"u{id}", first_name="Ana", last_name="Paz", email="a@b.c", role=role,
        dni="1", birth_date=date(2000, 1, 1),
    )  # fmt: skip


def _booking(**changes: object) -> Booking:
    base = Booking(
        id=_id(5), space_id=_id(2), venue_id=_id(1), space="Cancha 1", sport="futbol",
        kind="5",
        venue="Centro", address="x", starts_at=datetime(2026, 3, 3, 18, 0, tzinfo=ZONE),
        ends_at=datetime(2026, 3, 3, 20, 0, tzinfo=ZONE), price_per_hour=100, total=200,
        status="active", reason=None,
    )  # fmt: skip
    return replace(base, **changes)


def _history(**changes: object) -> BookingHistoryEntry:
    r = _booking()
    base = BookingHistoryEntry(
        id=r.id, space_id=r.space_id, venue_id=r.venue_id, space=r.space,
        sport=r.sport, kind=r.kind, venue=r.venue, address=r.address, starts_at=r.starts_at,
        ends_at=r.ends_at, price_per_hour=100, total=200, status="active", reason=None,
        user_id=_id(1), user="Ana Paz", created_at=NOW, canceled_at=None,
        canceled_by_name=None, space_deactivated=False,
    )  # fmt: skip
    return replace(base, **changes)


class InMemory:
    def __init__(self) -> None:
        self.current_schedule: OpeningHours | None = SCHEDULE
        self.repeated_done: Booking | None = None
        self.own_of: Booking | None = None
        self.kind: tuple[UUID, str, str] | None = (_id(1), "futbol", "5")
        self.schedules_changed = 0
        self.calls: list[tuple] = []
        self.detail: BookingHistoryEntry | None = None

    def of_user(self, user_id, when):
        self.calls.append(("of_user", user_id, when))
        return [_booking()]

    def opening_hours(self, space_id):
        return self.current_schedule

    def repeated(self, user_id, space_id, start, end):
        self.calls.append(("repeated", user_id, space_id, start, end))
        return self.repeated_done

    def own(self, user_id, booking_id):
        self.calls.append(("own", user_id, booking_id))
        return self.own_of

    def space_kind(self, space_id):
        return self.kind

    def move(self, user_id, booking_id, before, space_id, start, end, schedule):
        self.calls.append(("move", user_id, booking_id, before, space_id, start, end))
        if self.schedules_changed:
            self.schedules_changed -= 1
            raise OpeningHoursChanged()
        return _booking(space_id=space_id, starts_at=start, ends_at=end)

    def cancel(self, user_id, booking_id):
        self.calls.append(("cancel", user_id, booking_id))
        return _booking(status="canceled")

    def insert(self, user_id, space_id, start, end, schedule):
        self.calls.append(("insert", user_id, space_id, start, end, schedule))
        if self.schedules_changed:
            self.schedules_changed -= 1
            raise OpeningHoursChanged()
        return _booking(space_id=space_id, starts_at=start, ends_at=end)

    def void(self, admin_id, booking_id, reason, space_id, start):
        self.calls.append(("void", admin_id, booking_id, reason, space_id, start))
        return _history(status="voided", reason=reason)

    def history(self, filters):
        self.calls.append(("history", filters))
        return BookingHistory(
            bookings=[], total=0, page=1, per_page=20,
            counters=Counters(all=0, active=0, completed=0, voided=0),
        )  # fmt: skip

    def any_one(self, booking_id):
        self.calls.append(("any_one", booking_id))
        return self.detail


def _errors(exception: pytest.ExceptionInfo[InvalidData]) -> dict[str, str]:
    return exception.value.errors


# my_bookings


def test_my_bookings_asks_only_for_those_of_the_requester() -> None:
    repo = InMemory()

    result = my_bookings(repo, _profile(id=7), "upcoming")

    assert result == [_booking()]
    assert repo.calls == [("of_user", _id(7), "upcoming")]
    my_bookings(repo, _profile(id=7), "history")
    assert repo.calls[-1] == ("of_user", _id(7), "history")


# book


def test_book_saves_with_the_requested_time_and_the_venue_schedule() -> None:
    repo = InMemory()

    booking = book(repo, _profile(), _id(2), TOMORROW, time(18, 0), 2, NOW)

    start = datetime(2026, 3, 3, 18, 0, tzinfo=ZONE)
    assert repo.calls[-1] == (
        "insert",
        _id(1),
        _id(2),
        start,
        start + timedelta(hours=2),
        SCHEDULE,
    )
    assert (booking.starts_at, booking.ends_at) == (start, start + timedelta(hours=2))


def test_book_until_midnight_is_valid() -> None:
    repo = InMemory()

    booking = book(repo, _profile(), _id(2), TOMORROW, time(22, 0), 1, NOW)

    assert booking.ends_at == datetime(2026, 3, 3, 23, 0, tzinfo=ZONE)


def test_book_an_administrator_is_forbidden() -> None:
    with pytest.raises(Forbidden):
        book(InMemory(), _profile(role="admin"), _id(2), TOMORROW, time(18, 0), 1, NOW)


def test_book_without_an_hour_asks_for_an_on_the_hour_time() -> None:
    with pytest.raises(InvalidData) as e:
        book(InMemory(), _profile(), _id(2), TOMORROW, None, 1, NOW)

    assert set(_errors(e)) == {"start_hour"}


@pytest.mark.parametrize("hours", [0, 5, -1])
def test_book_with_a_duration_outside_one_to_four_hours_fails(hours: int) -> None:
    repo = InMemory()

    with pytest.raises(InvalidData) as e:
        book(repo, _profile(), _id(2), TOMORROW, time(18, 0), hours, NOW)

    assert set(_errors(e)) == {"hours", "until"}
    assert repo.calls == []


@pytest.mark.parametrize("hours", [1, 4])
def test_book_accepts_the_duration_edges(hours: int) -> None:
    booking = book(InMemory(), _profile(), _id(2), TOMORROW, time(10, 0), hours, NOW)

    assert booking.ends_at - booking.starts_at == timedelta(hours=hours)


def test_book_a_day_outside_the_window_fails_even_at_date_max() -> None:
    with pytest.raises(InvalidData) as e:
        book(InMemory(), _profile(), _id(2), date.max, time(18, 0), 4, NOW)
    assert set(_errors(e)) == {"date"}

    with pytest.raises(InvalidData):
        book(InMemory(), _profile(), _id(2), NOW.date() + timedelta(days=7), time(18, 0), 1, NOW)


def test_book_the_last_day_of_the_window_is_accepted() -> None:
    day = NOW.date() + timedelta(days=6)

    assert book(InMemory(), _profile(), _id(2), day, time(18, 0), 1, NOW).id == _id(5)


def test_book_returns_the_repeated_request_without_validating_the_time() -> None:
    repo = InMemory()
    repo.repeated_done = _booking(id=_id(99))
    repo.current_schedule = None
    already_started = NOW - timedelta(days=1)

    booking = book(repo, _profile(), _id(2), already_started.date(), time(9, 0), 1, NOW)

    assert booking.id == _id(99)
    assert [c[0] for c in repo.calls] == ["repeated"]


def test_book_a_space_without_a_schedule_is_not_available() -> None:
    repo = InMemory()
    repo.current_schedule = None

    with pytest.raises(Unavailable):
        book(repo, _profile(), _id(2), TOMORROW, time(18, 0), 1, NOW)


def test_book_outside_the_venue_hours_fails_without_saving() -> None:
    repo = InMemory()

    with pytest.raises(InvalidData):
        book(repo, _profile(), _id(2), TOMORROW, time(7, 0), 1, NOW)
    with pytest.raises(InvalidData):
        book(repo, _profile(), _id(2), TOMORROW, time(22, 0), 2, NOW)
    assert [c for c in repo.calls if c[0] == "insert"] == []


def test_book_revalidates_if_the_schedule_changed_in_the_meantime() -> None:
    repo = InMemory()
    repo.schedules_changed = 2

    booking = book(repo, _profile(), _id(2), TOMORROW, time(18, 0), 1, NOW)

    assert booking.id == _id(5)
    assert len([c for c in repo.calls if c[0] == "insert"]) == 3


def test_book_with_an_always_changing_schedule_ends_in_a_taken_slot() -> None:
    repo = InMemory()
    repo.schedules_changed = 99

    with pytest.raises(SlotTaken):
        book(repo, _profile(), _id(2), TOMORROW, time(18, 0), 1, NOW)

    assert len([c for c in repo.calls if c[0] == "insert"]) == 3


# cancel_booking


def test_cancel_booking_cancels_the_one_of_the_requester() -> None:
    repo = InMemory()

    booking = cancel_booking(repo, _profile(id=3), _id(5))

    assert booking.status == "canceled"
    assert repo.calls == [("cancel", _id(3), _id(5))]


def test_cancel_booking_lets_the_repository_errors_through() -> None:
    class Foreign(InMemory):
        def cancel(self, user_id, booking_id):
            raise NotFound("no")

    with pytest.raises(NotFound):
        cancel_booking(Foreign(), _profile(), _id(5))


# modify_booking


def _with_booking() -> InMemory:
    repo = InMemory()
    repo.own_of = _booking()
    return repo


def test_modify_booking_moves_with_the_same_duration_and_the_previous_state() -> None:
    repo = _with_booking()

    new = modify_booking(repo, _profile(), _id(5), _id(3), TOMORROW, time(10, 0), NOW)

    start = datetime(2026, 3, 3, 10, 0, tzinfo=ZONE)
    before = (_id(2), datetime(2026, 3, 3, 18, 0, tzinfo=ZONE))
    assert repo.calls[-1] == (
        "move",
        _id(1),
        _id(5),
        before,
        _id(3),
        start,
        start + timedelta(hours=2),
    )
    assert (new.space_id, new.starts_at) == (_id(3), start)


def test_modify_booking_an_administrator_is_forbidden() -> None:
    with pytest.raises(Forbidden):
        modify_booking(
            _with_booking(), _profile(role="admin"), _id(5), _id(2), TOMORROW, time(9, 0), NOW
        )


def test_modify_booking_without_an_hour_fails() -> None:
    with pytest.raises(InvalidData) as e:
        modify_booking(_with_booking(), _profile(), _id(5), _id(2), TOMORROW, None, NOW)

    assert set(_errors(e)) == {"start_hour"}


def test_modify_booking_outside_the_window_fails_before_looking_it_up() -> None:
    repo = _with_booking()

    with pytest.raises(InvalidData) as e:
        modify_booking(repo, _profile(), _id(5), _id(2), date.max, time(9, 0), NOW)

    assert set(_errors(e)) == {"date"}
    assert repo.calls == []


def test_modify_booking_of_someone_else_is_not_found() -> None:
    with pytest.raises(NotFound):
        modify_booking(InMemory(), _profile(), _id(5), _id(2), TOMORROW, time(9, 0), NOW)


def test_modify_booking_repeated_returns_the_current_one_without_moving() -> None:
    repo = _with_booking()

    booking = modify_booking(repo, _profile(), _id(5), _id(2), TOMORROW, time(18, 0), NOW)

    assert booking == _booking()
    assert [c[0] for c in repo.calls] == ["own"]


def test_modify_booking_canceled_with_the_same_time_is_not_taken_as_repeated() -> None:
    repo = InMemory()
    repo.own_of = _booking(status="canceled")

    modify_booking(repo, _profile(), _id(5), _id(2), TOMORROW, time(18, 0), NOW)

    assert repo.calls[-1][0] == "move"


def test_modify_booking_same_space_other_time_or_other_space_same_time_moves() -> None:
    repo = _with_booking()

    modify_booking(repo, _profile(), _id(5), _id(2), TOMORROW, time(19, 0), NOW)
    assert repo.calls[-1][0] == "move"
    modify_booking(repo, _profile(), _id(5), _id(3), TOMORROW, time(18, 0), NOW)
    assert repo.calls[-1][0] == "move"


@pytest.mark.parametrize(
    "kind", [None, (_id(2), "futbol", "5"), (_id(1), "tenis", "5"), (_id(1), "futbol", "7")]
)
def test_modify_booking_to_a_court_of_another_kind_or_venue_fails(kind) -> None:
    repo = _with_booking()
    repo.kind = kind

    with pytest.raises(InvalidData) as e:
        modify_booking(repo, _profile(), _id(5), _id(3), TOMORROW, time(10, 0), NOW)

    assert set(_errors(e)) == {"space_id"}


def test_modify_booking_validates_the_time_against_the_schedule() -> None:
    with pytest.raises(InvalidData):
        modify_booking(_with_booking(), _profile(), _id(5), _id(3), TOMORROW, time(7, 0), NOW)

    repo = _with_booking()
    repo.current_schedule = None
    with pytest.raises(Unavailable):
        modify_booking(repo, _profile(), _id(5), _id(3), TOMORROW, time(10, 0), NOW)


def test_modify_booking_revalidates_if_the_schedule_changes_and_gives_up_on_the_third() -> None:
    repo = _with_booking()
    repo.schedules_changed = 1
    modify_booking(repo, _profile(), _id(5), _id(3), TOMORROW, time(10, 0), NOW)
    assert len([c for c in repo.calls if c[0] == "move"]) == 2

    repo = _with_booking()
    repo.schedules_changed = 99
    with pytest.raises(SlotTaken):
        modify_booking(repo, _profile(), _id(5), _id(3), TOMORROW, time(10, 0), NOW)
    assert len([c for c in repo.calls if c[0] == "move"]) == 3


def test_modify_booking_of_three_hours_keeps_the_duration() -> None:
    repo = InMemory()
    repo.own_of = _booking(ends_at=datetime(2026, 3, 3, 21, 0, tzinfo=ZONE))

    new = modify_booking(repo, _profile(), _id(5), _id(3), TOMORROW, time(10, 0), NOW)

    assert new.ends_at - new.starts_at == timedelta(hours=3)


# global_history


def test_global_history_is_queried_by_an_administrator_with_their_filters() -> None:
    repo = InMemory()
    filters = HistoryFilters(since=date(2026, 1, 1), until=date(2026, 1, 1), q="ana")

    result = global_history(repo, _profile(role="admin"), filters)

    assert result.total == 0
    assert repo.calls == [("history", filters)]


def test_global_history_a_user_is_forbidden() -> None:
    repo = InMemory()

    with pytest.raises(Forbidden):
        global_history(repo, _profile(), HistoryFilters())
    assert repo.calls == []


def test_global_history_rejects_since_after_until() -> None:
    admin = _profile(role="admin")
    filters = HistoryFilters(since=date(2026, 1, 2), until=date(2026, 1, 1))

    with pytest.raises(InvalidData) as e:
        global_history(InMemory(), admin, filters)

    assert set(_errors(e)) == {"dates"}


def test_global_history_accepts_open_ranges() -> None:
    admin = _profile(role="admin")

    global_history(InMemory(), admin, HistoryFilters(since=date(2026, 1, 2)))
    global_history(InMemory(), admin, HistoryFilters(until=date(2026, 1, 2)))


# admin_detail


def test_admin_detail_returns_the_booking_of_anyone() -> None:
    repo = InMemory()
    repo.detail = _history(user_id=_id(44))

    assert admin_detail(repo, _profile(role="admin"), _id(5)).user_id == _id(44)
    assert repo.calls == [("any_one", _id(5))]


def test_admin_detail_a_user_is_forbidden() -> None:
    repo = InMemory()
    repo.detail = _history()

    with pytest.raises(Forbidden):
        admin_detail(repo, _profile(), _id(5))
    assert repo.calls == []


def test_admin_detail_without_a_booking_is_not_found() -> None:
    with pytest.raises(NotFound):
        admin_detail(InMemory(), _profile(role="admin"), _id(5))


# void_booking


def test_void_booking_saves_the_trimmed_reason_and_who_voids() -> None:
    repo = InMemory()
    start = datetime(2026, 3, 3, 18, 0, tzinfo=ZONE)

    result = void_booking(repo, _profile(id=9, role="admin"), _id(5), "  lluvia  ", _id(2), start)

    assert repo.calls == [("void", _id(9), _id(5), "lluvia", _id(2), start)]
    assert result.reason == "lluvia"


def test_void_booking_a_user_is_forbidden() -> None:
    repo = InMemory()

    with pytest.raises(Forbidden):
        void_booking(repo, _profile(), _id(5), "lluvia", _id(2), NOW)
    assert repo.calls == []


@pytest.mark.parametrize("reason", ["", "   ", "\n\t"])
def test_void_booking_without_a_reason_fails(reason: str) -> None:
    repo = InMemory()

    with pytest.raises(InvalidData) as e:
        void_booking(repo, _profile(role="admin"), _id(5), reason, _id(2), NOW)

    assert set(_errors(e)) == {"reason"}
    assert repo.calls == []


def test_void_booking_accepts_the_maximum_reason_and_rejects_one_more() -> None:
    admin = _profile(role="admin")
    repo = InMemory()

    void_booking(repo, admin, _id(5), "x" * MAX_REASON_LENGTH, _id(2), NOW)
    void_booking(repo, admin, _id(5), " " + "x" * MAX_REASON_LENGTH + " ", _id(2), NOW)
    with pytest.raises(InvalidData) as e:
        void_booking(repo, admin, _id(5), "x" * (MAX_REASON_LENGTH + 1), _id(2), NOW)

    assert set(_errors(e)) == {"reason"}
    assert str(MAX_REASON_LENGTH) in _errors(e)["reason"]
    assert len(repo.calls) == 2


def test_void_booking_lets_through_what_already_changed() -> None:
    class Changed(InMemory):
        def void(self, *a):
            raise ConcurrentChange()

    with pytest.raises(ConcurrentChange):
        void_booking(Changed(), _profile(role="admin"), _id(5), "x", _id(2), NOW)
