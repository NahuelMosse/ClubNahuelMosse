"""`/bookings` against the real database and emulator."""

from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, time, timedelta
from threading import Barrier
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.bookings.repository import BookingsSql
from app.shared.errors import OpeningHoursChanged, SlotTaken


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _book(
    engine: Engine,
    user: UUID,
    space: str,
    day: date,
    hour: int,
    status: str = "active",
    reason: str | None = None,
) -> None:
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total,"
                " status, reason, canceled_at)"
                " SELECT :u, :e, x.i, x.i + interval '1 hour', 38000, 38000, :status, :reason,"
                " CASE WHEN :status <> 'active' THEN now() END"
                " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :h))"
                " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x"
            ),
            {"u": user, "e": space, "dia": day, "h": hour, "status": status, "reason": reason},
        )


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


def test_everyone_sees_their_upcoming_bookings_and_their_history_in_order(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, prefix = venue
    space = api.post(
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
    ).json()["id"]
    me = _me(api, engine, user_token)
    today = date.today()
    _book(engine, me, space, today + timedelta(days=3), 10)
    _book(engine, me, space, today + timedelta(days=1), 10)
    _book(engine, me, space, today + timedelta(days=2), 10, "canceled")
    _book(engine, me, space, today - timedelta(days=5), 10)
    _book(engine, me, space, today - timedelta(days=2), 10, "voided", "lluvia")
    _book(engine, _me(api, engine, admin_token), space, today + timedelta(days=4), 10)

    def bookings(when: str) -> list[dict[str, object]]:
        r = api.get("/bookings", headers=_bearer(user_token), params={"when": when})
        assert r.status_code == 200
        items: list[dict[str, object]] = r.json()["bookings"]
        return items

    upcoming = bookings("upcoming")
    assert [str(p["starts_at"])[:10] for p in upcoming] == [
        str(today + timedelta(days=1)),
        str(today + timedelta(days=3)),
    ]
    assert upcoming[0]["space"] == f"{prefix}_Futbol_F5_1"
    assert upcoming[0]["address"] == "Av. Vergara 1850"
    assert {p["status"] for p in upcoming} == {"active"}
    history = bookings("history")
    assert [h["status"] for h in history] == ["canceled", "voided", "completed"]
    assert history[1]["reason"] == "lluvia"


def test_bookings_require_a_session(api: TestClient) -> None:
    assert api.get("/bookings").status_code == 401


def _new_space(api: TestClient, admin_token: str, venue_id: str) -> str:
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
    return str(r.json()["id"])


def test_booking_saves_the_price_and_a_repeated_request_returns_the_same_one(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = _new_space(api, admin_token, venue_id)
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    payload = {"space_id": space, "date": tomorrow, "start_hour": "18:00", "hours": 2}

    first = api.post("/bookings", headers=_bearer(user_token), json=payload)
    second = api.post("/bookings", headers=_bearer(user_token), json=payload)

    assert first.status_code == 201
    assert (first.json()["total"], first.json()["status"]) == (76000, "active")
    assert second.status_code == 201
    assert second.json()["id"] == first.json()["id"]
    with engine.connect() as conn:
        assert (
            conn.execute(
                text("SELECT count(*) FROM booking WHERE space_id = :e"), {"e": space}
            ).scalar_one()
            == 1
        )
    grid = api.get(
        f"/spaces/{space}/slots",
        headers=_bearer(user_token),
        params={"date": tomorrow},
    ).json()
    free = {f["starts_at"]: f["available"] for f in grid["slots"]}
    assert (free["17:00"], free["18:00"], free["19:00"], free["20:00"]) == (
        True,
        False,
        False,
        True,
    )


def test_the_admin_does_not_book_and_a_deactivated_space_is_not_booked(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = _new_space(api, admin_token, venue_id)
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    payload = {"space_id": space, "date": tomorrow, "start_hour": "10:00", "hours": 1}

    assert api.post("/bookings", headers=_bearer(admin_token), json=payload).status_code == 403
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE space SET active = false, deactivated_at = now() WHERE id = :e"),
            {"e": space},
        )
    r = api.post("/bookings", headers=_bearer(user_token), json=payload)
    assert r.status_code == 422
    assert "space_id" in r.json()["errors"]
    assert api.post("/bookings", json=payload).status_code == 401


def test_two_simultaneous_bookings_of_the_same_slot_leave_one_and_the_other_is_taken(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = _new_space(api, admin_token, venue_id)
    me = _me(api, engine, user_token)
    other = _me(api, engine, admin_token)
    tomorrow = datetime.combine(
        date.today() + timedelta(days=1), time(0), tzinfo=ZoneInfo("America/Argentina/Buenos_Aires")
    )
    for hour in range(8, 18):
        start = tomorrow + timedelta(hours=hour)
        end = start + timedelta(hours=1)
        barrier = Barrier(2)

        def request(
            user: UUID,
            start: datetime = start,
            end: datetime = end,
            barrier: Barrier = barrier,
        ) -> str:
            with engine.connect() as conn:
                barrier.wait()
                try:
                    sql = BookingsSql(conn)
                    schedule = sql.opening_hours(UUID(space))
                    assert schedule is not None
                    return str(sql.insert(user, UUID(space), start, end, schedule).id)
                except SlotTaken:
                    return "taken"

        # Two different people: one gets it and the other sees the slot taken.
        with ThreadPoolExecutor(2) as threads:
            results = sorted(threads.map(request, [me, other]))
        assert results[1] == "taken", results
        UUID(results[0])

    # The same person twice at once: both responses are the same booking.
    start = tomorrow + timedelta(hours=20)
    barrier = Barrier(2)

    def repeat(_: int) -> str:
        with engine.connect() as conn:
            barrier.wait()
            sql = BookingsSql(conn)
            schedule = sql.opening_hours(UUID(space))
            assert schedule is not None
            return str(sql.insert(me, UUID(space), start, start + timedelta(hours=1), schedule).id)

    with ThreadPoolExecutor(2) as threads:
        a, b = threads.map(repeat, [0, 1])
    assert a == b


def test_cancelling_frees_the_slot_stamps_who_and_can_be_repeated(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = _new_space(api, admin_token, venue_id)
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    payload = {"space_id": space, "date": tomorrow, "start_hour": "18:00", "hours": 1}
    booking = api.post("/bookings", headers=_bearer(user_token), json=payload).json()["id"]

    r = api.post(f"/bookings/{booking}/cancel", headers=_bearer(user_token))
    again = api.post(f"/bookings/{booking}/cancel", headers=_bearer(user_token))

    assert r.status_code == 200
    assert r.json()["status"] == "canceled"
    assert again.status_code == 200
    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT canceled_at IS NOT NULL, canceled_by = user_id FROM booking WHERE id = :id"
            ),
            {"id": booking},
        ).one()
    assert tuple(row) == (True, True)
    # The slot is free again for another booking.
    assert api.post("/bookings", headers=_bearer(user_token), json=payload).status_code == 201


def test_a_foreign_a_started_or_a_voided_booking_is_not_cancelled(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = _new_space(api, admin_token, venue_id)
    me = _me(api, engine, user_token)
    other = _me(api, engine, admin_token)
    today = date.today()
    _book(engine, other, space, today + timedelta(days=1), 10)
    _book(engine, me, space, today + timedelta(days=1), 12)
    _book(engine, me, space, today + timedelta(days=2), 12, "voided", "lluvia")
    with engine.begin() as conn:
        booking_ids: list[Any] = list(
            conn.execute(
                text("SELECT id FROM booking WHERE space_id = :e ORDER BY starts_at"),
                {"e": space},
            ).scalars()
        )
        foreign, mine, voided = booking_ids
        conn.execute(
            text(
                "UPDATE booking SET starts_at = date_trunc('hour', now()), ends_at ="
                " date_trunc('hour', now()) + interval '1 hour' WHERE id = :id"
            ),
            {"id": mine},
        )

    def cancel(booking: UUID) -> int:
        return api.post(f"/bookings/{booking}/cancel", headers=_bearer(user_token)).status_code

    assert cancel(foreign) == 404
    assert cancel(mine) == 409
    assert cancel(voided) == 409
    assert api.post(f"/bookings/{mine}/cancel").status_code == 401


def test_modifying_moves_the_same_booking_frees_the_slot_and_recalculates_the_total(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    one = _new_space(api, admin_token, venue_id)
    other = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json={
            "venue_id": venue_id,
            "sport": "Futbol",
            "kind": "F5",
            "covered": True,
            "lit": True,
            "price_per_hour": 43000,
        },
    ).json()["id"]
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    booking = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={"space_id": one, "date": tomorrow, "start_hour": "21:00", "hours": 2},
    ).json()

    r = api.post(
        f"/bookings/{booking['id']}/modify",
        headers=_bearer(user_token),
        json={"space_id": other, "date": tomorrow, "start_hour": "18:00"},
    )

    assert r.status_code == 200, r.text
    assert (r.json()["id"], r.json()["space_id"], r.json()["total"]) == (
        booking["id"],
        other,
        86000,
    )
    # The previous slot is free and the new court's grid ignores it only for its
    # owner.
    free = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={"space_id": one, "date": tomorrow, "start_hour": "21:00", "hours": 1},
    )
    assert free.status_code == 201
    grid = api.get(
        f"/spaces/{other}/slots",
        headers=_bearer(user_token),
        params={"date": tomorrow, "hours": 2, "booking_id": booking["id"]},
    ).json()
    assert {f["starts_at"]: f["available"] for f in grid["slots"]}["18:00"] is True
    foreign = api.get(
        f"/spaces/{other}/slots",
        headers=_bearer(admin_token),
        params={"date": tomorrow, "hours": 2, "booking_id": booking["id"]},
    ).json()
    assert {f["starts_at"]: f["available"] for f in foreign["slots"]}["18:00"] is False


def test_modifying_rejects_what_does_not_apply(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = _new_space(api, admin_token, venue_id)
    hockey = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json={
            "venue_id": venue_id,
            "sport": "Hockey",
            "kind": "H7",
            "covered": False,
            "lit": True,
            "price_per_hour": 50000,
        },
    ).json()["id"]
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    mine = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={"space_id": space, "date": tomorrow, "start_hour": "10:00", "hours": 1},
    ).json()["id"]
    _book(engine, _me(api, engine, admin_token), space, date.today() + timedelta(days=1), 12)

    def change(body: dict[str, object], token: str = user_token) -> tuple[int, object]:
        r = api.post(f"/bookings/{mine}/modify", headers=_bearer(token), json=body)
        return r.status_code, r.json() if r.content else None

    # The same slot is a retry of a change already made: it answers with the booking.
    same = change({"space_id": space, "date": tomorrow, "start_hour": "10:00"})
    assert same[0] == 200
    assert isinstance(same[1], dict)
    assert same[1]["id"] == mine
    assert change({"space_id": hockey, "date": tomorrow, "start_hour": "10:00"})[0] == 422
    taken = change({"space_id": space, "date": tomorrow, "start_hour": "12:00"})
    assert taken == (409, {"errors": {"slot": "That slot was taken"}})
    assert (
        change({"space_id": space, "date": tomorrow, "start_hour": "15:00"}, admin_token)[0] == 403
    )
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE booking SET status = 'voided', reason = 'lluvia' WHERE id = :id"),
            {"id": mine},
        )
    changed = change({"space_id": space, "date": tomorrow, "start_hour": "15:00"})
    assert changed == (409, {"errors": {"booking": "This changed in the meantime"}})


