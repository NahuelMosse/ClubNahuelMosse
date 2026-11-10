from collections.abc import Sequence
from datetime import UTC, datetime
from uuid import UUID

import pytest

from app.modules.notifications.rules import (
    BookingData,
    Delivery,
    LostNotice,
    Notice,
    Notification,
    Reminder,
    cancellation_message,
)
from app.modules.notifications.use_cases import (
    DeliveryResult,
    PendingNotice,
    dispatch_pending,
)


def _id(number: int) -> UUID:
    return UUID(int=number)


def _booking(start: datetime) -> BookingData:
    return BookingData(
        id=_id(12), sport="Futbol", kind="F5", venue="Sede Ramos Mejía", starts_at=start
    )


class InMemoryRepository:
    def __init__(self, pending: list[PendingNotice], tokens: list[str]) -> None:
        self.pending = pending
        self.tokens = tokens
        self.has_any_device = True
        self.deliveries: dict[UUID, Delivery] = {}
        self.deactivated: list[str] = []
        self.fails_on: UUID | None = None
        self.cannot_mark = False
        self.lost: list[LostNotice] = []
        self.order: list[str] = []

    def fail_stranded(self, user_id: UUID | None) -> list[LostNotice]:
        self.order.append("fail_stranded")
        return self.lost

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
        self.order.append("take_next")
        if not self.pending:
            return None
        next_one = self.pending.pop(0)
        self.deliveries[next_one.notification_id] = "sending"
        return next_one

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        if self.fails_on == user_id:
            raise OSError("la base no contesta")
        return list(self.tokens)

    def has_devices(self, user_id: UUID) -> bool:
        return self.has_any_device

    def mark_delivery(self, notification_id: UUID, delivery: Delivery) -> None:
        if self.cannot_mark:
            raise OSError("la base no contesta")
        self.deliveries[notification_id] = delivery

    def deactivate_tokens(self, tokens: Sequence[str]) -> None:
        self.deactivated.extend(tokens)

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        raise NotImplementedError

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        raise NotImplementedError

    def register_device(self, user_id: UUID, token: str, platform: str, permission: bool) -> bool:
        raise NotImplementedError

    def unregister_device(self, user_id: UUID, token: str) -> None:
        raise NotImplementedError

    def of_user(self, user_id: UUID) -> tuple[list[Notification], int]:
        raise NotImplementedError

    def read(self, user_id: UUID, notification_id: UUID) -> bool:
        raise NotImplementedError

    def read_all(self, user_id: UUID) -> None:
        raise NotImplementedError


class FailingChannel:
    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        raise ConnectionError("el servicio no contesta")


class AcceptingChannel:
    def __init__(self, invalid: tuple[str, ...] = ()) -> None:
        self.invalid = invalid
        self.sent: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.sent.append(notice)
        return DeliveryResult(sent=len(tokens) - len(self.invalid), invalid=self.invalid)


def _pending(number: int) -> PendingNotice:
    return PendingNotice(
        _id(number), _id(3), Notice("Booking cancelled", "body", {"kind": "user_cancellation"})
    )


def test_the_message_names_the_booking_with_the_club_day_and_hour() -> None:
    """the day is abbreviated as in the prototype @assumption:CU-24.3-SUP-05"""
    notice = cancellation_message(_booking(datetime(2026, 11, 11, 23, 0, tzinfo=UTC)))

    assert notice.title == "Booking cancelled"
    assert notice.body == ("Football 5 · Sede Ramos Mejía · Wed 11, 20:00. The slot was freed.")
    assert notice.data == {"kind": "user_cancellation", "booking_id": str(_id(12))}


def test_without_devices_with_permission_the_notice_ends_up_without_permission() -> None:
    repo = InMemoryRepository([_pending(1)], [])
    channel = AcceptingChannel()

    assert dispatch_pending(repo, channel) == 1

    assert repo.deliveries == {_id(1): "no_permission"}
    assert channel.sent == []


