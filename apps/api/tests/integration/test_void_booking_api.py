"""`POST /bookings/{id}/void` against the real database and emulator."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta
from threading import Barrier
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

REASON = "mantenimiento de la cancha"


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


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


def _book(api: TestClient, user_token: str, space: str, day: int = 1) -> dict[str, Any]:
    on = (date.today() + timedelta(days=day)).isoformat()
    r = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={"space_id": space, "date": on, "start_hour": "18:00", "hours": 1},
    )
    assert r.status_code == 201
    booking: dict[str, Any] = r.json()
    return booking


def _request(booking: dict[str, Any], reason: str = REASON) -> dict[str, Any]:
    return {"reason": reason, "space_id": booking["space_id"], "starts_at": booking["starts_at"]}


def test_voiding_stamps_who_when_and_why_frees_the_slot_and_can_be_repeated(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """voiding stamps the trail and repeating the request answers the same @assumption:CU-15-SUP-07"""
    space = _new_space(api, admin_token, venue[0])
    booking = _book(api, user_token, space)

    r = api.post(
        f"/bookings/{booking['id']}/void",
        headers=_bearer(admin_token),
        json=_request(booking, f"  {REASON}  "),
    )
    again = api.post(
        f"/bookings/{booking['id']}/void", headers=_bearer(admin_token), json=_request(booking)
    )
    different = api.post(
        f"/bookings/{booking['id']}/void",
        headers=_bearer(admin_token),
        json=_request(booking, "otro motivo"),
    )

    assert r.status_code == 200
    assert (r.json()["status"], r.json()["reason"], r.json()["voidable"]) == (
        "voided",
        REASON,
        False,
    )
    assert r.json()["canceled_by_name"] == "Ana Díaz"
    assert r.json()["canceled_at"] is not None
    assert again.status_code == 200
    # The notice delivery happens after responding: the only thing that differs between the two.
    delivery = {"notice_delivery", "notice_at"}
    assert {k: v for k, v in again.json().items() if k not in delivery} == {
        k: v for k, v in r.json().items() if k not in delivery
    }
    assert different.status_code == 409
    with engine.connect() as conn:
        row = conn.execute(
            text("SELECT status, canceled_by IS NOT NULL FROM booking WHERE id = :id"),
            {"id": booking["id"]},
        ).one()
    assert tuple(row) == ("voided", True)
    # The slot is free again and the user sees it voided, with the reason.
    on = (date.today() + timedelta(days=1)).isoformat()
    assert (
        api.post(
            "/bookings",
            headers=_bearer(user_token),
            json={"space_id": space, "date": on, "start_hour": "18:00", "hours": 1},
        ).status_code
        == 201
    )
    history = api.get("/bookings?when=history", headers=_bearer(user_token)).json()
    assert [(x["status"], x["reason"]) for x in history["bookings"]] == [("voided", REASON)]


def test_voiding_rejects_what_does_not_apply(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """rejections for the reason and for a changed booking @assumption:CU-15-SUP-01 @assumption:CU-15-SUP-05"""
    space = _new_space(api, admin_token, venue[0])
    other_space = _new_space(api, admin_token, venue[0])
    booking = _book(api, user_token, space)
    started = _book(api, user_token, space, day=2)
    canceled = _book(api, user_token, space, day=3)
    assert (
        api.post(f"/bookings/{canceled['id']}/cancel", headers=_bearer(user_token)).status_code
        == 200
    )
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE booking SET starts_at = date_trunc('hour', now()), ends_at ="
                " date_trunc('hour', now()) + interval '1 hour' WHERE id = :id"
            ),
            {"id": started["id"]},
        )

    def void(id_: str, request: dict[str, Any], token: str = admin_token) -> int:
        return api.post(f"/bookings/{id_}/void", headers=_bearer(token), json=request).status_code

    assert void(booking["id"], _request(booking), user_token) == 403
    assert void("00000000-0000-7000-8000-000000000000", _request(booking)) == 404
    assert void(booking["id"], _request(booking, "")) == 422
    assert void(booking["id"], _request(booking, "   ")) == 422
    assert void(booking["id"], _request(booking, "x" * 501)) == 422
    assert void(started["id"], _request(started)) == 409
    assert void(canceled["id"], _request(canceled)) == 409
    # The booking was seen on another court or at another time: it changed in the meantime.
    assert void(booking["id"], _request(booking) | {"space_id": other_space}) == 409
    assert void(booking["id"], _request(started)) == 409
    assert api.post(f"/bookings/{booking['id']}/void", json=_request(booking)).status_code == 401
    with engine.connect() as conn:
        status: Any = conn.execute(
            text("SELECT status FROM booking WHERE id = :id"), {"id": booking["id"]}
        ).scalar_one()
    assert status == "active"


def test_the_list_offers_voiding_only_for_active_bookings_that_have_not_started(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    space = _new_space(api, admin_token, venue[0])
    booking = _book(api, user_token, space)
    api.post(
        f"/bookings/{booking['id']}/void", headers=_bearer(admin_token), json=_request(booking)
    )
    future = _book(api, user_token, space, day=2)

    listing = api.get("/bookings/all?q=" + venue[1], headers=_bearer(admin_token)).json()

    by_id = {x["id"]: x["voidable"] for x in listing["bookings"]}
    assert by_id[future["id"]] is True
    assert by_id[booking["id"]] is False


def test_voiding_and_canceling_at_the_same_time_leave_only_one_and_do_not_deadlock(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    space = _new_space(api, admin_token, venue[0])
    for day in range(1, 6):
        booking = _book(api, user_token, space, day=day)
        barrier = Barrier(2)

        def void(booking: dict[str, Any] = booking, barrier: Barrier = barrier) -> int:
            barrier.wait()
            return api.post(
                f"/bookings/{booking['id']}/void",
                headers=_bearer(admin_token),
                json=_request(booking),
            ).status_code

        def cancel(booking: dict[str, Any] = booking, barrier: Barrier = barrier) -> int:
            barrier.wait()
            return api.post(
                f"/bookings/{booking['id']}/cancel", headers=_bearer(user_token)
            ).status_code

        with ThreadPoolExecutor(2) as threads:
            a, c = (f.result() for f in (threads.submit(void), threads.submit(cancel)))
        with engine.connect() as conn:
            status: Any = conn.execute(
                text("SELECT status FROM booking WHERE id = :id"), {"id": booking["id"]}
            ).scalar_one()
        assert (a, c, status) in {(200, 409, "voided"), (409, 200, "canceled")}


def test_a_booking_that_already_started_is_rejected_even_if_its_current_time_is_sent(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """voiding what already started is rejected for having started, not for an outdated time"""
    space = _new_space(api, admin_token, venue[0])
    started = _book(api, user_token, space)
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE booking SET starts_at = date_trunc('hour', now()), ends_at ="
                " date_trunc('hour', now()) + interval '1 hour' WHERE id = :id"
            ),
            {"id": started["id"]},
        )
    current = api.get(f"/bookings/all/{started['id']}", headers=_bearer(admin_token)).json()
    assert current["voidable"] is False

    r = api.post(
        f"/bookings/{started['id']}/void",
        headers=_bearer(admin_token),
        json=_request(current),
    )

    assert r.status_code == 409
    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT status, starts_at <= now() AS empezo,"
                " starts_at = CAST(:starts_at AS timestamptz) AS coincide"
                " FROM booking WHERE id = :id"
            ),
            {"id": started["id"], "starts_at": current["starts_at"]},
        ).one()
    assert (row.status, row.empezo, row.coincide) == ("active", True, True)
