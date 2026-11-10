"""The data model fixed by the brief, checked against the real database."""

import uuid
from datetime import date, datetime, time, timedelta, timezone

import pytest
from sqlalchemy import Connection, text
from sqlalchemy.exc import DBAPIError, IntegrityError

AR = timezone(timedelta(hours=-3))


def _unique() -> str:
    return uuid.uuid4().hex[:8]


def _user(db: Connection, suffix: str) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni, birth_date)"
            " VALUES (:uid, :email, 'Ana', 'Pérez', :dni, '2000-03-14') RETURNING id"
        ),
        {
            "uid": f"uid-{suffix}",
            "email": f"ana.{suffix}@correo.com",
            "dni": str(int(suffix, 16) % 90_000_000 + 10_000_000),
        },
    ).scalar_one()


def _venue(db: Connection, suffix: str) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
            " VALUES (:name, 'Av. Rivadavia', 19850, '08:00', '23:00', '{1,2,3,4,5,6,7}') RETURNING id"
        ),
        {"name": f"Sede Prueba {suffix}"},
    ).scalar_one()


def _space(db: Connection, venue_id: uuid.UUID, suffix: str, number: int = 1) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO space (venue_id, sport, kind, number, name, covered, lit, price_per_hour)"
            " VALUES (:venue, 'Futbol', 'F5', :number, :name, false, true, 38000) RETURNING id"
        ),
        {
            "venue": venue_id,
            "number": number,
            "name": f"Prueba{suffix}_Rivadavia_19850_Futbol_F5_{number}",
        },
    ).scalar_one()


def _booking(
    db: Connection, user_id: uuid.UUID, space_id: uuid.UUID, start: datetime, hours: int = 1
) -> uuid.UUID:
    return db.execute(
        text(
            "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
            " VALUES (:u, :e, :starts_at, :ends_at, 38000, :total) RETURNING id"
        ),
        {
            "u": user_id,
            "e": space_id,
            "starts_at": start,
            "ends_at": start + timedelta(hours=hours),
            "total": 38000 * hours,
        },
    ).scalar_one()


def test_the_user_is_stored_with_their_data_and_the_email_does_not_change(db: Connection) -> None:
    """the user is stored with email, first name, last name and birth date, and the email does not change @MOD-01-H01-01

    Checks: the four minimum profile fields are stored and the sign-up date is stamped by itself.
    If it fails, a profile is left incomplete or an email is rewritten and the account changes hands.
    """
    suffix = _unique()
    uid = _user(db, suffix)
    row = db.execute(
        text(
            "SELECT email, first_name, last_name, birth_date, created_at FROM app_user WHERE id = :id"
        ),
        {"id": uid},
    ).one()
    assert row.email == f"ana.{suffix}@correo.com"
    assert (row.first_name, row.last_name, row.birth_date) == (
        "Ana",
        "Pérez",
        date(2000, 3, 14),
    )
    assert row.created_at is not None

    with pytest.raises(DBAPIError, match="email"):
        with db.begin_nested():
            db.execute(
                text("UPDATE app_user SET email = 'otro@correo.com' WHERE id = :id"), {"id": uid}
            )


def test_the_venue_is_stored_with_name_address_and_hours(db: Connection) -> None:
    """a venue is stored with name, address and opening hours @MOD-01-H01-02

    Checks: the venue stores name, street and number, opening, closing and the days it opens.
    If it fails, bookings have no hours to be validated against.
    """
    suffix = _unique()
    sid = _venue(db, suffix)
    row = db.execute(
        text(
            "SELECT name, street, street_number, opens_at, closes_at, open_days, active FROM venue WHERE id = :id"
        ),
        {"id": sid},
    ).one()
    assert row.name == f"Sede Prueba {suffix}"
    assert (row.street, row.street_number) == ("Av. Rivadavia", 19850)
    assert (row.opens_at, row.closes_at) == (time(8), time(23))
    assert list(row.open_days) == [1, 2, 3, 4, 5, 6, 7]
    assert row.active is True


