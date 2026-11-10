"""A notice that fails on dispatch neither blocks the others nor cuts the sweep."""

from collections.abc import Callable, Iterator
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, app_of, a_member

from app.modules.notifications.use_cases import dispatch_pending
from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.push import push_channel
from app.modules.notifications import sweep


@pytest.fixture
def channel(api: TestClient) -> Iterator[FakeChannel]:
    channel = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: channel
    yield channel
    app_of(api).dependency_overrides.pop(push_channel, None)


class FailsTheFirstTime(NotificationsSql):
    """The database goes down right when looking up the devices of the first notice."""

    calls = 0

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        FailsTheFirstTime.calls += 1
        if FailsTheFirstTime.calls == 1:
            raise OSError("la base no contesta")
        return super().tokens_with_permission(user_id)


def _three_pending_cancellations(member: Member) -> None:
    for start in ("20:00", "21:00", "22:00"):
        booking = member.book(start)
        r = member.api.post(f"/bookings/{booking['id']}/cancel", headers=member.session)
        assert r.status_code == 200
    with member.engine.begin() as conn:
        conn.execute(
            text("UPDATE notification SET delivery = 'pending', sent_at = NULL WHERE user_id = :u"),
            {"u": member.user_id},
        )


def _deliveries(member: Member) -> list[str]:
    with member.engine.connect() as conn:
        return [
            f.delivery
            for f in conn.execute(
                text("SELECT delivery FROM notification WHERE user_id = :u ORDER BY id"),
                {"u": member.user_id},
            )
        ]


def test_a_failure_on_the_first_notice_does_not_leave_the_rest_in_sending(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """the notice that fails ends up failed and the others go out @assumption:CU-24.3-SUP-04"""
    member = a_member(api, engine, sign_in, unique)
    _three_pending_cancellations(member)
    channel.sent.clear()
    FailsTheFirstTime.calls = 0

    with engine.connect() as conn:
        dispatched = dispatch_pending(FailsTheFirstTime(conn), channel, member.user_id)

    assert dispatched == 3
    assert _deliveries(member) == ["failed", "sent", "sent"]
    assert len(channel.sent) == 2


def test_if_the_dispatch_of_pending_notices_fails_the_reminders_still_go_out(
    monkeypatch: pytest.MonkeyPatch, engine: Engine
) -> None:
    """the sweep does not cut the reminders because of a pending notice that fails"""
    ran: list[str] = []

    def fails(*_: object, **__: object) -> int:
        raise OSError("la base no contesta")

    def reminders(*_: object, **__: object) -> int:
        ran.append("recordatorios")
        return 0

    monkeypatch.setattr(sweep, "dispatch_pending", fails)
    monkeypatch.setattr(sweep, "send_reminders", reminders)

    assert sweep.sweep_once() == 0
    assert ran == ["recordatorios"]
