import uuid
from uuid import UUID
from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from sqlalchemy import Engine, create_engine, text

from app.modules.bookings.repository import BookingsSql
from app.modules.spaces.repository import SpacesSql
from app.modules.users.repository import UsersSql
from app.modules.venues.repository import VenuesSql


def _hour(days: int = 0, minutes: int = 0) -> datetime:
    base = datetime.now(UTC).replace(minute=0, second=0, microsecond=0)
    return base + timedelta(days=days, minutes=minutes)


def _world(engine: Engine) -> dict[str, UUID]:
    """One account, one venue with a space, everything committed in the database."""
    s = uuid.uuid4().hex[:8]
    with engine.begin() as conn:
        user = conn.execute(
            text(
                "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni,"
                " birth_date) VALUES (:uid, :email, 'Ana', 'Pérez', :dni, '2000-03-14')"
                " RETURNING id"
            ),
            {
                "uid": f"uid-{s}",
                "email": f"ana.{s}@correo.com",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            },
        ).scalar_one()
        venue = conn.execute(
            text(
                "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Rivadavia', 19850, '08:00', '23:00',"
                " '{1,2,3,4,5,6,7}') RETURNING id"
            ),
            {"n": f"Sede Propia {s}"},
        ).scalar_one()
        space = conn.execute(
            text(
                "INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour) VALUES (:venue, 'Futbol', 'F5', 1, :n, false,"
                " true, 38000) RETURNING id"
            ),
            {"venue": venue, "n": f"Propia{s}_Rivadavia_19850_Futbol_F5_1"},
        ).scalar_one()
    return {"user": user, "venue": venue, "space": space}


def _booking(
    engine: Engine, world: dict[str, UUID], start: datetime, created: datetime | None = None
) -> UUID:
    with engine.begin() as conn:
        return conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                " total, created_at, updated_at) VALUES (:u, :e, :i, :f, 38000, 38000,"
                " coalesce(:c, now()), coalesce(:c, now())) RETURNING id"
            ),
            {
                "u": world["user"],
                "e": world["space"],
                "i": start,
                "f": start + timedelta(hours=1),
                "c": created,
            },
        ).scalar_one()


def _one(engine: Engine, sql: str, **data: Any) -> Any:
    with engine.connect() as conn:
        return conn.execute(text(sql), data).scalar_one()


def test_account_deactivation_cancels_future_bookings(engine: Engine) -> None:
    """deactivating an account still cancels its future bookings @REV-06-S6 @assumption:REV-06-ASM-05"""
    world = _world(engine)
    booking = _booking(engine, world, _hour(days=3))
    with engine.connect() as conn:
        assert UsersSql(conn).deactivate(world["user"]) is True
    assert _one(engine, "SELECT status FROM booking WHERE id = :i", i=booking) == "canceled"
    assert not _one(engine, "SELECT active FROM app_user WHERE id = :i", i=world["user"])


def test_canceling_a_booking_leaves_its_notice(engine: Engine) -> None:
    """canceling a booking still leaves its notice @REV-06-S6 @assumption:REV-06-ASM-05"""
    world = _world(engine)
    booking = _booking(engine, world, _hour(days=3))
    with engine.connect() as conn:
        BookingsSql(conn).cancel(world["user"], booking)
    assert (
        _one(
            engine,
            "SELECT count(*) FROM notification WHERE booking_id = :i"
            " AND kind = 'user_cancellation'",
            i=booking,
        )
        == 1
    )


def test_venue_deactivation_deactivates_its_spaces(engine: Engine) -> None:
    """deactivating a venue still deactivates its spaces @REV-06-S6 @assumption:REV-06-ASM-05"""
    world = _world(engine)
    with engine.connect() as conn:
        VenuesSql(conn).deactivate(world["venue"], world["user"])
    assert not _one(engine, "SELECT active FROM venue WHERE id = :i", i=world["venue"])
    assert not _one(engine, "SELECT active FROM space WHERE id = :i", i=world["space"])


def test_venue_deactivation_survives_a_restart(engine: Engine) -> None:
    """the deactivation of a venue and its spaces survives the restart of the app on the same database @REV-06-S6 @assumption:REV-06-ASM-05"""
    world = _world(engine)
    with engine.connect() as conn:
        VenuesSql(conn).deactivate(world["venue"], world["user"])
    fresh = create_engine(engine.url)
    try:
        assert not _one(fresh, "SELECT active FROM venue WHERE id = :i", i=world["venue"])
        assert not _one(fresh, "SELECT active FROM space WHERE id = :i", i=world["space"])
    finally:
        fresh.dispose()


def test_if_venue_deactivation_fails_nothing_is_left(
    engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """if the deactivation of a venue fails halfway, neither the venue deactivated nor its spaces are left @REV-06-S6 @assumption:REV-06-ASM-11"""
    world = _world(engine)
    original = SpacesSql.deactivate_venue_spaces

    def writes_and_fails(self: SpacesSql, venue_id: UUID, author: UUID) -> None:
        original(self, venue_id, author)
        raise RuntimeError("fails after writing the spaces")

    monkeypatch.setattr(SpacesSql, "deactivate_venue_spaces", writes_and_fails)
    with engine.connect() as conn, pytest.raises(RuntimeError):
        VenuesSql(conn).deactivate(world["venue"], world["user"])
    assert _one(engine, "SELECT active FROM venue WHERE id = :i", i=world["venue"])
    assert _one(engine, "SELECT active FROM space WHERE id = :i", i=world["space"])
