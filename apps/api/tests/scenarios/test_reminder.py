from collections.abc import Callable, Sequence
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, cast
from uuid import UUID
from zoneinfo import ZoneInfo

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.notifications.rules import Notice, DeliveryResult

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")
PASSWORD = "ClubNahuel1"


def app_of(api: TestClient) -> FastAPI:
    """The FastAPI application behind the client, to replace dependencies."""
    return cast(FastAPI, api.app)


class FakeChannel:
    """The phone notification service, which records what it is asked to send."""

    def __init__(self) -> None:
        self.sent: list[tuple[list[str], Notice]] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.sent.append((list(tokens), notice))
        return DeliveryResult(sent=len(tokens), invalid=())


@dataclass
class Member:
    api: TestClient
    engine: Engine
    email: str
    session: dict[str, str]
    user_id: UUID
    space_id: UUID
    venue: str
    device: str
    bookings: list[dict[str, Any]] = field(default_factory=list)

    def book(self, start_hour: str) -> dict[str, Any]:
        r = self.api.post(
            "/bookings",
            headers=self.session,
            json={
                "space_id": str(self.space_id),
                "date": tomorrow().isoformat(),
                "start_hour": start_hour,
                "hours": 1,
            },
        )
        assert r.status_code == 201
        booking: dict[str, Any] = r.json()
        self.bookings.append(booking)
        return booking

    def sweep(self, channel: FakeChannel, now: datetime) -> int:
        """The reminder sweep running at the club time [now], for this member."""
        from app.modules.notifications.use_cases import send_reminders
        from app.modules.notifications.repository import NotificationsSql

        with self.engine.connect() as conn:
            return send_reminders(NotificationsSql(conn), channel, now, self.user_id)

    def center(self) -> dict[str, Any]:
        r = self.api.get("/notifications", headers=self.session)
        assert r.status_code == 200
        center: dict[str, Any] = r.json()
        return center


def tomorrow() -> Any:
    return datetime.now(ZONE).date() + timedelta(days=1)


def at_time(hour: int, minute: int = 0) -> datetime:
    """The time [hour]:[minute] tomorrow at the club."""
    return datetime.combine(tomorrow(), datetime.min.time(), ZONE).replace(hour=hour, minute=minute)


def a_member(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    *,
    permission: bool = True,
) -> Member:
    """A new account with a registered device, in a venue with a Football 5 court."""
    s = unique()
    email = f"socio.{s}@correo.com"
    signup = api.post(
        "/register",
        json={
            "first_name": "Martín",
            "last_name": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1994-07-21",
            "email": email,
            "password": PASSWORD,
        },
    )
    assert signup.status_code == 201
    venue = f"Sede Morón {s}"
    with engine.begin() as conn:
        space: Any = conn.execute(
            text(
                "WITH s AS (INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Rivadavia', 19850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id)"
                " INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id"
            ),
            {"n": venue, "e": f"Moron{s}_Rivadavia_19850_Futbol_F5_1"},
        ).scalar_one()
        user: Any = conn.execute(
            text("SELECT id FROM app_user WHERE email = :c"), {"c": email}
        ).scalar_one()
    token = sign_in(email, PASSWORD)
    assert token is not None
    session = {"Authorization": f"Bearer {token}"}
    device = f"fcm-{s}"
    registration = api.put(
        "/devices",
        headers=session,
        json={"token": device, "platform": "android", "permission_granted": permission},
    )
    assert registration.status_code == 204
    return Member(api, engine, email, session, user, space, venue, device)