def test_the_space_belongs_to_a_venue_and_has_a_composite_name(db: Connection) -> None:
    """a space is stored tied to a venue, with a kind and a name made of venue, address, kind and number @MOD-01-H01-03

    Checks: the name comes from the venue, the street without its prefix, the number, the sport, the
    kind and the space number, without accents or spaces, as in the prototype; and there are no two
    spaces with the same number of the same kind in a venue. If it fails, two courts get mixed up in
    a booking.
    """
    from app.modules.spaces.rules import composite_name

    assert composite_name("Sede Morón", "Av. Rivadavia", 19850, "Fútbol", "F5", 1) == (
        "Moron_Rivadavia_19850_Futbol_F5_1"
    )
    assert composite_name("Sede Ramos Mejía", "Calle Belgrano", 1240, "Hockey", "H7", 1) == (
        "RamosMejia_Belgrano_1240_Hockey_H7_1"
    )
    assert composite_name("Sede San Justo", "Av. Casanova", 320, "Golf", "CORTO", 2) == (
        "SanJusto_Casanova_320_Golf_CORTO_2"
    )

    suffix = _unique()
    sid = _venue(db, suffix)
    eid = _space(db, sid, suffix)
    row = db.execute(
        text("SELECT venue_id, kind, name FROM space WHERE id = :id"), {"id": eid}
    ).one()
    assert (row.venue_id, row.kind) == (sid, "F5")
    assert row.name == f"Prueba{suffix}_Rivadavia_19850_Futbol_F5_1"

    with pytest.raises(IntegrityError):
        with db.begin_nested():
            _space(db, sid, suffix)


def test_the_booking_has_user_space_date_start_and_end(db: Connection) -> None:
    """a booking is stored with user, space, date, start time and end time @MOD-01-H01-04

    Checks: the booking stores whose it is, which space, when it starts and ends, and the price of
    the moment. If it fails, what was booked cannot be listed or charged.
    """
    suffix = _unique()
    uid = _user(db, suffix)
    eid = _space(db, _venue(db, suffix), suffix)
    start = datetime(2030, 11, 14, 18, tzinfo=AR)
    rid = _booking(db, uid, eid, start, hours=2)
    row = db.execute(
        text(
            "SELECT user_id, space_id, starts_at, ends_at, price_per_hour, total, status, created_at FROM booking WHERE id = :id"
        ),
        {"id": rid},
    ).one()
    assert (row.user_id, row.space_id) == (uid, eid)
    assert row.starts_at == start and row.ends_at == start + timedelta(hours=2)
    assert (row.price_per_hour, row.total) == (38000, 76000)
    assert row.status == "active"
    assert row.created_at is not None


def test_the_database_rejects_two_overlapping_bookings_of_the_same_space(db: Connection) -> None:
    """the database rejects two overlapping bookings of the same space on the same date @MOD-01-H01-05

    Checks: a booking that partly overlaps another active one of the same space does not go in, one
    right after it does, and a canceled one frees the slot. If it fails, two people arrive at the
    same court at the same time.
    """
    suffix = _unique()
    uid = _user(db, suffix)
    eid = _space(db, _venue(db, suffix), suffix)
    start = datetime(2030, 11, 14, 18, tzinfo=AR)
    first = _booking(db, uid, eid, start, hours=2)

    with pytest.raises(IntegrityError):
        with db.begin_nested():
            _booking(db, uid, eid, start + timedelta(hours=1))

    _booking(db, uid, eid, start + timedelta(hours=2))

    db.execute(text("UPDATE booking SET status = 'canceled' WHERE id = :id"), {"id": first})
    _booking(db, uid, eid, start + timedelta(hours=1))


def test_a_finished_booking_still_exists(db: Connection) -> None:
    """a finished booking still exists and appears in the history @MOD-01-H01-06

    Checks: a booking whose time has already passed is kept and listed among the user's, with the
    status completed. If it fails, the history loses what was already played.
    """
    suffix = _unique()
    uid = _user(db, suffix)
    eid = _space(db, _venue(db, suffix), suffix)
    start = datetime.now(AR).replace(minute=0, second=0, microsecond=0) - timedelta(days=3)
    rid = _booking(db, uid, eid, start)
    rows = db.execute(
        text("SELECT id, current_status FROM booking_with_status WHERE user_id = :u"), {"u": uid}
    ).all()
    assert [(r.id, r.current_status) for r in rows] == [(rid, "completed")]
