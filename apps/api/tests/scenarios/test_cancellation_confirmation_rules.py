"""The cancellation confirmation rules that no scenario of the card exercises."""

from collections.abc import Callable, Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, app_of, a_member

from app.modules.notifications.use_cases import dispatch_pending
from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.push import push_channel


class DownChannel:
    def send(self, tokens: list[str], aviso: Any) -> Any:
        raise ConnectionError("el servicio no contesta")


@pytest.fixture
def channel(api: TestClient) -> Iterator[FakeChannel]:
    channel = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: channel
    yield channel
    app_of(api).dependency_overrides.pop(push_channel, None)


def _cancel(member: Member, booking_id: str) -> int:
    return member.api.post(f"/bookings/{booking_id}/cancel", headers=member.session).status_code


def _deliveries(member: Member) -> list[str]:
    with member.engine.connect() as conn:
        return [
            f.delivery
            for f in conn.execute(
                text("SELECT delivery FROM notification WHERE user_id = :u ORDER BY id"),
                {"u": member.user_id},
            )
        ]


def test_repeating_the_cancellation_does_not_repeat_the_confirmation(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """a retry of the cancellation does not duplicate the notice @assumption:CU-24.3-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")

    assert _cancel(member, booking["id"]) == 200
    assert _cancel(member, booking["id"]) == 200

    assert len(channel.sent) == 1
    assert len(member.center()["notifications"]) == 1


def test_each_cancelled_booking_has_its_confirmation(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """several cancellations in a row give one confirmation each @assumption:CU-24.3-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    first = member.book("20:00")
    second = member.book("21:00")

    assert _cancel(member, first["id"]) == 200
    assert _cancel(member, second["id"]) == 200

    assert len(channel.sent) == 2
    center = member.center()
    assert center["unread"] == 2
    assert {n["booking_id"] for n in center["notifications"]} == {first["id"], second["id"]}


def test_if_the_push_service_is_down_the_confirmation_stays_in_the_center_as_failed(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """the failed delivery is not retried and the cancellation stays done @assumption:CU-24.3-SUP-01"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    app_of(api).dependency_overrides[push_channel] = DownChannel
    try:
        assert _cancel(member, booking["id"]) == 200
    finally:
        app_of(api).dependency_overrides.pop(push_channel, None)

    assert _deliveries(member) == ["failed"]
    assert len(member.center()["notifications"]) == 1


def test_what_was_left_pending_is_dispatched_only_once(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """the sweep picks up what did not go out and nobody sends it twice @assumption:CU-24.3-SUP-04"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    assert _cancel(member, booking["id"]) == 200
    channel.sent.clear()
    # As if the server had crashed before dispatching.
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE notification SET delivery = 'pending' WHERE user_id = :u"),
            {"u": member.user_id},
        )

    with engine.connect() as conn:
        first = dispatch_pending(NotificationsSql(conn), channel, member.user_id)
    with engine.connect() as conn:
        second = dispatch_pending(NotificationsSql(conn), channel, member.user_id)

    assert (first, second) == (1, 0)
    assert len(channel.sent) == 1
    assert _deliveries(member) == ["sent"]
