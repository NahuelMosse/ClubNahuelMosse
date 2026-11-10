from collections.abc import Callable
from datetime import date, datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")


@pytest.fixture
def court(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> tuple[dict[str, str], str]:
    """A user account and a Football 5 court in a venue open 08:00 to 23:00 every day."""
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
    assert token is not None
    return {"Authorization": f"Bearer {token}"}, str(space)


def _tomorrow() -> date:
    return datetime.now(ZONE).date() + timedelta(days=1)


def _bookings(engine: Engine, space: str) -> int:
    with engine.connect() as conn:
        return int(
            conn.execute(
                text("SELECT count(*) FROM booking WHERE space_id = :e"), {"e": space}
            ).scalar_one()
        )


def test_the_backend_rejects_a_booking_in_a_past_time_slot(
    api: TestClient, engine: Engine, court: tuple[dict[str, str], str]
) -> None:
    """the backend rejects a booking in a past time slot @CU-09-H01-04"""
    session, space = court
    yesterday = datetime.now(ZONE).date() - timedelta(days=1)

    r = api.post(
        "/bookings",
        headers=session,
        json={"space_id": space, "date": yesterday.isoformat(), "start_hour": "10:00", "hours": 1},
    )

    # Verifies: it rejects it because of the date and saves nothing.
    assert r.status_code == 422
    assert r.json()["errors"]["date"] == "The date must be in the future"
    assert _bookings(engine, space) == 0


def test_the_backend_rejects_a_booking_that_ends_after_the_venue_closes(
    api: TestClient, engine: Engine, court: tuple[dict[str, str], str]
) -> None:
    """the backend rejects a booking that ends after the venue closes @CU-09-H01-05"""
    session, space = court

    r = api.post(
        "/bookings",
        headers=session,
        json={
            "space_id": space,
            "date": _tomorrow().isoformat(),
            "start_hour": "22:00",
            "hours": 2,
        },
    )

    # Verifies: it rejects it because of the closing time and saves nothing.
    assert r.status_code == 422
    assert r.json()["errors"]["until"] == "The venue closes at 23:00"
    assert _bookings(engine, space) == 0


def test_the_backend_rejects_a_booking_that_does_not_start_or_end_on_the_hour(
    api: TestClient, engine: Engine, court: tuple[dict[str, str], str]
) -> None:
    """the backend rejects a booking that does not start or end on the hour @CU-09-H01-06"""
    session, space = court

    r = api.post(
        "/bookings",
        headers=session,
        json={
            "space_id": space,
            "date": _tomorrow().isoformat(),
            "start_hour": "18:30",
            "hours": 1,
        },
    )

    # Verifies: it rejects it because of the time and saves nothing.
    assert r.status_code == 422
    assert r.json()["errors"]["start_hour"] == "Choose an on-the-hour time"
    assert _bookings(engine, space) == 0


def test_the_backend_rejects_a_booking_of_less_than_one_hour(
    api: TestClient, engine: Engine, court: tuple[dict[str, str], str]
) -> None:
    """the backend rejects a booking of less than one hour @CU-09-H01-08"""
    session, space = court

    r = api.post(
        "/bookings",
        headers=session,
        json={
            "space_id": space,
            "date": _tomorrow().isoformat(),
            "start_hour": "18:00",
            "hours": 0,
        },
    )

    # Verifies: it rejects it because of the duration and saves nothing.
    assert r.status_code == 422
    assert r.json()["errors"]["until"] == "The minimum duration is one hour"
    assert _bookings(engine, space) == 0


def test_the_backend_rejects_a_booking_that_partly_overlaps_another_of_the_same_space(
    api: TestClient, engine: Engine, court: tuple[dict[str, str], str]
) -> None:
    """the backend rejects a booking that partly overlaps another of the same space @CU-09-H02-02"""
    session, space = court
    tomorrow = _tomorrow().isoformat()
    first = api.post(
        "/bookings",
        headers=session,
        json={"space_id": space, "date": tomorrow, "start_hour": "18:00", "hours": 2},
    )
    assert first.status_code == 201

    r = api.post(
        "/bookings",
        headers=session,
        json={"space_id": space, "date": tomorrow, "start_hour": "19:00", "hours": 2},
    )

    # Verifies: the second one collides with the first and only one remains.
    assert r.status_code == 409
    assert r.json()["errors"]["slot"] == "That slot was taken"
    assert _bookings(engine, space) == 1
