"""What `BookingsSql` decides inside `in_transaction`, against the real database."""

import uuid
from datetime import date, datetime, time, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.availability.rules import OpeningHours
from app.modules.bookings.repository import BookingsSql
from app.shared.errors import ConcurrentChange, OpeningHoursChanged, Unavailable

CLUB = ZoneInfo("America/Argentina/Buenos_Aires")


def _user(api: TestClient, engine: Engine, token: str) -> UUID:
    email = api.get("/me", headers={"Authorization": f"Bearer {token}"}).json()["email"]
    with engine.connect() as conn:
        row = conn.execute(text("SELECT id FROM app_user WHERE email = :c"), {"c": email})
        return UUID(str(row.scalar_one()))


def _court(api: TestClient, admin_token: str, venue_id: str) -> str:
    r = api.post(
        "/spaces",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"venue_id": venue_id, "sport": "Futbol", "kind": "F5", "covered": False,
              "lit": True, "price_per_hour": 38000},
    )  # fmt: skip
    return str(r.json()["id"])


def _at_hour(days: int, hour: int) -> datetime:
    return datetime.combine(date.today() + timedelta(days=days), time(hour), tzinfo=CLUB)


def _schedule(engine: Engine, space: UUID) -> OpeningHours:
    with engine.connect() as conn:
        schedule = BookingsSql(conn).opening_hours(space)
    assert schedule is not None
    return schedule


def _deactivate(engine: Engine, table: str, column: str, id_: UUID) -> None:
    with engine.begin() as conn:
        conn.execute(
            text(f"UPDATE {table} SET {column} = false, deactivated_at = now() WHERE id = :id"),
            {"id": id_},
        )


@pytest.fixture
def court(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> tuple[str, str, UUID]:
    """The venue, one of its courts and who books."""
    return venue[0], _court(api, admin_token, venue[0]), _user(api, engine, user_token)


def test_a_foreign_or_nonexistent_booking_is_not_found(
    engine: Engine, court: tuple[str, str, UUID]
) -> None:
    """a foreign or nonexistent booking is not found @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, space_api, me = court
    space = UUID(space_api)
    with engine.connect() as conn:
        booking = BookingsSql(conn).insert(
            me, space, _at_hour(1, 10), _at_hour(1, 11), _schedule(engine, space)
        )
        repository = BookingsSql(conn)

        assert repository.own(uuid.uuid4(), booking.id) is None
        assert repository.any_one(uuid.uuid4()) is None


def test_moving_with_the_old_venue_hours_changes_nothing(
    engine: Engine, court: tuple[str, str, UUID]
) -> None:
    """moving with the old venue hours changes nothing @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    venue_id, space_api, me = court
    space = UUID(space_api)
    old = _schedule(engine, space)
    with engine.connect() as conn:
        booking = BookingsSql(conn).insert(me, space, _at_hour(1, 10), _at_hour(1, 11), old)
    with engine.begin() as conn:
        conn.execute(text("UPDATE venue SET opens_at = '09:00' WHERE id = :s"), {"s": venue_id})

    with engine.connect() as conn, pytest.raises(OpeningHoursChanged):
        BookingsSql(conn).move(
            me,
            booking.id,
            (space, booking.starts_at),
            space,
            _at_hour(1, 12),
            _at_hour(1, 13),
            old,
        )


def test_a_cancelled_booking_is_not_moved(engine: Engine, court: tuple[str, str, UUID]) -> None:
    """a cancelled booking is not moved @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    _, space_api, me = court
    space = UUID(space_api)
    schedule = _schedule(engine, space)
    with engine.connect() as conn:
        booking = BookingsSql(conn).insert(me, space, _at_hour(1, 10), _at_hour(1, 11), schedule)
        BookingsSql(conn).cancel(me, booking.id)

    with engine.connect() as conn, pytest.raises(ConcurrentChange):
        BookingsSql(conn).move(
            me,
            booking.id,
            (space, booking.starts_at),
            space,
            _at_hour(1, 12),
            _at_hour(1, 13),
            schedule,
        )


@pytest.mark.parametrize("deactivated", ["venue", "space"])
def test_no_booking_or_moving_to_a_deactivated_court(
    engine: Engine, court: tuple[str, str, UUID], deactivated: str
) -> None:
    """no booking or moving to a court whose venue or the court itself is deactivated
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    venue_id, space_api, me = court
    space = UUID(space_api)
    schedule = _schedule(engine, space)
    with engine.connect() as conn:
        booking = BookingsSql(conn).insert(me, space, _at_hour(1, 10), _at_hour(1, 11), schedule)
    if deactivated == "venue":
        _deactivate(engine, "venue", "active", UUID(venue_id))
    else:
        _deactivate(engine, "space", "active", space)

    with engine.connect() as conn:
        with pytest.raises(Unavailable):
            BookingsSql(conn).insert(me, space, _at_hour(2, 10), _at_hour(2, 11), schedule)
        with pytest.raises(Unavailable):
            BookingsSql(conn).move(
                me,
                booking.id,
                (space, booking.starts_at),
                space,
                _at_hour(1, 12),
                _at_hour(1, 13),
                schedule,
            )  # fmt: skip