def test_one_hour_before_the_start_the_reminder_is_sent_once_with_sport_venue_and_time(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """one hour before the start the member receives the reminder with sport, venue and time @CU-24.1-H01-01"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    channel = FakeChannel()

    # Checks: with more than an hour ahead nothing is sent yet.
    assert member.sweep(channel, at_time(19, 59)) == 0
    assert channel.sent == []

    # Checks: at the exact hour it goes out to the member's device, with what the use case says.
    assert member.sweep(channel, at_time(20, 0)) == 1
    assert len(channel.sent) == 1
    tokens, notice = channel.sent[0]
    assert tokens == [member.device]
    assert notice.title == "Your booking is in 1 hour"
    assert notice.body == f"Football 5 · {member.venue} · 21:00 – 22:00"
    assert notice.data["booking_id"] == str(booking["id"])

    # Checks: it is sent only once, even if the sweep passes again before the slot.
    assert member.sweep(channel, at_time(20, 30)) == 0
    assert len(channel.sent) == 1


def test_without_notification_permission_nothing_is_sent_but_the_notice_stays_in_the_center(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """without notification permission nothing is sent and the notice is recorded @CU-24.1-H03-01"""
    member = a_member(api, engine, sign_in, unique, permission=False)
    member.book("21:00")
    channel = FakeChannel()

    recorded = member.sweep(channel, at_time(20, 0))

    # Checks: nothing goes out to the phone, and the notice is in the center unread.
    assert recorded == 1
    assert channel.sent == []
    center = member.center()
    assert [n["title"] for n in center["notifications"]] == ["Your booking is in 1 hour"]
    assert center["unread"] == 1


def test_a_reminder_that_was_not_touched_stays_unread(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """a reminder that was not touched stays unread @CU-24.1-H04-01"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    assert member.center() == {"notifications": [], "unread": 0}

    member.sweep(FakeChannel(), at_time(20, 0))

    # Checks: the notice is in the center, unread, with its booking and its body.
    center = member.center()
    assert center["unread"] == 1
    [notice] = center["notifications"]
    assert notice["kind"] == "reminder"
    assert notice["read"] is False
    assert notice["booking_id"] == booking["id"]
    assert notice["body"] == f"Football 5 · {member.venue} · 21:00 – 22:00"


def test_mark_all_leaves_all_the_notifications_read(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """«Marcar todas» leaves all the notifications read @CU-24.1-H04-02"""
    member = a_member(api, engine, sign_in, unique)
    member.book("21:00")
    member.book("22:00")
    channel = FakeChannel()
    member.sweep(channel, at_time(20, 30))
    member.sweep(channel, at_time(21, 30))
    assert member.center()["unread"] == 2

    r = member.api.post("/notifications/read-all", headers=member.session)

    # Checks: none is left unread, and each one records that it was read.
    assert r.status_code == 204
    center = member.center()
    assert center["unread"] == 0
    assert [n["read"] for n in center["notifications"]] == [True, True]


def test_a_booking_canceled_earlier_gets_no_reminder(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """the booking was canceled earlier and the reminder does not arrive @CU-24.1-H05-01"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    canceled = member.api.post(f"/bookings/{booking['id']}/cancel", headers=member.session)
    assert canceled.status_code == 200
    channel = FakeChannel()

    recorded = member.sweep(channel, at_time(20, 0))

    # Checks: nothing is sent or recorded, neither at that hour nor later.
    assert recorded == 0
    assert member.sweep(channel, at_time(20, 45)) == 0
    assert channel.sent == []
    assert [n for n in member.center()["notifications"] if n["kind"] == "reminder"] == []


def test_a_modified_booking_gets_the_reminder_one_hour_before_the_new_time(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """the booking was modified and the reminder arrives one hour before the new time @CU-24.1-H05-02"""
    member = a_member(api, engine, sign_in, unique)
    booking = member.book("21:00")
    change = member.api.post(
        f"/bookings/{booking['id']}/modify",
        headers=member.session,
        json={
            "space_id": str(member.space_id),
            "date": tomorrow().isoformat(),
            "start_hour": "22:00",
        },
    )
    assert change.status_code == 200
    channel = FakeChannel()

    # Checks: one hour before the old time nothing arrives.
    assert member.sweep(channel, at_time(20, 0)) == 0
    assert channel.sent == []

    # Checks: one hour before the new one it arrives, with the new time.
    assert member.sweep(channel, at_time(21, 0)) == 1
    [(tokens, notice)] = channel.sent
    assert tokens == [member.device]
    assert notice.body == f"Football 5 · {member.venue} · 22:00 – 23:00"
