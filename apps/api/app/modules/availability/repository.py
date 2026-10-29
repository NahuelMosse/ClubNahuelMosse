# kit-shape: the availability repository and the functions that build its opening hours go together
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.modules.availability.rules import OpeningHours
from app.modules.spaces import SPACE_COLUMNS, Space, space_of_row
from app.shared.db import DbConnection
from app.shared.stored_values import stored


def opening_hours_of_row(row: Any) -> OpeningHours:
    """The days go in a tuple: the opening hours are compared with `!=` against another to
    know whether they changed."""
    return OpeningHours(
        opens_at=row.opens_at,
        closes_at=row.closes_at,
        open_days=tuple(int(d) for d in row.open_days),
    )


class AvailabilitySql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def opening_hours(self, space_id: UUID) -> OpeningHours | None:
        row = self._conn.execute(
            text(
                "SELECT s.opens_at, s.closes_at, s.open_days FROM space e"
                " JOIN venue s ON s.id = e.venue_id"
                " WHERE e.id = :id AND e.active AND s.active"
            ),
            {"id": space_id},
        ).one_or_none()
        self._conn.rollback()
        return None if row is None else opening_hours_of_row(row)

    def venue_opening_hours(self, venue_id: UUID) -> OpeningHours | None:
        row = self._conn.execute(
            text("SELECT opens_at, closes_at, open_days FROM venue WHERE id = :id AND active"),
            {"id": venue_id},
        ).one_or_none()
        self._conn.rollback()
        return None if row is None else opening_hours_of_row(row)

    def free(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self, venue_id: UUID, sport: str, kind: str | None, start: datetime, end: datetime
    ) -> list[Space]:
        rows = self._conn.execute(
            text(
                f"SELECT {SPACE_COLUMNS} FROM space e JOIN venue s ON s.id = e.venue_id"
                " WHERE e.active AND s.active AND e.venue_id = :venue_id AND e.sport = :sport"
                " AND (CAST(:kind AS text) IS NULL OR e.kind = :kind)"
                " AND NOT EXISTS (SELECT 1 FROM booking r WHERE r.space_id = e.id"
                " AND r.status = :active AND r.starts_at < :ends_at AND r.ends_at > :starts_at)"
                " ORDER BY e.sport, e.kind, e.number"
            ),
            {
                "venue_id": venue_id,
                "sport": sport,
                "kind": kind,
                "starts_at": start,
                "ends_at": end,
                "active": stored("activa"),
            },
        ).all()
        self._conn.rollback()
        return [space_of_row(r) for r in rows]

    def taken(
        self,
        space_id: UUID,
        since: datetime,
        until: datetime,
        excluding: tuple[UUID, UUID] | None = None,
    ) -> list[tuple[datetime, datetime]]:
        booking, user = excluding or (None, None)
        rows = self._conn.execute(
            text(
                "SELECT starts_at, ends_at FROM booking"
                " WHERE space_id = :id AND status = :active"
                " AND starts_at < :until AND ends_at > :since"
                " AND (CAST(:booking_id AS uuid) IS NULL"
                "      OR NOT (id = :booking_id AND user_id = CAST(:user_id AS uuid)))"
            ),
            {
                "id": space_id,
                "since": since,
                "until": until,
                "booking_id": booking,
                "user_id": user,
                "active": stored("activa"),
            },
        ).all()
        self._conn.rollback()
        return [(r.starts_at, r.ends_at) for r in rows]


def availability_repository(conn: DbConnection) -> AvailabilitySql:
    return AvailabilitySql(conn)