def test_two_crossed_changes_between_the_same_courts_wait_for_each_other_without_locking_up(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    a = _new_space(api, admin_token, venue_id)
    b = _new_space(api, admin_token, venue_id)
    me = _me(api, engine, user_token)
    tomorrow = datetime.combine(
        date.today() + timedelta(days=1), time(0), tzinfo=ZoneInfo("America/Argentina/Buenos_Aires")
    )
    ua, ub = UUID(a), UUID(b)
    with engine.connect() as conn:
        schedule = BookingsSql(conn).opening_hours(ua)
    assert schedule is not None
    for hour in range(8, 20, 2):
        ten, eleven = tomorrow + timedelta(hours=hour), tomorrow + timedelta(hours=hour + 1)
        one_hour = timedelta(hours=1)
        with engine.connect() as conn:
            sql = BookingsSql(conn)
            r1 = sql.insert(me, ua, ten, ten + one_hour, schedule).id
            r2 = sql.insert(me, ub, eleven, eleven + one_hour, schedule).id
        barrier = Barrier(2)

        # Each one wants the other's place, which is still taken: both end up taken.
        def move(
            change: tuple[UUID, tuple[UUID, datetime], UUID, datetime],
            barrier: Barrier = barrier,
            one_hour: timedelta = one_hour,
        ) -> str:
            booking, before, space, start = change
            with engine.connect() as conn:
                barrier.wait()
                try:
                    BookingsSql(conn).move(
                        me, booking, before, space, start, start + one_hour, schedule
                    )
                except SlotTaken:
                    return "taken"
                return "moved"

        with ThreadPoolExecutor(2) as threads:
            results = list(
                threads.map(move, [(r1, (ua, ten), ub, eleven), (r2, (ub, eleven), ua, ten)])
            )
        assert results == ["taken", "taken"]


def test_a_booking_validated_with_the_old_hours_is_not_saved(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = _new_space(api, admin_token, venue_id)
    me = _me(api, engine, user_token)
    tomorrow = datetime.combine(
        date.today() + timedelta(days=1), time(8), tzinfo=ZoneInfo("America/Argentina/Buenos_Aires")
    )
    with engine.connect() as conn:
        old = BookingsSql(conn).opening_hours(UUID(space))
    assert old is not None
    with engine.begin() as conn:
        conn.execute(text("UPDATE venue SET opens_at = '09:00' WHERE id = :s"), {"s": venue_id})

    # Checks: the 8 o'clock booking, validated before the change, does not go in.
    with engine.connect() as conn, pytest.raises(OpeningHoursChanged):
        BookingsSql(conn).insert(me, UUID(space), tomorrow, tomorrow + timedelta(hours=1), old)
    # Checks: through the API, it is validated again with the new hours.
    r = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={
            "space_id": space,
            "date": tomorrow.date().isoformat(),
            "start_hour": "08:00",
            "hours": 1,
        },
    )
    assert r.status_code == 422
    assert r.json()["errors"]["start_hour"] == "The venue opens at 09:00"
