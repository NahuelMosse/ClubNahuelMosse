from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")


def test_the_backend_rejects_a_new_time_in_the_past_or_ending_after_closing(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """the backend rejects a new time in the past or ending after closing @CU-11-H01-03"""
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
            "password": "ClubNahuel1",
        },
    )
    assert signup.status_code == 201
    with engine.begin() as conn:
        space: Any = conn.execute(
            text(
                "WITH s AS (INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id)"
                " INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id"
            ),
            {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1"},
        ).scalar_one()
    token = sign_in(email, "ClubNahuel1")
    session = {"Authorization": f"Bearer {token}"}
    tomorrow = datetime.now(ZONE).date() + timedelta(days=1)
    booking = api.post(
        "/bookings",
        headers=session,
        json={
            "space_id": str(space),
            "date": tomorrow.isoformat(),
            "start_hour": "21:00",
            "hours": 1,
        },
    ).json()

    yesterday = api.post(
        f"/bookings/{booking['id']}/modify",
        headers=session,
        json={
            "space_id": str(space),
            "date": (tomorrow - timedelta(days=2)).isoformat(),
            "start_hour": "10:00",
        },
    )
    late = api.post(
        f"/bookings/{booking['id']}/modify",
        headers=session,
        json={"space_id": str(space), "date": tomorrow.isoformat(), "start_hour": "23:00"},
    )

    # Checks: both changes are rejected by their rule.
    assert yesterday.status_code == 422
    assert yesterday.json()["errors"]["date"] == "The date must be in the future"
    assert late.status_code == 422
    assert late.json()["errors"]["until"] == "The venue closes at 23:00"
    # Checks: the booking stays at its time.
    with engine.connect() as conn:
        start: Any = conn.execute(
            text("SELECT starts_at FROM booking WHERE id = :id"), {"id": booking["id"]}
        ).scalar_one()
    assert start.astimezone(ZONE).hour == 21
