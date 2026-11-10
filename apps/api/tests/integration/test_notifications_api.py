"""Devices, reminders and the notification center against the real database and emulator."""

from collections.abc import Callable, Sequence
from datetime import datetime, timedelta
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import Notice, Reminder
from app.modules.notifications.use_cases import DeliveryResult, send_reminders

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


class Channel:
    def __init__(self, fails: bool = False) -> None:
        self.fails = fails
        self.sent: list[tuple[list[str], Notice]] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        if self.fails:
            raise ConnectionError("el servicio no contesta")
        self.sent.append((list(tokens), notice))
        return DeliveryResult(sent=len(tokens))


def _me(api: TestClient, engine: Engine, token: str) -> UUID:
    email = api.get("/me", headers=_bearer(token)).json()["email"]
    with engine.connect() as conn:
        return UUID(
            str(
                conn.execute(
                    text("SELECT id FROM app_user WHERE email = :c"), {"c": email}
                ).scalar_one()
            )
        )


def _space(api: TestClient, admin_token: str, venue_id: str) -> str:
    r = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json={
            "venue_id": venue_id,
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    )
    assert r.status_code == 201
    return str(r.json()["id"])


def _sweep(engine: Engine, user: UUID, channel: Channel, now: datetime) -> int:
    with engine.connect() as conn:
        return send_reminders(NotificationsSql(conn), channel, now, user)


def _tomorrow_at(hour: int) -> datetime:
    day = datetime.now(ZONE).date() + timedelta(days=1)
    return datetime.combine(day, datetime.min.time(), ZONE).replace(hour=hour)


def _register(api: TestClient, token: str, device: str, permission: bool = True) -> int:
    return api.put(
        "/devices",
        headers=_bearer(token),
        json={"token": device, "platform": "android", "permission_granted": permission},
    ).status_code


def _book(api: TestClient, token: str, space: str, since: str = "21:00") -> dict[str, Any]:
    r = api.post(
        "/bookings",
        headers=_bearer(token),
        json={
            "space_id": space,
            "date": _tomorrow_at(0).date().isoformat(),
            "start_hour": since,
            "hours": 1,
        },
    )
    assert r.status_code == 201
    booking: dict[str, Any] = r.json()
    return booking


def test_registering_a_device_requires_a_user_session_and_valid_data(
    api: TestClient, admin_token: str, user_token: str, unique: Callable[[], str]
) -> None:
    device = f"fcm-{unique()}"
    body = {"token": device, "platform": "android", "permission_granted": True}

    assert api.put("/devices", json=body).status_code == 401
    assert api.put("/devices", headers=_bearer(admin_token), json=body).status_code == 403
    empty = api.put("/devices", headers=_bearer(user_token), json=body | {"token": "  "})
    assert empty.status_code == 422
    assert empty.json()["errors"]["token"] == "This field is required"
    assert (
        api.put(
            "/devices", headers=_bearer(user_token), json=body | {"platform": "web"}
        ).status_code
        == 422
    )
    assert api.put("/devices", headers=_bearer(user_token), json=body).status_code == 204
    # Registering it again with another permission updates it, does not duplicate it.
    assert (
        api.put(
            "/devices", headers=_bearer(user_token), json=body | {"permission_granted": False}
        ).status_code
        == 204
    )


