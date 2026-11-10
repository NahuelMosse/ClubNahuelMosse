import logging
from collections.abc import Sequence
from datetime import UTC, datetime
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import Notice, Recipient, Reminder
from app.modules.notifications.use_cases import DeliveryResult, deliver, send_reminders
from app.shared.config import config
from app.shared.message import Message

ADDRESS = "ana@correo.com"
USER = UUID(int=7)
NOTICE = Notice(
    title="El club canceló tu reserva",
    body="Football 5 · Sede Morón · Wed 11, 20:00",
    data={"kind": "forced_cancellation"},
)


class _Repository:
    def __init__(self, tokens: list[str], devices: bool = False, is_new: bool = True) -> None:
        self.tokens = tokens
        self.devices = devices
        self.is_new = is_new
        self.deliveries: list[str] = []

    def recipient(self, user_id: UUID) -> Recipient | None:
        return Recipient(email=ADDRESS, name="Ana")

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        return self.tokens

    def has_devices(self, user_id: UUID) -> bool:
        return self.devices

    def mark_delivery(self, notification_id: UUID, delivery: str) -> None:
        self.deliveries.append(delivery)

    def deactivate_tokens(self, tokens: Sequence[str]) -> None: ...

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        start = datetime(2026, 10, 1, 21, 0, tzinfo=UTC)
        return [
            Reminder(
                booking_id=UUID(int=3),
                user_id=USER,
                starts_at=start,
                ends_at=start.replace(hour=22),
                sport="Futbol",
                kind="F5",
                venue="Sede Morón",
                email=ADDRESS,
                name="Ana",
            )
        ]

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        return UUID(int=50) if self.is_new else None


class _Channel:
    """A channel that accepts every token and keeps what it was sent."""

    def __init__(self) -> None:
        self.notices: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.notices += [notice]
        return DeliveryResult(sent=len(tokens))


def _deliver(repo: _Repository, channel: _Channel) -> None:
    deliver(cast(Any, repo), channel, UUID(int=1), USER, NOTICE)


def test_each_registered_notification_also_goes_out_by_email_with_title_body_and_template(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """each registered notification also goes out by email with its title, body and the template
    @MAIL-03-S1 @assumption:MAIL-03-ASM-02"""
    sent: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent.append)
    monkeypatch.setattr(config, "public_url", "https://club.example")
    channel = _Channel()

    _deliver(_Repository(["token"]), channel)

    assert len(channel.notices) == 1
    assert len(sent) == 1
    assert sent[0].recipient == ADDRESS
    assert sent[0].subject == NOTICE.title
    assert sent[0].html is not None
    for text in (NOTICE.title, "Football 5", "Open the app", 'href="https://club.example"'):
        assert text in sent[0].html
    assert NOTICE.body in sent[0].body

    sent.clear()
    monkeypatch.setattr(config, "public_url", "")
    _deliver(_Repository(["token"]), channel)
    assert sent[0].html is not None
    assert "Open the app" not in sent[0].html


def test_the_email_goes_out_even_without_push_and_if_it_fails_the_notice_stays_as_it_was(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """the email goes out even without push and if it fails the notice stays as it was
    @MAIL-03-S2"""
    sent: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent.append)
    repo = _Repository([])
    _deliver(repo, _Channel())
    assert len(sent) == 1
    assert repo.deliveries == ["no_channel"]

    def broken(message: Message) -> None:
        raise RuntimeError(f"could not send to {message.recipient}")

    monkeypatch.setattr(use_cases, "send", broken)
    repo, channel = _Repository(["token"]), _Channel()
    with caplog.at_level(logging.WARNING):
        _deliver(repo, channel)
    assert repo.deliveries == ["sent"]
    assert len(channel.notices) == 1
    assert "RuntimeError" in caplog.text
    assert ADDRESS not in caplog.text


def test_the_reminder_sends_a_single_email(monkeypatch: pytest.MonkeyPatch) -> None:
    """the reminder sends a single email
    @assumption:MAIL-03-ASM-01"""
    sent: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent.append)

    registered = send_reminders(
        cast(Any, _Repository(["token"])), _Channel(), datetime(2026, 10, 1, 20, 30, tzinfo=UTC)
    )

    assert registered == 1
    assert len(sent) == 1
    assert sent[0].subject == "Your booking is in 1 hour"


def test_a_notice_that_is_not_registered_sends_no_email(monkeypatch: pytest.MonkeyPatch) -> None:
    """a notice that is not registered sends no email
    @assumption:MAIL-03-ASM-03"""
    sent: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent.append)

    registered = send_reminders(
        cast(Any, _Repository(["token"], is_new=False)),
        _Channel(),
        datetime(2026, 10, 1, 20, 30, tzinfo=UTC),
    )

    assert registered == 0
    assert sent == []
