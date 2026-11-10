import json
import logging
from collections.abc import Sequence
from contextlib import contextmanager
from datetime import UTC, date, datetime, timedelta
from typing import Any, cast
from uuid import UUID

import pytest
from fastapi import BackgroundTasks

from app.modules.bookings import routes
from app.modules.bookings.rules import Booking
from app.modules.notifications.rules import Notice, Reminder
from app.modules.notifications.use_cases import DeliveryResult, send_reminders
from app.modules.password_recovery.rules import Message, Recipient
from app.modules.password_recovery.use_cases import request_link
from app.modules.session import Profile
from app.shared import email
from app.shared.config import config
from app.shared.email_template import html_email

BASE_LINK = "https://club.example"
ADDRESS = "ana@correo.com"


def _id(number: int) -> UUID:
    return UUID(int=number)


class _Links:
    def __init__(self, name: str = "Ana") -> None:
        self.name = name

    def recipient(self, email: str) -> Recipient:
        return Recipient(_id(1), self.name, ADDRESS)

    def issue(
        self, user_id: UUID, code_hash: str, validity_minutes: int, max_per_hour: int
    ) -> bool:
        return True


def _recovery(name: str = "Ana") -> Message:
    message = request_link(ADDRESS, BASE_LINK, cast(Any, _Links(name)))
    assert message is not None
    return message


def test_the_recovery_email_goes_out_in_html_with_the_template_the_greeting_the_link_button_and_the_expiry() -> (
    None
):
    """the recovery email goes out in HTML with the template, the greeting, the link button and the expiry
    @MAIL-02-S1 @assumption:MAIL-02-ASM-03"""
    html = _recovery().html

    assert html is not None
    for mark in ("#0A0A0B", "#141416", "#D4FF3D", "#A1A1AA", "CLUB NAHUEL MOSSE", "<table"):
        assert mark in html
    assert "<script" not in html
    assert "<img" not in html
    assert "Hi Ana" in html
    assert "Create new password" in html
    assert f'href="{BASE_LINK}/link/recover#code=' in html
    assert "30 minutes" in html
    assert "only once" in html
    assert "ignore this email" in html


def _booking(**changes: Any) -> Booking:
    starts_at = datetime(2026, 10, 28, 23, 0, tzinfo=UTC)  # 20:00 at the club
    data: dict[str, Any] = {
        "id": _id(9),
        "space_id": _id(2),
        "venue_id": _id(3),
        "space": "Cancha 1",
        "sport": "Futbol",
        "kind": "F5",
        "venue": "Sede Morón",
        "address": "Calle 1",
        "starts_at": starts_at,
        "ends_at": starts_at + timedelta(hours=1),
        "price_per_hour": 12000,
        "total": 12000,
        "status": "active",
        "reason": None,
        "cancelable": True,
    }
    return Booking(**(data | changes))


def _profile(name: str = "Ana") -> Profile:
    return Profile(_id(1), "uid", name, "Pérez", ADDRESS, "user", "30111222", date(1990, 1, 1))


def _reminder(venue: str = "Sede Morón") -> Reminder:
    starts_at = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)
    return Reminder(
        _id(7),
        _id(1),
        starts_at,
        starts_at + timedelta(hours=1),
        "Futbol",
        "F5",
        venue,
        ADDRESS,
        "Ana",
    )


def test_each_email_still_carries_its_text_and_the_html_repeats_the_button_link() -> None:
    """each email still carries its text and the HTML repeats the button link
    @MAIL-02-S2"""
    recovery = _recovery()
    link = recovery.body.split("\n")[3]
    assert link.startswith(BASE_LINK)
    assert recovery.html is not None
    assert recovery.html.count(link) >= 2
    assert "Create new password" not in recovery.body or link in recovery.body

    sent: list[Message] = []
    patch = pytest.MonkeyPatch()
    try:
        patch.setattr(routes, "send", sent.append)
        tasks = BackgroundTasks()
        patch.setattr(routes, "book", lambda *a, **k: _booking())
        routes.create_booking(
            routes.BookingRequest(
                space_id=cast(Any, _id(2)), date=date(2026, 10, 28), start_hour="20:00", hours=1
            ),
            _profile(),
            cast(Any, None),
            tasks,
        )
        _run(tasks)
    finally:
        patch.undo()
    from app.modules.notifications.rules import reminder_email

    for message in (*sent, reminder_email(_reminder())):
        assert message.body.strip()
        assert message.html is not None


