from collections.abc import Sequence
from datetime import UTC, datetime, timedelta
from uuid import UUID

import pytest

from app.modules.notifications import push
from app.modules.notifications.rules import (
    Delivery,
    Notice,
    Notification,
    Reminder,
    reminder_message,
    short_kind,
)
from app.modules.notifications.use_cases import (
    ChannelNotConfigured,
    DeliveryResult,
    PendingNotice,
    send_reminders,
)

NOW = datetime(2026, 10, 1, 23, 0, tzinfo=UTC)


def _id(number: int) -> UUID:
    return UUID(int=number)


def _reminder(sport: str = "Futbol", kind: str = "F5", booking_id: int = 7) -> Reminder:
    # 21:00 – 22:00 in the club's time (UTC−3).
    start = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)
    return Reminder(
        _id(booking_id), _id(3), start, start + timedelta(hours=1), sport, kind, "Sede Morón"
    )


class InMemoryRepository:
    def __init__(self, pending: list[Reminder], tokens: list[str]) -> None:
        self.pending = pending
        self.tokens = tokens
        self.has_any_device = True
        self.registered: dict[UUID, Reminder] = {}
        self.deliveries: dict[UUID, Delivery] = {}
        self.deactivated: list[str] = []

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        return list(self.pending)

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        if any(r.booking_id == reminder.booking_id for r in self.registered.values()):
            return None
        new_id = _id(len(self.registered) + 1)
        self.registered[new_id] = reminder
        return new_id

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        return list(self.tokens)

    def has_devices(self, user_id: UUID) -> bool:
        return self.has_any_device

    def mark_delivery(self, notification_id: UUID, delivery: Delivery) -> None:
        self.deliveries[notification_id] = delivery

    def deactivate_tokens(self, tokens: Sequence[str]) -> None:
        self.deactivated.extend(tokens)

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
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
        raise ConnectionError("the service does not answer")


class RejectingChannel:
    def __init__(self, invalid_tokens: tuple[str, ...], sent: int) -> None:
        self.invalid_tokens = invalid_tokens
        self.sent = sent

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        return DeliveryResult(sent=self.sent, invalid=self.invalid_tokens)


def test_the_message_carries_sport_venue_and_the_clubs_schedule() -> None:
    notice = reminder_message(_reminder())

    assert notice.title == "Your booking is in 1 hour"
    assert notice.body == "Football 5 · Sede Morón · 21:00 – 22:00"
    assert notice.data == {"kind": "reminder", "booking_id": str(_id(7))}


@pytest.mark.parametrize(
    ("sport", "kind", "expected"),
    [
        ("Futbol", "F11", "Football 11"),
        ("Tenis", "PDL", "Tennis"),
        ("Hockey", "H7", "Hockey 7"),
        ("Padel", "PAD", "Padel"),
        ("Rugby", "R15", "Rugby"),
    ],
)
def test_the_sport_is_named_with_the_short_kind(sport: str, kind: str, expected: str) -> None:
    """the notice names the sport with the catalog's short kind @assumption:CU-24.1-SUP-14"""
    assert short_kind(sport, kind) == expected


def test_a_delivery_that_fails_is_marked_failed_without_retry_and_does_not_stop_the_sweep() -> None:
    """the backend does not retry a failed delivery @assumption:CU-24.1-SUP-02"""
    repo = InMemoryRepository([_reminder(booking_id=1), _reminder(booking_id=2)], ["t"])

    registered = send_reminders(repo, FailingChannel(), NOW)

    assert registered == 2
    assert repo.deliveries == {_id(1): "failed", _id(2): "failed"}


def test_a_token_that_the_service_rejects_is_deactivated() -> None:
    """an invalid token is deactivated @assumption:CU-24.1-SUP-02"""
    repo = InMemoryRepository([_reminder()], ["bueno", "viejo"])

    send_reminders(repo, RejectingChannel(("viejo",), sent=1), NOW)

    assert repo.deactivated == ["viejo"]
    assert repo.deliveries == {_id(1): "sent"}


def test_if_the_service_accepts_no_device_the_delivery_is_failed() -> None:
    repo = InMemoryRepository([_reminder()], ["viejo"])

    send_reminders(repo, RejectingChannel(("viejo",), sent=0), NOW)

    assert repo.deliveries == {_id(1): "failed"}


def test_without_devices_with_permission_the_notice_ends_up_without_permission() -> None:
    repo = InMemoryRepository([_reminder()], [])

    assert send_reminders(repo, FailingChannel(), NOW) == 1
    assert repo.deliveries == {_id(1): "no_permission"}


def test_without_any_registered_device_the_notice_ends_up_without_channel() -> None:
    repo = InMemoryRepository([_reminder()], [])
    repo.has_any_device = False

    assert send_reminders(repo, FailingChannel(), NOW) == 1
    assert repo.deliveries == {_id(1): "no_channel"}


def test_a_notice_that_another_sweep_already_registered_is_not_sent_again() -> None:
    repo = InMemoryRepository([_reminder()], ["t"])
    repo.register(_reminder(), reminder_message(_reminder()))

    assert send_reminders(repo, FailingChannel(), NOW) == 0
    assert repo.deliveries == {}


def test_without_firebase_credentials_the_channel_reaches_no_network(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the real push sits behind a port that does not send by default @assumption:CU-24.1-SUP-06"""
    monkeypatch.delenv("GOOGLE_APPLICATION_CREDENTIALS", raising=False)
    push.push_channel.cache_clear()

    channel = push.push_channel()

    assert isinstance(channel, push.NullChannel)
    with pytest.raises(ChannelNotConfigured):
        channel.send(["t"], reminder_message(_reminder()))
    push.push_channel.cache_clear()


def test_without_a_configured_channel_the_notice_is_not_shown_as_sent() -> None:
    repo = InMemoryRepository([_reminder()], ["t"])

    assert send_reminders(repo, push.NullChannel(), NOW) == 1
    assert repo.deliveries == {_id(1): "no_channel"}
