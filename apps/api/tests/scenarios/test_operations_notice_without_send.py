"""A notice that was not sent stays visible to whoever operates."""

import logging
from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


class _FailingChannel:
    def send(self, tokens: list[str], notice: object) -> object:
        raise ConnectionError("FCM does not answer")


def test_a_notice_that_was_not_sent_is_left_visible(
    api: TestClient,
    engine: Engine,
    unique: Callable[[], str],
    caplog: pytest.LogCaptureFixture,
) -> None:
    """a reminder that was not sent stays visible to whoever operates @REV-02-S4"""
    from app.modules.notifications.use_cases import dispatch_pending
    from app.modules.notifications.repository import NotificationsSql

    s = unique()
    api.post(
        "/register",
        json={
            "first_name": "Martín",
            "last_name": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1994-07-21",
            "email": f"socio.{s}@correo.com",
            "password": "ClubNahuel1",
        },
    )
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notification (user_id, kind, title, body, delivery)"
                " SELECT id, 'forced_cancellation', 'Cancelaron tu reserva', 'Fútbol 5',"
                " 'pending' FROM app_user WHERE email = :c AND active"
            ),
            {"c": f"socio.{s}@correo.com"},
        )
        conn.execute(
            text(
                "INSERT INTO device (user_id, token, platform, permission_granted)"
                " SELECT user_id, 'fcm-' || id, 'android', true FROM notification"
                " WHERE delivery = 'pending' ON CONFLICT DO NOTHING"
            )
        )

    with caplog.at_level(logging.INFO), engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), _FailingChannel())

    errors = [r for r in caplog.records if r.levelno >= logging.ERROR]
    assert any("notice_not_sent" in r.getMessage() for r in errors)
    assert not any("fcm-" in r.getMessage() for r in caplog.records)