def _run(tasks: BackgroundTasks) -> None:
    for task in tasks.tasks:
        task.func(*task.args, **task.kwargs)


def test_brevo_gets_htmlcontent_only_if_there_is_html_smtp_the_alternative_and_the_outbox_only_the_text(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Brevo gets htmlContent only if there is HTML, SMTP the alternative and the outbox only the text
    @assumption:MAIL-02-ASM-01"""
    requests: list[dict[str, Any]] = []

    def fake_urlopen(request: Any, timeout: int) -> Any:
        requests.append(json.loads(request.data))

        @contextmanager
        def response() -> Any:
            yield None

        return response()

    monkeypatch.setattr("urllib.request.urlopen", fake_urlopen)
    monkeypatch.setattr(config, "brevo_api_key", "key")
    monkeypatch.setattr(config, "email_sender", "club@correo.com")
    email._by_brevo(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    email._by_brevo(Message(ADDRESS, "Asunto", "texto"))
    assert requests[0]["htmlContent"] == "<p>hola</p>"
    assert requests[0]["textContent"] == "texto"
    assert "htmlContent" not in requests[1]

    sent: list[Any] = []

    class FakeSmtp:
        def __init__(self, *a: Any, **k: Any) -> None: ...
        def __enter__(self) -> "FakeSmtp":
            return self

        def __exit__(self, *a: Any) -> None: ...
        def starttls(self, **k: Any) -> None: ...
        def login(self, *a: Any) -> None: ...
        def send_message(self, message: Any) -> None:
            sent.append(message)

    monkeypatch.setattr("smtplib.SMTP", FakeSmtp)
    monkeypatch.setattr(config, "smtp_host", "smtp.example")
    email._by_smtp(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    email._by_smtp(Message(ADDRESS, "Asunto", "texto"))
    assert sent[0].get_body(("html",)).get_content().strip() == "<p>hola</p>"
    assert sent[1].get_body(("html",)) is None

    saved: list[dict[str, Any]] = []

    class FakeConnection:
        def execute(self, sql: Any, params: dict[str, Any]) -> None:
            saved.append(params)

    class FakeEngine:
        @contextmanager
        def begin(self) -> Any:
            yield FakeConnection()

    monkeypatch.setattr(email, "engine", lambda: FakeEngine())
    email._to_outbox(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    assert saved == [{"recipient": ADDRESS, "subject": "Asunto", "body": "texto"}]


def test_a_name_or_a_venue_with_markup_goes_out_escaped_in_the_html() -> None:
    """a name or a venue with markup goes out escaped in the HTML
    @assumption:MAIL-02-ASM-02"""
    from app.modules.bookings.email import booking_email
    from app.modules.notifications.rules import reminder_email

    bad = "<b>x</b> & <script>"
    htmls = [
        _recovery(bad).html,
        booking_email(_profile(bad), _booking(venue=bad)).html,
        reminder_email(_reminder(bad)).html,
        html_email(bad, [bad], ("Ir", "https://x.test/?a=1&b=2"), bad),
    ]
    for html in htmls:
        assert html is not None
        assert "<b>x</b>" not in html
        assert "<script>" not in html
        assert "&lt;b&gt;x&lt;/b&gt;" in html or "&amp;" in html
    assert "a=1&amp;b=2" in str(htmls[3])


def test_making_a_booking_sends_the_confirmation_email_with_sport_venue_day_time_and_total(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """making a booking sends the confirmation email with sport, venue, day, time and total
    @MAIL-02-S3"""
    sent: list[Message] = []
    monkeypatch.setattr(routes, "send", sent.append)
    monkeypatch.setattr(routes, "book", lambda *a, **k: _booking())
    tasks = BackgroundTasks()
    response = routes.create_booking(
        routes.BookingRequest(
            space_id=cast(Any, _id(2)), date=date(2026, 10, 28), start_hour="20:00", hours=1
        ),
        _profile(),
        cast(Any, None),
        tasks,
    )
    assert not isinstance(response, type(None))
    assert sent == []  # it goes out after responding

    _run(tasks)

    assert len(sent) == 1
    message = sent[0]
    assert message.recipient == ADDRESS
    assert message.subject == "Your booking is confirmed"
    for item in ("Football 5", "Sede Morón", "Wednesday October 28", "20:00", "21:00", "12.000"):
        assert item in message.body
        assert message.html is not None
        assert item in message.html


def test_if_the_confirmation_email_fails_the_booking_answers_the_same_and_the_log_has_no_address(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """if the confirmation email fails the booking answers the same and the log has no address
    @assumption:MAIL-02-ASM-04"""
    monkeypatch.setattr(config, "email_mode", "brevo")

    def broken(*a: Any, **k: Any) -> None:
        raise ConnectionError(f"sin red hacia {ADDRESS}")

    monkeypatch.setattr("urllib.request.urlopen", broken)
    monkeypatch.setattr(routes, "book", lambda *a, **k: _booking())
    tasks = BackgroundTasks()
    response = routes.create_booking(
        routes.BookingRequest(
            space_id=cast(Any, _id(2)), date=date(2026, 10, 28), start_hour="20:00", hours=1
        ),
        _profile(),
        cast(Any, None),
        tasks,
    )
    assert getattr(response, "id", None) == _id(9)

    with caplog.at_level(logging.ERROR, logger="clubnahuelmosse.correo"):
        _run(tasks)

    assert "Your booking is confirmed" in caplog.text
    assert "ConnectionError" in caplog.text
    assert ADDRESS not in caplog.text


def test_modifying_canceling_or_voiding_send_no_email(monkeypatch: pytest.MonkeyPatch) -> None:
    """modifying, canceling or voiding send no email
    @assumption:MAIL-02-ASM-05"""
    sent: list[Message] = []
    monkeypatch.setattr(routes, "send", sent.append)
    monkeypatch.setattr(routes, "dispatch_for", lambda *a: None)
    monkeypatch.setattr(routes, "cancel_booking", lambda *a: _booking(status="canceled"))
    monkeypatch.setattr(routes, "modify_booking", lambda *a: _booking())
    tasks = BackgroundTasks()
    routes.cancel(_profile(), cast(Any, None), _id(9), tasks, cast(Any, None))
    routes.modify(
        routes.BookingChangeRequest(
            space_id=cast(Any, _id(2)), date=date(2026, 10, 28), start_hour="20:00"
        ),
        _profile(),
        cast(Any, None),
        _id(9),
    )
    _run(tasks)
    assert sent == []


class _Repository:
    def __init__(self) -> None:
        self.registered: set[UUID] = set()

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        return [_reminder()]

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        if reminder.booking_id in self.registered:
            return None
        self.registered.add(reminder.booking_id)
        return _id(50)

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        return ["token"]

    def mark_delivery(self, notification_id: UUID, delivery: str) -> None: ...

    def deactivate_tokens(self, tokens: Sequence[str]) -> None: ...


class _Channel:
    def __init__(self) -> None:
        self.notices: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.notices.append(notice)
        return DeliveryResult(sent=1)


def test_the_reminder_one_hour_before_goes_out_by_push_and_by_email_only_once(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the reminder one hour before goes out by push and by email, only once
    @MAIL-02-S4"""
    from app.modules.notifications import use_cases

    sent: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent.append)
    repo, channel = _Repository(), _Channel()
    now = datetime(2026, 10, 1, 23, 0, tzinfo=UTC)

    assert send_reminders(cast(Any, repo), channel, now) == 1
    assert send_reminders(cast(Any, repo), channel, now) == 0

    assert len(channel.notices) == 1
    assert len(sent) == 1
    assert sent[0].recipient == ADDRESS
    assert sent[0].subject == "Your booking is in 1 hour"
    assert sent[0].html is not None
    for item in ("Football 5", "Sede Morón", "21:00", "22:00"):
        assert item in sent[0].body
        assert item in sent[0].html


def test_if_the_reminder_email_fails_the_push_goes_out_anyway(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """if the reminder email fails the push goes out anyway
    @assumption:MAIL-02-ASM-04"""
    from app.modules.notifications import use_cases

    def broken(message: Message) -> None:
        raise RuntimeError(f"no se pudo enviar a {message.recipient}")

    monkeypatch.setattr(use_cases, "send", broken)
    channel = _Channel()
    with caplog.at_level(logging.WARNING):
        registered = send_reminders(
            cast(Any, _Repository()), channel, datetime(2026, 10, 1, 23, 0, tzinfo=UTC)
        )

    assert registered == 1
    assert len(channel.notices) == 1
    assert "RuntimeError" in caplog.text
    assert ADDRESS not in caplog.text
