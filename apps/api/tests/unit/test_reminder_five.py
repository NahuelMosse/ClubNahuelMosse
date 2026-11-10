from collections.abc import Sequence
from datetime import UTC, datetime, timedelta
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import (
    FIVE_MINUTE_LEAD_TIME,
    Notice,
    Recipient,
    Reminder,
    reminder_message,
)
from app.modules.notifications.use_cases import DeliveryResult, send_reminders
from app.shared.message import Message

NOW = datetime(2026, 10, 1, 23, 56, tzinfo=UTC)
START = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)


def _five() -> Reminder:
    return Reminder(
        UUID(int=7),
        UUID(int=3),
        START,
        START + timedelta(hours=1),
        "Futbol",
        "F5",
        "Sede Morón",
        email="ana@correo.com",
        name="Ana",
        reminder_kind="five_minute_reminder",
    )


class _Repository:
    def __init__(self) -> None:
        self.registered: list[Reminder] = []
        self.deliveries: list[str] = []

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        return [_five(), _five()]

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        if self.registered:
            return None
        self.registered.append(reminder)
        return UUID(int=50)

    def recipient(self, user_id: UUID) -> Recipient | None:
        return None

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        return ["token"]

    def mark_delivery(self, notification_id: UUID, delivery: str) -> None:
        self.deliveries.append(delivery)

    def deactivate_tokens(self, tokens: Sequence[str]) -> None: ...


class _Channel:
    def __init__(self) -> None:
        self.notices: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.notices.append(notice)
        return DeliveryResult(sent=len(tokens))


def test_five_minutes_before_the_booking_one_notice_goes_out_by_push_and_by_email_only_once(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """five minutes before the booking one notice goes out by push and email, once @NOT-05-S1"""
    emails: list[Message] = []
    monkeypatch.setattr(use_cases, "send", emails.append)
    repo, channel = _Repository(), _Channel()

    registered = send_reminders(cast(Any, repo), channel, NOW)

    assert registered == 1
    assert [a.title for a in channel.notices] == ["Your booking starts in 5 minutes"]
    assert channel.notices[0].body == "Football 5 · Sede Morón · 21:00 – 22:00"
    assert channel.notices[0].data == {
        "kind": "five_minute_reminder",
        "booking_id": str(UUID(int=7)),
    }
    assert [c.subject for c in emails] == ["Your booking starts in 5 minutes"]
    assert repo.deliveries == ["sent"]
    assert FIVE_MINUTE_LEAD_TIME == timedelta(minutes=5)


def test_the_one_hour_notice_stays_the_same() -> None:
    one_hour = Reminder(UUID(int=7), UUID(int=3), START, START, "Futbol", "F5", "Sede")
    assert reminder_message(one_hour).title == "Your booking is in 1 hour"