def test_a_token_registered_by_another_account_does_not_change_owner(
    api: TestClient,
    engine: Engine,
    user_token: str,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    s = unique()
    device = f"fcm-{s}"
    assert _register(api, user_token, device) == 204
    other = api.post(
        "/register",
        json={
            "first_name": "Lucía",
            "last_name": "Paz",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1996-02-11",
            "email": f"otra.{s}@correo.com",
            "password": "ClubNahuel1",
        },
    )
    assert other.status_code == 201
    other_token = sign_in(f"otra.{s}@correo.com", "ClubNahuel1")
    assert other_token is not None

    assert _register(api, other_token, device) == 204

    with engine.connect() as conn:
        owners = conn.execute(
            text("SELECT user_id FROM device WHERE token = :t AND active"),
            {"t": device},
        ).all()
    assert [d.user_id for d in owners] == [_me(api, engine, user_token)]


def test_with_several_devices_all_receive_and_on_signing_out_one_stops_receiving(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    """several sessions at once and on signing out one stops receiving push (decision 14)"""
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    s = unique()
    assert _register(api, user_token, f"a-{s}") == 204
    assert _register(api, user_token, f"b-{s}") == 204
    _book(api, user_token, space)
    first = Channel()

    assert _sweep(engine, user, first, _tomorrow_at(20)) == 1
    assert [t for t, _ in first.sent] == [[f"a-{s}", f"b-{s}"]]

    unregistered = api.post(
        "/devices/unregister", headers=_bearer(user_token), json={"token": f"a-{s}"}
    )
    assert unregistered.status_code == 204
    other_booking = _book(api, user_token, space, "22:00")
    second = Channel()
    assert _sweep(engine, user, second, _tomorrow_at(21)) == 1
    assert [t for t, _ in second.sent] == [[f"b-{s}"]]
    assert second.sent[0][1].data["booking_id"] == str(other_booking["id"])
    # Unregistering one that is already gone answers the same.
    repeated = api.post(
        "/devices/unregister", headers=_bearer(user_token), json={"token": f"a-{s}"}
    )
    assert repeated.status_code == 204


def test_a_booking_made_less_than_an_hour_ahead_gets_no_reminder(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """a booking made less than an hour ahead gives no notice (decision 10)"""
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    start = _tomorrow_at(21)
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total,"
                " created_at, updated_at) VALUES (:u, :e, :i, :f, 38000, 38000, :c, :c)"
            ),
            {
                "u": user,
                "e": space,
                "i": start,
                "f": start + timedelta(hours=1),
                "c": start - timedelta(minutes=30),
            },
        )
    channel = Channel()

    assert _sweep(engine, user, channel, start - timedelta(minutes=20)) == 0
    assert channel.sent == []


def test_if_the_sweep_runs_late_the_reminder_goes_out_while_the_booking_has_not_started(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    """if the server was down the notice goes out late, before the start
    @assumption:CU-24.1-SUP-07"""
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    _register(api, user_token, f"fcm-{unique()}")
    _book(api, user_token, space)
    channel = Channel()

    assert _sweep(engine, user, channel, _tomorrow_at(21)) == 0
    assert _sweep(engine, user, channel, _tomorrow_at(20) + timedelta(minutes=50)) == 1
    assert len(channel.sent) == 1


def test_a_booking_modified_after_the_notice_gets_another_one_for_the_new_slot(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """a modified booking gets a new notice and the previous one stays @assumption:CU-24.1-SUP-12"""
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    booking = _book(api, user_token, space)
    assert _sweep(engine, user, Channel(), _tomorrow_at(20)) == 1
    change = api.post(
        f"/bookings/{booking['id']}/modify",
        headers=_bearer(user_token),
        json={
            "space_id": space,
            "date": _tomorrow_at(0).date().isoformat(),
            "start_hour": "22:00",
        },
    )
    assert change.status_code == 200

    assert _sweep(engine, user, Channel(), _tomorrow_at(21)) == 1

    bodies = [
        n["body"]
        for n in api.get("/notifications", headers=_bearer(user_token)).json()["notifications"]
    ]
    assert [c.rsplit(" · ", 1)[1] for c in bodies] == ["22:00 – 23:00", "21:00 – 22:00"]


def test_a_failed_delivery_leaves_the_notice_in_the_center_marked_as_failed(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    """the failed delivery stays in the center, without a retry @assumption:CU-24.1-SUP-02"""
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    _register(api, user_token, f"fcm-{unique()}")
    _book(api, user_token, space)

    assert _sweep(engine, user, Channel(fails=True), _tomorrow_at(20)) == 1
    assert _sweep(engine, user, Channel(), _tomorrow_at(20)) == 0

    with engine.connect() as conn:
        delivery: Any = conn.execute(
            text("SELECT delivery FROM notification WHERE user_id = :u"), {"u": user}
        ).scalar_one()
    assert delivery == "failed"
    assert api.get("/notifications", headers=_bearer(user_token)).json()["unread"] == 1


def test_the_notice_stores_when_it_was_created_sent_and_read(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    """creation, delivery and reading are stamped @assumption:CU-24.1-SUP-05"""
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    _register(api, user_token, f"fcm-{unique()}")
    _book(api, user_token, space)
    _sweep(engine, user, Channel(), _tomorrow_at(20))
    notice = api.get("/notifications", headers=_bearer(user_token)).json()["notifications"][0]

    with engine.connect() as conn:
        before = conn.execute(
            text(
                "SELECT created_at AS creada_en, sent_at, read_at FROM notification WHERE id = :i"
            ),
            {"i": notice["id"]},
        ).one()
    assert before.creada_en is not None
    assert before.sent_at is not None
    assert before.read_at is None

    read = api.post(f"/notifications/{notice['id']}/read", headers=_bearer(user_token))
    assert read.status_code == 204
    with engine.connect() as conn:
        after: Any = conn.execute(
            text("SELECT read_at FROM notification WHERE id = :i"), {"i": notice["id"]}
        ).scalar_one()
    assert after is not None
    # Reading it again answers the same and does not change when it was read.
    api.post(f"/notifications/{notice['id']}/read", headers=_bearer(user_token))
    with engine.connect() as conn:
        same: Any = conn.execute(
            text("SELECT read_at FROM notification WHERE id = :i"), {"i": notice["id"]}
        ).scalar_one()
    assert same == after


def test_notifications_belong_to_whoever_receives_them(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    _book(api, user_token, space)
    _sweep(engine, user, Channel(), _tomorrow_at(20))
    foreign = api.get("/notifications", headers=_bearer(user_token)).json()["notifications"][0]
    s = unique()
    api.post(
        "/register",
        json={
            "first_name": "Lucía",
            "last_name": "Paz",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1996-02-11",
            "email": f"otra.{s}@correo.com",
            "password": "ClubNahuel1",
        },
    )
    other_token = sign_in(f"otra.{s}@correo.com", "ClubNahuel1")
    assert other_token is not None

    assert api.get("/notifications").status_code == 401
    assert api.get("/notifications", headers=_bearer(other_token)).json() == {
        "notifications": [],
        "unread": 0,
    }
    assert (
        api.post(f"/notifications/{foreign['id']}/read", headers=_bearer(other_token)).status_code
        == 404
    )
    api.post("/notifications/read-all", headers=_bearer(other_token))
    assert api.get("/notifications", headers=_bearer(user_token)).json()["unread"] == 1


def test_the_edge_of_devices_and_notifications_answers_with_a_code(
    api: TestClient, user_token: str
) -> None:
    session = _bearer(user_token)
    base = {"token": "fcm-x", "platform": "android", "permission_granted": True}

    assert (
        api.put(
            "/devices", headers=session, json=base | {"permission_granted": "quizás"}
        ).status_code
        == 422
    )
    assert api.put("/devices", headers=session, json={"token": "fcm-x"}).status_code == 422
    assert api.put("/devices", headers=session, content=b"{roto").status_code == 422
    assert api.put("/devices", headers=session, json=base | {"token": 7}).status_code == 422
    assert api.post("/notifications/0/read", headers=session).status_code == 422
    assert api.post(f"/notifications/{2**63}/read", headers=session).status_code == 422
    assert api.post("/notifications/abc/read", headers=session).status_code == 422
    nonexistent = "/notifications/00000000-0000-7000-8000-0000000000ff/read"
    assert api.post(nonexistent, headers=session).status_code == 404


def test_the_center_responses_carry_no_extra_fields_and_are_not_cached(
    api: TestClient, user_token: str
) -> None:
    r = api.get("/notifications", headers=_bearer(user_token))

    assert r.status_code == 200
    assert set(r.json()) == {"notifications", "unread"}


class BetweenSnapshotAndRecord(NotificationsSql):
    """Makes something happen right after the sweep looks at the bookings and before it
    records the notice."""

    def __init__(self, conn: Any, someone: Callable[[], None]) -> None:
        super().__init__(conn)
        self._someone = someone

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        snapshot = super().due(now, user_id)
        self._someone()
        return snapshot


def _sweep_with(
    engine: Engine, user: UUID, channel: Channel, now: datetime, someone: Callable[[], None]
) -> int:
    with engine.connect() as conn:
        return send_reminders(BetweenSnapshotAndRecord(conn, someone), channel, now, user)


def _no_reminders(engine: Engine, user: UUID) -> bool:
    with engine.connect() as conn:
        return (
            conn.execute(
                text("SELECT count(*) FROM notification WHERE user_id = :u AND kind = 'reminder'"),
                {"u": user},
            ).scalar_one()
            == 0
        )


def test_a_booking_cancelled_between_the_read_and_the_record_gets_no_notice(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    _register(api, user_token, f"fcm-{unique()}")
    booking = _book(api, user_token, space)
    channel = Channel()

    def cancel() -> None:
        r = api.post(f"/bookings/{booking['id']}/cancel", headers=_bearer(user_token))
        assert r.status_code == 200

    assert _sweep_with(engine, user, channel, _tomorrow_at(20), cancel) == 0
    assert channel.sent == []
    assert _no_reminders(engine, user)


def test_a_booking_moved_between_the_read_and_the_record_does_not_notice_the_old_slot(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    _register(api, user_token, f"fcm-{unique()}")
    booking = _book(api, user_token, space)
    channel = Channel()

    def move() -> None:
        r = api.post(
            f"/bookings/{booking['id']}/modify",
            headers=_bearer(user_token),
            json={
                "space_id": space,
                "date": _tomorrow_at(0).date().isoformat(),
                "start_hour": "22:00",
            },
        )
        assert r.status_code == 200

    assert _sweep_with(engine, user, channel, _tomorrow_at(20), move) == 0
    assert channel.sent == []
    assert _no_reminders(engine, user)


def test_an_account_deactivated_between_the_read_and_the_record_gets_no_notice(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    space = _space(api, admin_token, venue[0])
    user = _me(api, engine, user_token)
    _register(api, user_token, f"fcm-{unique()}")
    _book(api, user_token, space)
    channel = Channel()

    def deactivate() -> None:
        with engine.begin() as conn:
            conn.execute(
                text("UPDATE app_user SET active = false, deactivated_at = now() WHERE id = :u"),
                {"u": user},
            )

    assert _sweep_with(engine, user, channel, _tomorrow_at(20), deactivate) == 0
    assert channel.sent == []
    assert _no_reminders(engine, user)
