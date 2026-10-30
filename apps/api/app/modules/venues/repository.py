# kit-shape: the venue repository and the functions that build its entity go together
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Row, text
from sqlalchemy.exc import IntegrityError

from app.modules.spaces import SpacesSql
from app.modules.venues.rules import NewVenue, Venue
from app.shared.club_timezone import CLUB_TIMEZONE_NAME
from app.shared.db import DbConnection, in_transaction, violated_constraint
from app.shared.errors import BookingsOutsideHours, Duplicate, HasFutureBookings, NotFound

_COLUMNS = "v.id, v.name, v.street, v.street_number, v.opens_at, v.closes_at, v.open_days"


def _venue(row: Any, space_count: int, sports: tuple[str, ...] = ()) -> Venue:
    return Venue(
        id=row.id,
        name=row.name,
        street=row.street,
        street_number=int(row.street_number),
        opens_at=row.opens_at,
        closes_at=row.closes_at,
        open_days=tuple(int(d) for d in row.open_days),
        space_count=space_count,
        sports=sports,
    )


# A booking falls outside a schedule if it starts before opening, ends after closing (at
# 00:00 it is midnight) or falls on a day the venue is closed, counted in the club's time.
_OUTSIDE = (
    "(({start})::time < CAST(:{p}opens_at AS time)"
    " OR ({end}) - date_trunc('day', {start}) > CASE WHEN CAST(:{p}closes_at AS time) = '00:00'"
    " THEN interval '24 hours' ELSE CAST(:{p}closes_at AS time) - time '00:00' END"
    " OR extract(isodow FROM {start})::smallint <> ALL (CAST(:{p}open_days AS smallint[])))"
)


def _outside(prefix: str) -> str:
    return _OUTSIDE.format(
        start=f"b.starts_at AT TIME ZONE '{CLUB_TIMEZONE_NAME}'",
        end=f"b.ends_at AT TIME ZONE '{CLUB_TIMEZONE_NAME}'",
        p=prefix,
    )


class VenuesSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def active(self) -> list[Venue]:
        rows = self._conn.execute(
            text(
                f"SELECT {_COLUMNS}, count(e.id) AS space_count,"
                " coalesce(array_agg(DISTINCT e.sport ORDER BY e.sport)"
                " FILTER (WHERE e.id IS NOT NULL), '{}') AS sports FROM venue v"
                " LEFT JOIN space e ON e.venue_id = v.id AND e.active"
                " WHERE v.active GROUP BY v.id ORDER BY lower(v.name), v.id"
            )
        ).all()
        self._conn.rollback()
        return [_venue(r, int(r.space_count), tuple(r.sports)) for r in rows]

    def insert(self, new: NewVenue, author: UUID) -> Venue:
        try:
            with in_transaction(self._conn):
                row = self._conn.execute(
                    text(
                        "INSERT INTO venue AS v (name, street, street_number, opens_at,"
                        " closes_at, open_days, created_by, updated_by)"
                        " VALUES (:name, :street, :street_number, :opens_at, :closes_at,"
                        " CAST(:open_days AS smallint[]), :author, :author)"
                        f" RETURNING {_COLUMNS}"
                    ),
                    {
                        "name": new.name,
                        "street": new.street,
                        "street_number": new.street_number,
                        "opens_at": new.opens_at,
                        "closes_at": new.closes_at,
                        "open_days": list(new.open_days),
                        "author": author,
                    },
                ).one()
        except IntegrityError as e:
            constraint = violated_constraint(e)
            if constraint == "venue_name_active_unique":
                raise Duplicate(["name"]) from e
            raise
        return _venue(row, space_count=0)

    def _check_bookings(self, values: dict[str, Any], before: Row[Any]) -> None:
        outside = int(
            self._conn.execute(
                text(
                    "SELECT count(*) FROM booking b"
                    " JOIN space e ON e.id = b.space_id"
                    " WHERE e.venue_id = :id AND b.status = :active_status"
                    " AND b.starts_at > now()"
                    f" AND {_outside('')} AND NOT {_outside('before_')}"
                ),
                values
                | {
                    "active_status": "active",
                    "before_opens_at": before.opens_at,
                    "before_closes_at": before.closes_at,
                    "before_open_days": list(before.open_days),
                },
            ).scalar_one()
        )
        if outside:
            raise BookingsOutsideHours(outside)

    def _save(self, values: dict[str, Any]) -> None:
        self._conn.execute(
            text(
                "UPDATE venue SET name = :name, street = :street,"
                " street_number = :street_number, opens_at = :opens_at, closes_at = :closes_at,"
                " open_days = CAST(:open_days AS smallint[]),"
                " updated_by = :author, updated_at = now() WHERE id = :id"
            ),
            values,
        )

    def update(self, venue_id: UUID, data: NewVenue, author: UUID, *, confirm: bool) -> Venue:
        values = {
            "id": venue_id,
            "name": data.name,
            "street": data.street,
            "street_number": data.street_number,
            "opens_at": data.opens_at,
            "closes_at": data.closes_at,
            "open_days": list(data.open_days),
            "author": author,
        }
        try:
            with in_transaction(self._conn):
                # Exclusive: a booking being made at the venue finishes first, or waits for the
                # new schedule and is validated again with it.
                before = self._conn.execute(
                    text(
                        "SELECT opens_at, closes_at, open_days FROM venue"
                        " WHERE id = :id AND active FOR UPDATE"
                    ),
                    values,
                ).first()
                if before is None:
                    raise NotFound("la sede ya no está activa")
                if not confirm:
                    self._check_bookings(values, before)
                self._save(values)
        except IntegrityError as e:
            constraint = violated_constraint(e)
            if constraint == "venue_name_active_unique":
                raise Duplicate(["name"]) from e
            raise
        saved = next((s for s in self.active() if s.id == venue_id), None)
        if saved is None:
            raise NotFound("la sede se dio de baja apenas se guardó")
        return saved

    def deactivate(self, venue_id: UUID, author: UUID) -> None:
        params = {"id": venue_id, "author": author}
        with in_transaction(self._conn):
            # Exclusive: a booking being made at the venue finishes first and is seen here, or
            # waits and finds the venue deactivated.
            if (
                self._conn.execute(
                    text("SELECT 1 FROM venue WHERE id = :id AND active FOR UPDATE"),
                    {"id": venue_id},
                ).first()
                is None
            ):
                raise NotFound("la sede ya no está activa")
            pending: int = self._conn.execute(
                text(
                    "SELECT count(*) FROM booking b JOIN space e ON e.id = b.space_id"
                    " WHERE e.venue_id = :id AND b.status = :active_status AND b.ends_at > now()"
                ),
                {"id": venue_id, "active_status": "active"},
            ).scalar_one()
            if pending:
                raise HasFutureBookings("la sede tiene reservas que todavía no terminaron")
            SpacesSql(self._conn).deactivate_venue_spaces(venue_id, author)
            self._conn.execute(
                text(
                    "UPDATE venue SET active = false, deactivated_at = now(),"
                    " deactivated_by = :author, updated_by = :author, updated_at = now()"
                    " WHERE id = :id"
                ),
                params,
            )


def venue_repository(conn: DbConnection) -> VenuesSql:
    return VenuesSql(conn)
