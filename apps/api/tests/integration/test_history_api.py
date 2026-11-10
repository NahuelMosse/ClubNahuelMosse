"""`GET /bookings/all`: the date cuts and the search against the real database and emulator."""

from datetime import date, timedelta
from typing import Any
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


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


def _book(api: TestClient, user_token: str, space: str, day: int) -> dict[str, Any]:
    on = (date.today() + timedelta(days=day)).isoformat()
    r = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={"space_id": space, "date": on, "start_hour": "18:00", "hours": 1},
    )
    assert r.status_code == 201
    booking: dict[str, Any] = r.json()
    return booking


def _move_to(engine: Engine, id_: UUID, day: str, hour: int) -> None:
    """Leaves the booking on [day] at [hour] club time."""
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE booking"
                " SET starts_at = x.starts_at, ends_at = x.starts_at + interval '1 hour'"
                " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :hora))"
                "       AT TIME ZONE 'America/Argentina/Buenos_Aires' AS starts_at) x"
                " WHERE id = :id"
            ),
            {"id": id_, "dia": day, "hora": hour},
        )


def _ids(api: TestClient, token: str, query: str) -> set[str]:
    r = api.get(f"/bookings/all?{query}", headers=_bearer(token))
    assert r.status_code == 200
    body: dict[str, Any] = r.json()
    return {x["id"] for x in body["bookings"]}


def test_the_filter_days_are_cut_at_the_club_time(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """at 21:00 and at 23:00 club time the booking falls on its day, not on the next one in UTC"""
    space = _new_space(api, admin_token, venue[0])
    at_21 = _book(api, user_token, space, day=1)["id"]
    at_23 = _book(api, user_token, space, day=2)["id"]
    _move_to(engine, UUID(at_21), "2031-09-10", 21)
    _move_to(engine, UUID(at_23), "2031-09-10", 23)
    base = f"q={venue[1]}"

    assert _ids(api, admin_token, f"{base}&since=2031-09-10&until=2031-09-10") == {
        at_21,
        at_23,
    }
    assert _ids(api, admin_token, f"{base}&since=2031-09-11&until=2031-09-11") == set()
    assert _ids(api, admin_token, f"{base}&since=2031-09-09&until=2031-09-09") == set()
    assert _ids(api, admin_token, f"{base}&until=2031-09-10") == {at_21, at_23}


def test_the_search_takes_wildcards_as_text(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """% and _ are not wildcards in the search @assumption:CU-14-SUP-02"""
    space = _new_space(api, admin_token, venue[0])
    booking = _book(api, user_token, space, day=1)["id"]
    name = venue[1]

    assert booking in _ids(api, admin_token, f"q={name}")
    assert _ids(api, admin_token, "q=%25") == set()
    assert _ids(api, admin_token, f"q={name[:5]}%25") == set()
    assert _ids(api, admin_token, f"q={name[:4]}_{name[5:]}") == set()
    assert _ids(api, admin_token, "q=%5C") == set()
