"""Schema constraints that no scenario of the card covers."""

import uuid
from collections.abc import Callable
from datetime import datetime, timedelta, timezone
from typing import Any

import pytest
from sqlalchemy import Connection, text
from sqlalchemy.exc import DBAPIError

AR = timezone(timedelta(hours=-3))


def _user(db: Connection, email: str | None = None, dni: str | None = None) -> uuid.UUID:
    s = uuid.uuid4().hex[:8]
    return db.execute(
        text(
            "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni, birth_date)"
            " VALUES (:uid, :email, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {
            "uid": f"uid-{s}",
            "email": email or f"{s}@correo.com",
            "dni": dni or str(int(s, 16) % 90_000_000 + 10_000_000),
        },
    ).scalar_one()


def _venue(
    db: Connection, opening: str = "08:00", closing: str = "23:00", days: str = "{1,2,3}"
) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
            " VALUES ('Sede X', 'Av. X', 1, :a, :c, CAST(:d AS smallint[])) RETURNING id"
        ),
        {"a": opening, "c": closing, "d": days},
    ).scalar_one()


def _space(db: Connection) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO space (venue_id, sport, kind, number, name, covered, lit,"
            " price_per_hour) VALUES (:s, 'Futbol', 'F5', 1, :n, false, true, 38000) RETURNING id"
        ),
        {"s": _venue(db), "n": f"X_{uuid.uuid4().hex[:8]}"},
    ).scalar_one()


def _fails(db: Connection, sql: str, params: dict[str, object] | None = None) -> None:
    with pytest.raises(DBAPIError), db.begin_nested():
        db.execute(text(sql), params or {})


def test_the_full_hour_does_not_depend_on_the_session_time_zone(db: Connection) -> None:
    uid, eid = _user(db), _space(db)
    db.execute(text("SET LOCAL TimeZone = 'Asia/Kolkata'"))
    start = datetime(2030, 11, 14, 18, 30, tzinfo=AR)
    _fails(
        db,
        "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
        " VALUES (:u, :e, :i, :f, 38000, 38000)",
        {"u": uid, "e": eid, "i": start, "f": start + timedelta(hours=1)},
    )


def test_the_total_is_the_price_times_the_hours(db: Connection) -> None:
    uid, eid = _user(db), _space(db)
    start = datetime(2030, 11, 14, 18, tzinfo=AR)
    _fails(
        db,
        "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
        " VALUES (:u, :e, :i, :f, 38000, 38000)",
        {"u": uid, "e": eid, "i": start, "f": start + timedelta(hours=2)},
    )


def test_voiding_requires_a_reason(db: Connection) -> None:
    uid, eid = _user(db), _space(db)
    start = datetime(2030, 11, 14, 18, tzinfo=AR)
    rid: Any = db.execute(
        text(
            "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
            " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
        ),
        {"u": uid, "e": eid, "i": start, "f": start + timedelta(hours=1)},
    ).scalar_one()
    _fails(db, "UPDATE booking SET status = 'voided' WHERE id = :id", {"id": rid})


def test_a_venue_can_close_at_midnight(db: Connection) -> None:
    _venue(db, "18:00", "00:00")
    _fails(
        db,
        "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
        " VALUES ('S', 'C', 1, '22:00', '08:00', '{1}')",
    )


@pytest.mark.parametrize("days", ["{{1,2},{3,4}}", "{}", "{0}", "{8}"])
def test_the_days_are_a_list_of_one_to_seven(db: Connection, days: str) -> None:
    _fails(
        db,
        "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
        " VALUES ('S', 'C', 1, '08:00', '23:00', CAST(:d AS smallint[]))",
        {"d": days},
    )


@pytest.mark.parametrize("table", ["app_user", "venue", "space"])
def test_nothing_is_deleted(db: Connection, table: str) -> None:
    ids: dict[str, Callable[[Connection], uuid.UUID]] = {
        "app_user": _user,
        "venue": _venue,
        "space": _space,
    }
    row = ids[table](db)
    _fails(db, f"DELETE FROM {table} WHERE id = :id", {"id": row})


def test_the_space_name_does_not_change(db: Connection) -> None:
    eid = _space(db)
    _fails(db, "UPDATE space SET name = 'Otro' WHERE id = :id", {"id": eid})
    _fails(db, "UPDATE space SET number = 9 WHERE id = :id", {"id": eid})
    db.execute(text("UPDATE space SET price_per_hour = 40000 WHERE id = :id"), {"id": eid})


def test_created_at_does_not_change_and_updated_at_is_refreshed(db: Connection) -> None:
    uid = _user(db)
    before = db.execute(
        text("SELECT created_at, updated_at FROM app_user WHERE id = :id"), {"id": uid}
    ).one()
    db.execute(text("SELECT pg_sleep(0.01)"))
    db.execute(
        text("UPDATE app_user SET first_name = 'Eva', created_at = '2001-01-01' WHERE id = :id"),
        {"id": uid},
    )
    after = db.execute(
        text("SELECT created_at, updated_at FROM app_user WHERE id = :id"), {"id": uid}
    ).one()
    assert after.created_at == before.created_at
    assert after.updated_at > before.updated_at


def test_active_and_deactivation_date_go_together(db: Connection) -> None:
    uid = _user(db)
    _fails(db, "UPDATE app_user SET active = false WHERE id = :id", {"id": uid})