def test_without_any_registered_device_the_notice_ends_up_without_channel() -> None:
    repo = InMemoryRepository([_pending(1)], [])
    repo.has_any_device = False

    assert dispatch_pending(repo, AcceptingChannel()) == 1

    assert repo.deliveries == {_id(1): "no_channel"}


def test_a_delivery_that_fails_stays_failed_without_retry_and_does_not_stop_the_dispatch() -> None:
    """the backend does not retry a failed delivery @assumption:CU-24.3-SUP-01"""
    repo = InMemoryRepository([_pending(1), _pending(2)], ["t"])

    assert dispatch_pending(repo, FailingChannel()) == 2

    assert repo.deliveries == {_id(1): "failed", _id(2): "failed"}


def test_a_rejected_token_is_deactivated_and_the_notice_goes_out_as_sent() -> None:
    """an invalid token is deactivated @assumption:CU-24.3-SUP-01"""
    repo = InMemoryRepository([_pending(1)], ["bueno", "viejo"])

    dispatch_pending(repo, AcceptingChannel(invalid=("viejo",)))

    assert repo.deactivated == ["viejo"]
    assert repo.deliveries == {_id(1): "sent"}


def test_a_dispatch_does_not_repeat_what_another_one_already_took() -> None:
    """what was taken stays reserved @assumption:CU-24.3-SUP-04"""
    repo = InMemoryRepository([_pending(1)], ["t"])
    channel = AcceptingChannel()

    assert dispatch_pending(repo, channel) == 1
    assert dispatch_pending(repo, channel) == 0

    assert len(channel.sent) == 1


def test_a_failure_on_the_first_notice_leaves_it_failed_and_does_not_block_the_rest() -> None:
    """the notice in progress becomes failed and the following ones go out
    @assumption:CU-24.3-SUP-04"""
    repo = InMemoryRepository(
        [
            PendingNotice(_id(1), _id(7), Notice("t", "c", {"kind": "user_cancellation"})),
            _pending(2),
            _pending(3),
        ],
        ["t"],
    )
    repo.fails_on = _id(7)
    channel = AcceptingChannel()

    assert dispatch_pending(repo, channel) == 3

    assert repo.deliveries == {_id(1): "failed", _id(2): "sent", _id(3): "sent"}
    assert len(channel.sent) == 2


def test_each_notice_given_as_failed_is_in_the_log_with_its_number_and_its_type(
    caplog: pytest.LogCaptureFixture,
) -> None:
    """the lost notice shows in the log as `notice_not_sent` @REV-03-S5"""
    repo = InMemoryRepository([], ["t"])
    repo.lost = [
        LostNotice(_id(8), "forced_cancellation"),
        LostNotice(_id(9), "reminder"),
    ]

    with caplog.at_level("ERROR"):
        dispatch_pending(repo, AcceptingChannel())

    assert [(r.levelname, r.getMessage()) for r in caplog.records] == [
        ("ERROR", f"notice_not_sent notification_id={_id(8)} kind=forced_cancellation"),
        ("ERROR", f"notice_not_sent notification_id={_id(9)} kind=reminder"),
    ]


def test_the_stranded_ones_are_given_as_failed_before_taking_the_next() -> None:
    repo = InMemoryRepository([_pending(1)], ["t"])

    dispatch_pending(repo, AcceptingChannel())

    assert repo.order[:2] == ["fail_stranded", "take_next"]


def test_what_was_not_attempted_stays_pending_if_the_dispatch_is_cut() -> None:
    """a dispatch that is cut leaves no notices in `enviando` beyond the one in progress"""
    repo = InMemoryRepository([_pending(1), _pending(2)], ["t"])
    repo.fails_on = _id(3)
    repo.cannot_mark = True

    with pytest.raises(OSError):
        dispatch_pending(repo, AcceptingChannel())

    assert [p.notification_id for p in repo.pending] == [_id(2)]
