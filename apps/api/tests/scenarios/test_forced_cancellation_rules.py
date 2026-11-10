from collections.abc import Callable
from uuid import UUID

import test_forced_cancellation as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, a_member

admin = base.admin
channel = base.channel


def test_a_notice_that_is_going_out_is_grouped_with_the_next_voiding(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """the notice in progress still goes out and the next voiding opens one with the total count,
    which is the only one of the center @assumption:CU-24.2-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    first = member.book("20:00")
    second = member.book("21:00")
    assert base.force_cancel(member, admin, first) == 200
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE notification SET delivery = 'sending' WHERE user_id = :u"),
            {"u": member.user_id},
        )

    assert base.force_cancel(member, admin, second) == 200

    center = member.center()
    assert center["unread"] == 1
    assert [e["title"] for e in center["notifications"]] == ["The club voided 2 of your bookings"]


def test_the_long_reason_is_trimmed_in_the_notice_and_the_history_keeps_it(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """the reason of the notice has 200 characters at most @assumption:CU-24.2-SUP-06"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    reason = "x" * 300

    assert base.force_cancel(member, admin, booking, reason) == 200

    [(_, notice)] = channel.sent
    assert notice.body.endswith(f"Reason: {'x' * 199}….")
    history = member.api.get("/bookings?when=history", headers=member.session).json()
    assert [r["reason"] for r in history["bookings"]] == [reason]


def test_a_booking_with_a_notice_does_not_repeat_it_if_it_is_queued_again(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """queueing the same booking twice leaves a single notice @assumption:CU-24.2-SUP-08"""
    from app.modules.notifications.repository import enqueue_forced_cancellation

    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    assert base.force_cancel(member, admin, booking) == 200

    with engine.begin() as conn:
        enqueue_forced_cancellation(conn, member.user_id, [UUID(booking["id"])])

    assert len(member.center()["notifications"]) == 1
