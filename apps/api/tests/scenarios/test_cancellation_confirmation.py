from collections.abc import Callable, Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, app_of, tomorrow, a_member

from app.modules.notifications.push import push_channel

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


@pytest.fixture
def channel(api: TestClient) -> Iterator[FakeChannel]:
    """The phone notification service, which records what the API asks it to send."""
    channel = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: channel
    yield channel
    app_of(api).dependency_overrides.pop(push_channel, None)


def cancel(member: Member, booking_id: str) -> int:
    return member.api.post(f"/bookings/{booking_id}/cancel", headers=member.session).status_code


def expected_body(venue: str, hour: str) -> str:
    day = tomorrow()
    return f"Football 5 · {venue} · {DAYS[day.weekday()]} {day.day}, {hour}. The slot was freed."


def test_cancelling_a_booking_sends_the_confirmation_with_the_booking_and_the_freed_slot(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """cancels a booking and receives the confirmation with the booking and the freed slot @CU-24.3-H01-01"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")

    # Verifies: nothing goes out before cancelling.
    assert channel.sent == []

    assert cancel(member, booking["id"]) == 200

    # Verifies: a single confirmation goes out, to the member's device, with what the CU says.
    assert len(channel.sent) == 1
    tokens, notice = channel.sent[0]
    assert tokens == [member.device]
    assert notice.title == "Booking cancelled"
    assert notice.body == expected_body(member.venue, "21:00")
    assert notice.data["booking_id"] == str(booking["id"])
    assert notice.data["kind"] == "user_cancellation"


def test_tapping_the_confirmation_tells_the_app_which_booking_to_open(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """tapping the confirmation opens the history with the cancelled booking @CU-24.3-H01-02"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    assert cancel(member, booking["id"]) == 200

    # Verifies: the push and the center carry the booking number, which the history lists
    # as cancelled.
    [(_, notice)] = channel.sent
    assert notice.data["booking_id"] == str(booking["id"])
    [entry] = member.center()["notifications"]
    assert entry["booking_id"] == booking["id"]
    history = member.api.get("/bookings?when=history", headers=member.session).json()
    assert [(r["id"], r["status"]) for r in history["bookings"]] == [(booking["id"], "canceled")]


def test_the_confirmation_stays_in_the_notification_center(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """the confirmation stays in the notification center @CU-24.3-H01-03"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    assert member.center() == {"notifications": [], "unread": 0}

    assert cancel(member, booking["id"]) == 200

    # Verifies: an unread confirmation entry remains, with the CU text.
    center = member.center()
    assert center["unread"] == 1
    [entry] = center["notifications"]
    assert entry["kind"] == "user_cancellation"
    assert entry["title"] == "Booking cancelled"
    assert entry["body"] == expected_body(member.venue, "21:00")
    assert entry["read"] is False


def test_without_notification_permission_nothing_is_sent_but_the_confirmation_stays_in_the_center(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """without notification permission the push is not sent but the confirmation is in the center @CU-24.3-H03-01"""
    member = a_member(api, engine, sign_in, unique, permission=False)
    booking = member.book("21:00")

    assert cancel(member, booking["id"]) == 200

    # Verifies: nothing goes out to the phone and the confirmation is in the center.
    assert channel.sent == []
    [entry] = member.center()["notifications"]
    assert entry["title"] == "Booking cancelled"


def test_if_the_cancellation_fails_nothing_is_confirmed(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """if the cancellation failed, it receives no confirmation @CU-24.3-H04-01"""
    member = a_member(api, engine, sign_in, unique)
    other = a_member(api, engine, sign_in, unique)
    someone_elses = other.book("21:00")
    voided = member.book("20:00")
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE booking SET status = 'voided', reason = 'mantenimiento',"
                " canceled_at = now(), canceled_by = :u WHERE id = :id"
            ),
            {"u": member.user_id, "id": voided["id"]},
        )

    # Verifies: cancelling someone else's booking (404) or one the club already voided (409)
    # fails and leaves no confirmation for anybody.
    assert cancel(member, someone_elses["id"]) == 404
    assert cancel(member, voided["id"]) == 409
    assert channel.sent == []
    assert member.center() == {"notifications": [], "unread": 0}
    assert other.center() == {"notifications": [], "unread": 0}
