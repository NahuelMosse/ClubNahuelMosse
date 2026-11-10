"""The 5-minute notice against the real database."""

from collections.abc import Sequence
from datetime import datetime, timedelta
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from sqlalchemy.exc import IntegrityError

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import Notice
from app.modules.notifications.use_cases import (
    DeliveryResult,
    dispatch_pending,
    send_reminders,
)
from tests.integration.test_notifications_api import (
    _book,
    _me,
    _register,
    _space,
    _tomorrow_at,
)


class _Channel:
    def __init__(self) -> None:
        self.notices: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.notices.append(notice)
        return DeliveryResult(sent=len(tokens))


def _sweep(engine: Engine, user: UUID, channel: _Channel, now: datetime) -> int:
    with engine.connect() as conn:
        return send_reminders(NotificationsSql(conn), channel, now, user)


def _five(engine: Engine, user: UUID) -> list[tuple[str, str]]:
    with engine.connect() as conn:
        rows = conn.execute(
            text(
                "SELECT title, delivery FROM notification WHERE user_id = :u"
                " AND kind = 'five_minute_reminder'"
            ),
            {"u": user},
        ).all()
    return [(f.title, f.delivery) for f in rows]


def _setup(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> tuple[UUID, UUID, datetime]:
    assert _register(api, user_token, f"fcm-{venue[0]}") == 204
    space = _space(api, admin_token, venue[0])
    booking = _book(api, user_token, space)
    return _me(api, engine, user_token), UUID(booking["id"]), _tomorrow_at(21)


def test_the_database_accepts_the_five_reminder_kind_and_does_not_allow_two_for_the_same_booking_and_slot(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """the database accepts the five reminder kind and does not allow two for the same booking and slot @assumption:NOT-05-ASM-01"""
    user, booking, start = _setup(api, engine, admin_token, user_token, venue)
    insert = text(
        "INSERT INTO notification (user_id, kind, title, body, booking_id, booking_starts_at,"
        " delivery) VALUES (:u, :t, 'x', 'y', :r, :i, 'pending')"
    )
    data = {"u": user, "t": "five_minute_reminder", "r": booking, "i": start}
    with engine.begin() as conn:
        conn.execute(insert, data)
        conn.execute(insert, data | {"t": "reminder"})
    with pytest.raises(IntegrityError), engine.begin() as conn:
        conn.execute(insert, data)
    with pytest.raises(IntegrityError), engine.begin() as conn:
        conn.execute(insert, data | {"r": None})


def test_a_5_minute_notice_of_a_booking_cancelled_before_dispatching_it_does_not_go_out_and_stays_failed(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """a 5-minute notice of a booking cancelled before dispatching it does not go out and stays failed @assumption:NOT-05-ASM-03"""
    user, booking, start = _setup(api, engine, admin_token, user_token, venue)
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notification (user_id, kind, title, body, booking_id,"
                " booking_starts_at, delivery, created_at) VALUES (:u, 'five_minute_reminder', 'x', 'y',"
                " :r, :i, 'pending', now() - interval '5 minutes')"
            ),
            {"u": user, "r": booking, "i": start},
        )
        conn.execute(text("UPDATE booking SET status = 'canceled' WHERE id = :r"), {"r": booking})
    channel = _Channel()
    with engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), channel, user)
    assert channel.notices == []
    assert [e for _, e in _five(engine, user)] == ["failed"]


def test_a_booking_that_already_started_or_made_within_5_minutes_gets_no_5_minute_notice(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """a booking that already started, or made within 5 minutes, gets no 5-minute notice @assumption:NOT-05-ASM-02"""
    user, booking, start = _setup(api, engine, admin_token, user_token, venue)
    channel = _Channel()
    assert _sweep(engine, user, channel, start + timedelta(minutes=1)) == 0
    with engine.begin() as conn:
        # The audit trigger overwrites the dates: it is switched off only to fake the late booking.
        conn.execute(text("ALTER TABLE booking DISABLE TRIGGER booking_updated"))
        conn.execute(
            text("UPDATE booking SET created_at = :c, updated_at = :c WHERE id = :r"),
            {"c": start - timedelta(minutes=2), "r": booking},
        )
        conn.execute(text("ALTER TABLE booking ENABLE TRIGGER booking_updated"))
    assert _sweep(engine, user, channel, start - timedelta(minutes=1)) == 0
    assert _five(engine, user) == []
    with engine.begin() as conn:
        conn.execute(text("ALTER TABLE booking DISABLE TRIGGER booking_updated"))
        conn.execute(
            text("UPDATE booking SET created_at = now(), updated_at = now() WHERE id = :r"),
            {"r": booking},
        )
        conn.execute(text("ALTER TABLE booking ENABLE TRIGGER booking_updated"))
    # With time to spare both notices go out, the one-hour and the 5-minute, and neither repeats.
    assert _sweep(engine, user, channel, start - timedelta(minutes=4)) == 2
    assert _sweep(engine, user, channel, start - timedelta(minutes=3)) == 0
    assert [t for t, _ in _five(engine, user)] == ["Your booking starts in 5 minutes"]
