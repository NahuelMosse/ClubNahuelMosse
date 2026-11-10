import threading
from collections.abc import Callable, Iterator, Sequence

import pytest
import test_forced_cancellation as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine
from test_reminder import FakeChannel, app_of, a_member

from app.modules.notifications.rules import Notice, DeliveryResult
from app.modules.notifications.push import push_channel

admin = base.admin


class ChannelThatHoldsTheFirst(FakeChannel):
    """The first send stays in progress until released, like a slow push."""

    def __init__(self) -> None:
        super().__init__()
        self.sending = threading.Event()
        self.release = threading.Event()

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        first = not self.sent
        result = super().send(tokens, notice)
        if first:
            self.sending.set()
            assert self.release.wait(timeout=30)
        return result


@pytest.fixture
def slow_channel(api: TestClient) -> Iterator[ChannelThatHoldsTheFirst]:
    channel = ChannelThatHoldsTheFirst()
    app_of(api).dependency_overrides[push_channel] = lambda: channel
    yield channel
    channel.release.set()
    app_of(api).dependency_overrides.pop(push_channel, None)


def test_a_voiding_that_arrives_while_the_previous_notice_is_going_out_is_grouped_anyway(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    slow_channel: ChannelThatHoldsTheFirst,
    admin: dict[str, str],
) -> None:
    """the dispatch of the first notice is slow and the second voiding still arrives in a single
    notice with the count @assumption:CU-24.2-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    first = member.book("20:00")
    second = member.book("21:00")
    statuses: list[int] = []
    thread = threading.Thread(
        target=lambda: statuses.append(base.force_cancel(member, admin, first))
    )
    thread.start()
    try:
        assert slow_channel.sending.wait(timeout=30)

        statuses.append(base.force_cancel(member, admin, second))
    finally:
        slow_channel.release.set()
        thread.join(timeout=30)

    assert statuses == [200, 200]
    center = member.center()
    assert center["unread"] == 1
    assert [e["title"] for e in center["notifications"]] == ["The club voided 2 of your bookings"]
