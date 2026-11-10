from collections.abc import Callable, Iterator, Sequence
from typing import Any
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, app_of, tomorrow, a_member

from app.modules.notifications.use_cases import dispatch_pending
from app.modules.notifications.repository import NotificationsSql, enqueue_forced_cancellation
from app.modules.notifications.push import push_channel
from app.modules.users.seed_admin import main as seed_admin

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
PASSWORD = "ClubNahuel1"
REASON = "mantenimiento de la cancha"
TITLE = "The club voided your booking"


class FailingChannel:
    def send(self, tokens: Sequence[str], notice: Any) -> Any:
        raise ConnectionError("el servicio no contesta")


@pytest.fixture
def channel(api: TestClient) -> Iterator[FakeChannel]:
    """The phone notification service, which records what the API asks it to send."""
    channel = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: channel
    yield channel
    app_of(api).dependency_overrides.pop(push_channel, None)


@pytest.fixture
def admin(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> dict[str, str]:
    s = unique()
    monkeypatch.setenv("ADMIN_PASSWORD", PASSWORD)
    arguments = [
        "--email", f"admin.{s}@club.com", "--first-name", "Ana", "--last-name", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--birth-date", "1985-06-01",
    ]  # fmt: skip
    assert seed_admin(arguments) == 0
    token = sign_in(f"admin.{s}@club.com", PASSWORD)
    assert token is not None
    return {"Authorization": f"Bearer {token}"}


def force_cancel(
    member: Member, admin: dict[str, str], booking: dict[str, Any], reason: str = REASON
) -> int:
    r = member.api.post(
        f"/bookings/{booking['id']}/void",
        headers=admin,
        json={"reason": reason, "space_id": booking["space_id"], "starts_at": booking["starts_at"]},
    )
    return r.status_code


def expected_body(venue: str, hour: str, reason: str = REASON) -> str:
    day = tomorrow()
    return f"Football 5 · {venue} · {DAYS[day.weekday()]} {day.day}, {hour}. Reason: {reason}."


def for_admin(member: Member, admin: dict[str, str], booking_id: str) -> dict[str, Any]:
    """The booking as the administrator sees it in the global history."""
    r = member.api.get(f"/bookings/all?q={member.venue}", headers=admin)
    assert r.status_code == 200
    [booking] = [x for x in r.json()["bookings"] if x["id"] == booking_id]
    assert isinstance(booking, dict)
    return booking


def test_when_a_booking_is_voided_the_user_gets_the_notice_with_sport_venue_date_and_reason(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """the administrator voids a booking and the user gets the notice with sport, venue, date and reason @CU-24.2-H01-01 @assumption:CU-24.2-SUP-06"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    assert channel.sent == []

    assert force_cancel(member, admin, booking) == 200

    # Verifies: a single notice goes out, to the member's device, with what the use case says.
    assert len(channel.sent) == 1
    tokens, notice = channel.sent[0]
    assert tokens == [member.device]
    assert notice.title == TITLE
    assert notice.body == expected_body(member.venue, "21:00")

    # Verifies: it is also in the center, unread.
    center = member.center()
    assert center["unread"] == 1
    [entry] = center["notifications"]
    assert (entry["kind"], entry["title"], entry["body"]) == (
        "forced_cancellation",
        notice.title,
        notice.body,
    )


def test_when_the_notice_is_tapped_the_app_knows_which_booking_to_open_and_the_history_has_it_voided(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """tapping the notice opens the history with the voided booking and its reason @CU-24.2-H01-02"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    assert force_cancel(member, admin, booking) == 200

    # Verifies: the push and the center carry the kind and the booking number.
    [(_, notice)] = channel.sent
    assert notice.data == {"kind": "forced_cancellation", "booking_id": str(booking["id"])}
    [entry] = member.center()["notifications"]
    assert entry["booking_id"] == booking["id"]

    # Verifies: that person's history lists it as voided and with the reason.
    history = member.api.get("/bookings?when=history", headers=member.session).json()
    assert [(r["id"], r["status"], r["reason"]) for r in history["bookings"]] == [
        (booking["id"], "voided", REASON)
    ]


def test_the_sending_of_the_notice_is_recorded_in_the_traceability_of_the_booking(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """the sending of the notice stays in the traceability of the booking @CU-24.2-H01-03 @assumption:CU-24.2-SUP-07"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    assert for_admin(member, admin, booking["id"])["notice_delivery"] is None

    assert force_cancel(member, admin, booking) == 200

    # Verifies: the administrator sees that it was sent, and when.
    detail = for_admin(member, admin, booking["id"])
    assert detail["notice_delivery"] == "sent"
    assert detail["notice_at"] is not None


def test_a_deactivation_that_affects_several_users_sends_a_notice_to_each_with_their_booking(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """a deactivation that affects several users sends a notice to each with their own booking @CU-24.2-H02-01 @assumption:CU-24.2-SUP-03"""
    one = a_member(api, engine, sign_in, unique)
    other = a_member(api, engine, sign_in, unique)
    of_one = one.book("20:00")
    of_other = other.book("21:00")

    # The deactivation voids the bookings and queues, in the same transaction, each person's notice.
    with engine.begin() as conn:
        for member, booking in ((one, of_one), (other, of_other)):
            conn.execute(
                text(
                    "UPDATE booking SET status = 'voided', reason = 'Baja de la sede',"
                    " canceled_at = now(), canceled_by = :u WHERE id = :id"
                ),
                {"u": member.user_id, "id": booking["id"]},
            )
            enqueue_forced_cancellation(conn, member.user_id, [UUID(booking["id"])])
    with engine.connect() as conn:
        for member in (one, other):
            dispatch_pending(NotificationsSql(conn), channel, member.user_id)

    # Verifies: each person gets a single notice, with the data of their own booking.
    assert [(t, a.body) for t, a in channel.sent] == [
        ([one.device], expected_body(one.venue, "20:00", "Baja de la sede")),
        ([other.device], expected_body(other.venue, "21:00", "Baja de la sede")),
    ]
    assert [e["title"] for e in one.center()["notifications"]] == [TITLE]
    assert [e["title"] for e in other.center()["notifications"]] == [TITLE]


def test_several_bookings_voided_for_the_same_person_arrive_in_a_single_notice_with_the_count(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """a user with several affected bookings gets a single notice with the count @CU-24.2-H03-01 @assumption:CU-24.2-SUP-02 @assumption:CU-24.2-SUP-04 @assumption:CU-24.2-SUP-06"""
    member = a_member(api, engine, sign_in, unique)
    first = member.book("20:00")
    second = member.book("21:00")

    assert force_cancel(member, admin, first) == 200
    assert force_cancel(member, admin, second) == 200

    # Verifies: the center has a single unread notice, which says how many and does not point to one.
    center = member.center()
    assert center["unread"] == 1
    [entry] = center["notifications"]
    assert entry["title"] == "The club voided 2 of your bookings"
    assert (
        entry["body"] == "You have 2 bookings voided by the club. See the detail in your history."
    )
    assert entry["booking_id"] is None

    # Verifies: the last push says the same and leads to My bookings without a specific booking.
    _, notice = channel.sent[-1]
    assert (notice.title, notice.body) == (entry["title"], entry["body"])
    assert notice.data == {"kind": "forced_cancellation"}

    # Verifies: both appear voided in the history, each with its reason.
    history = member.api.get("/bookings?when=history", headers=member.session).json()
    assert sorted((r["id"], r["status"]) for r in history["bookings"]) == sorted(
        [(first["id"], "voided"), (second["id"], "voided")]
    )

    # Verifies: both have the sending in their traceability.
    for booking in (first, second):
        assert for_admin(member, admin, booking["id"])["notice_delivery"] == "sent"


def test_a_voiding_after_reading_the_notice_opens_a_new_one(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """a voiding after reading the notice opens a new one @assumption:CU-24.2-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    first = member.book("20:00")
    second = member.book("21:00")
    assert force_cancel(member, admin, first) == 200
    [read] = member.center()["notifications"]
    assert api.post(f"/notifications/{read['id']}/read", headers=member.session).status_code == 204

    assert force_cancel(member, admin, second) == 200

    center = member.center()
    assert center["unread"] == 1
    assert [e["title"] for e in center["notifications"]] == [TITLE, TITLE]
    assert [e["read"] for e in center["notifications"]] == [False, True]


def test_without_notification_permission_the_push_does_not_arrive_but_the_notice_is_in_the_center(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """without notification permission the push does not arrive but the notice is in the center @CU-24.2-H04-01 @assumption:CU-24.2-SUP-07"""
    member = a_member(api, engine, sign_in, unique, permission=False)
    booking = member.book("21:00")

    assert force_cancel(member, admin, booking) == 200

    # Verifies: nothing goes out to the phone, the notice is in the center and the administrator
    # sees that the push did not go out.
    assert channel.sent == []
    [entry] = member.center()["notifications"]
    assert entry["title"] == TITLE
    assert for_admin(member, admin, booking["id"])["notice_delivery"] == "no_permission"


def test_if_the_user_had_already_canceled_the_booking_they_get_no_notice(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """if the user had already canceled the booking, they get no notice @CU-24.2-H05-01"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    canceled = member.api.post(f"/bookings/{booking['id']}/cancel", headers=member.session)
    assert canceled.status_code == 200

    assert force_cancel(member, admin, booking) == 409

    # Verifies: only the confirmation of their own cancellation remains.
    assert [a.data["kind"] for _, a in channel.sent] == ["user_cancellation"]
    assert [e["kind"] for e in member.center()["notifications"]] == ["user_cancellation"]


def test_repeating_the_voiding_does_not_repeat_the_notice(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """repeating the voiding does not repeat the notice @assumption:CU-24.2-SUP-08"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")

    assert force_cancel(member, admin, booking) == 200
    assert force_cancel(member, admin, booking) == 200

    assert len(channel.sent) == 1
    assert len(member.center()["notifications"]) == 1


def test_a_voiding_that_does_not_complete_leaves_no_notice(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """a rejected voiding leaves no notice @assumption:CU-24.2-SUP-08"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    moved = {**booking, "starts_at": "2030-01-01T21:00:00-03:00"}

    assert force_cancel(member, admin, moved) == 409

    assert channel.sent == []
    assert member.center() == {"notifications": [], "unread": 0}


def test_if_the_push_fails_it_is_not_retried_and_the_notice_stays_in_the_center(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    admin: dict[str, str],
) -> None:
    """if the push fails the notice stays in the center with the sending failed @assumption:CU-24.2-SUP-01 @assumption:CU-24.2-SUP-07"""
    app_of(api).dependency_overrides[push_channel] = lambda: FailingChannel()
    try:
        member = a_member(api, engine, sign_in, unique)
        booking = member.book("21:00")

        assert force_cancel(member, admin, booking) == 200

        assert [e["title"] for e in member.center()["notifications"]] == [TITLE]
        assert for_admin(member, admin, booking["id"])["notice_delivery"] == "failed"
    finally:
        app_of(api).dependency_overrides.pop(push_channel, None)
