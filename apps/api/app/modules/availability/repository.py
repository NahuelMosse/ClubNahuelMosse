# kit-shape: the availability repository and the functions that build its opening hours go together
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.modules.availability.rules import OpeningHours
from app.modules.spaces import SPACE_COLUMNS, Space, space_of_row
from app.shared.db import DbConnection


def opening_hours_of_row(row: Any) -> OpeningHours:
    """The days go in a tuple: the opening hours are compared with `!=` against another to
    know whether they changed."""
    return OpeningHours(
        opens_at=row.apertura, closes_at=row.cierre, open_days=tuple(int(d) for d in row.dias)
    )


class AvailabilitySql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def opening_hours(self, space_id: UUID) -> OpeningHours | None:
        row = self._conn.execute(
            text(
                "SELECT s.apertura, s.cierre, s.dias FROM espacio e"
                " JOIN sede s ON s.id = e.sede_id"
                " WHERE e.id = :id AND e.activo AND s.activa"
            ),
            {"id": space_id},
        ).one_or_none()
        self._conn.rollback()
        return None if row is None else opening_hours_of_row(row)

    def venue_opening_hours(self, venue_id: UUID) -> OpeningHours | None:
        row = self._conn.execute(
            text("SELECT apertura, cierre, dias FROM sede WHERE id = :id AND activa"),
            {"id": venue_id},
        ).one_or_none()
        self._conn.rollback()
        return None if row is None else opening_hours_of_row(row)

    def free(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self, venue_id: UUID, sport: str, kind: str | None, start: datetime, end: datetime
    ) -> list[Space]:
        rows = self._conn.execute(
            text(
                f"SELECT {SPACE_COLUMNS} FROM espacio e JOIN sede s ON s.id = e.sede_id"
                " WHERE e.activo AND s.activa AND e.sede_id = :sede AND e.deporte = :deporte"
                " AND (CAST(:tipo AS text) IS NULL OR e.tipo = :tipo)"
                " AND NOT EXISTS (SELECT 1 FROM reserva r WHERE r.espacio_id = e.id"
                " AND r.estado = 'activa' AND r.inicio < :fin AND r.fin > :inicio)"
                " ORDER BY e.deporte, e.tipo, e.numero"
            ),
            {"sede": venue_id, "deporte": sport, "tipo": kind, "inicio": start, "fin": end},
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
                "SELECT inicio, fin FROM reserva"
                " WHERE espacio_id = :id AND estado = 'activa'"
                " AND inicio < :hasta AND fin > :desde"
                " AND (CAST(:reserva AS uuid) IS NULL"
                "      OR NOT (id = :reserva AND usuario_id = CAST(:usuario AS uuid)))"
            ),
            {
                "id": space_id,
                "desde": since,
                "hasta": until,
                "reserva": booking,
                "usuario": user,
            },
        ).all()
        self._conn.rollback()
        return [(r.inicio, r.fin) for r in rows]


def availability_repository(conn: DbConnection) -> AvailabilitySql:
    return AvailabilitySql(conn)
