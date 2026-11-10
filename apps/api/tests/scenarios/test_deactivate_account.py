from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")


def _next_hour(days: int) -> datetime:
    now = datetime.now(ZONE).replace(minute=0, second=0, microsecond=0)
    return now + timedelta(days=days, hours=1)


def test_deleting_the_account_frees_the_time_slot_of_its_current_booking(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """when the account is deleted, the time slot of its current booking becomes available again @CU-07-H01-02"""
    s = unique()
    email = f"socia.{s}@correo.com"
    assert (
        api.post(
            "/register",
            json={
                "first_name": "Lucía",
                "last_name": "Gómez",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
                "birth_date": "1998-11-02",
                "email": email,
                "password": "ClubNahuel1",
            },
        ).status_code
        == 201
    )
    start = _next_hour(days=2)
    with engine.begin() as conn:
        user: Any = conn.execute(
            text("SELECT id FROM app_user WHERE email = :c"), {"c": email}
        ).scalar_one()
        venue: Any = conn.execute(
            text(
                "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Rivadavia', 19850, '08:00', '00:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede {s}"},
        ).scalar_one()
        space: Any = conn.execute(
            text(
                "INSERT INTO space (venue_id, sport, kind, number, name, price_per_hour,"
                " covered, lit) VALUES (:venue, 'Futbol', 'F5', 1, :name, 38000, false,"
                " true) RETURNING id"
            ),
            {"venue": venue, "name": f"Moron_Rivadavia_19850_Futbol_F5_1_{s}"},
        ).scalar_one()
        booking: Any = conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
            ),
            {"u": user, "e": space, "i": start, "f": start + timedelta(hours=1)},
        ).scalar_one()

    token = sign_in(email, "ClubNahuel1")
    assert api.delete("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 204

    with engine.begin() as conn:
        status, canceled_by = conn.execute(
            text("SELECT status, canceled_by FROM booking WHERE id = :r"), {"r": booking}
        ).one()
        # Verifies: the booking ends up cancelled by the person who deleted their account, with a trace.
        assert (status, canceled_by) == ("canceled", user)
        # Verifies: the same time slot of the same space can be booked again; if it were still
        # taken, the database would reject it for overlap.
        other: Any = conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
            ),
            {"u": user, "e": space, "i": start, "f": start + timedelta(hours=1)},
        ).scalar_one()
        assert other != booking
