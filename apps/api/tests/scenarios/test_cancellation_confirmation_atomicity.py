"""The cancellation and its confirmation are committed together or not at all."""

from collections.abc import Callable, Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, app_of, a_member

from app.modules.notifications.push import push_channel


@pytest.fixture
def channel(api: TestClient) -> Iterator[FakeChannel]:
    channel = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: channel
    yield channel
    app_of(api).dependency_overrides.pop(push_channel, None)


@pytest.fixture
def failing_notice(engine: Engine) -> Iterator[None]:
    """Makes the confirmation INSERT fail, which runs after the booking UPDATE."""
    with engine.begin() as conn:
        conn.execute(
            text(
                "CREATE FUNCTION falla_la_confirmacion() RETURNS trigger LANGUAGE plpgsql AS"
                " $$ BEGIN RAISE EXCEPTION 'falla el aviso'; END $$"
            )
        )
        conn.execute(
            text(
                "CREATE TRIGGER falla_la_confirmacion BEFORE INSERT ON notification"
                " FOR EACH ROW WHEN (NEW.kind = 'user_cancellation')"
                " EXECUTE FUNCTION falla_la_confirmacion()"
            )
        )
    yield
    with engine.begin() as conn:
        conn.execute(text("DROP TRIGGER falla_la_confirmacion ON notification"))
        conn.execute(text("DROP FUNCTION falla_la_confirmacion()"))


def test_if_the_notice_fails_the_booking_stays_active_and_no_notice_is_left(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    failing_notice: None,
) -> None:
    """a cancellation whose notice is not recorded is not confirmed @assumption:CU-24.3-SUP-04"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")

    try:
        response = api.post(f"/bookings/{booking['id']}/cancel", headers=member.session)
        assert response.status_code >= 500
    except Exception as e:
        # The test client propagates the server error instead of answering 500.
        assert "falla el aviso" in str(e)

    with engine.connect() as conn:
        status: Any = conn.execute(
            text("SELECT status FROM booking WHERE id = :id"), {"id": booking["id"]}
        ).scalar_one()
        notices: Any = conn.execute(
            text("SELECT count(*) FROM notification WHERE user_id = :u"),
            {"u": member.user_id},
        ).scalar_one()
    assert (status, notices) == ("active", 0)
    assert channel.sent == []
