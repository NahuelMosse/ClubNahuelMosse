"""SIM-02 against the real database and emulator: the readable API does the same."""

from datetime import date, timedelta
from typing import Any

from fastapi.testclient import TestClient


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


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
    assert r.status_code == 201, r.text
    return str(r.json()["id"])


def _payload(space: str, day: int, hour: int) -> dict[str, Any]:
    return {
        "space_id": space,
        "date": (date.today() + timedelta(days=day)).isoformat(),
        "start_hour": f"{hour:02d}:00",
        "hours": 1,
    }


def test_a_made_and_moved_booking_survives_restarting_the_api(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """a made and moved booking survives restarting the API on the same database @SIM-02-S1"""
    from app.main import create_app

    space = _space(api, admin_token, venue[0])
    r = api.post("/bookings", headers=_bearer(user_token), json=_payload(space, 1, 10))
    assert r.status_code == 201, r.text
    created = r.json()["id"]
    new = _payload(space, 2, 11)
    new.pop("hours")
    moved = api.post(f"/bookings/{created}/modify", headers=_bearer(user_token), json=new)
    assert moved.status_code == 200, moved.text

    with TestClient(create_app()) as other:
        r = other.get("/bookings", headers=_bearer(user_token))
    read = next(x for x in r.json()["bookings"] if x["id"] == created)
    assert read["starts_at"] == moved.json()["starts_at"]
    assert read["total"] == moved.json()["total"]
