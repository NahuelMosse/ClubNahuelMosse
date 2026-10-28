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

_COLUMNS = "s.id, s.nombre, s.calle, s.altura, s.apertura, s.cierre, s.dias"


def _venue(row: Any, space_count: int, sports: tuple[str, ...] = ()) -> Venue:
    return Venue(
        id=row.id,
        name=row.nombre,
        street=row.calle,
        street_number=int(row.altura),
        opens_at=row.apertura,
        closes_at=row.cierre,
        open_days=tuple(int(d) for d in row.dias),
        space_count=space_count,
        sports=sports,
    )


# A booking falls outside a schedule if it starts before opening, ends after closing (at
# 00:00 it is midnight) or falls on a day the venue is closed, counted in the club's time.
_OUTSIDE = (
    "(({ini})::time < CAST(:{p}apertura AS time)"
    " OR ({fin}) - date_trunc('day', {ini}) > CASE WHEN CAST(:{p}cierre AS time) = '00:00'"
    " THEN interval '24 hours' ELSE CAST(:{p}cierre AS time) - time '00:00' END"
    " OR extract(isodow FROM {ini})::smallint <> ALL (CAST(:{p}dias AS smallint[])))"
)


def _outside(prefix: str) -> str:
    return _OUTSIDE.format(
        ini=f"r.inicio AT TIME ZONE '{CLUB_TIMEZONE_NAME}'",
        fin=f"r.fin AT TIME ZONE '{CLUB_TIMEZONE_NAME}'",
        p=prefix,
    )


class VenuesSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def active(self) -> list[Venue]:
        rows = self._conn.execute(
            text(
                f"SELECT {_COLUMNS}, count(e.id) AS canchas,"
                " coalesce(array_agg(DISTINCT e.deporte ORDER BY e.deporte)"
                " FILTER (WHERE e.id IS NOT NULL), '{}') AS deportes FROM sede s"
                " LEFT JOIN espacio e ON e.sede_id = s.id AND e.activo"
                " WHERE s.activa GROUP BY s.id ORDER BY lower(s.nombre), s.id"
            )
        ).all()
        self._conn.rollback()
        return [_venue(r, int(r.canchas), tuple(r.deportes)) for r in rows]

    def insert(self, new: NewVenue, author: UUID) -> Venue:
        try:
            with in_transaction(self._conn):
                row = self._conn.execute(
                    text(
                        "INSERT INTO sede AS s (nombre, calle, altura, apertura, cierre, dias,"
                        " creado_por, modificado_por)"
                        " VALUES (:nombre, :calle, :altura, :apertura, :cierre,"
                        " CAST(:dias AS smallint[]), :autor, :autor)"
                        f" RETURNING {_COLUMNS}"
                    ),
                    {
                        "nombre": new.name,
                        "calle": new.street,
                        "altura": new.street_number,
                        "apertura": new.opens_at,
                        "cierre": new.closes_at,
                        "dias": list(new.open_days),
                        "autor": author,
                    },
                ).one()
        except IntegrityError as e:
            constraint = violated_constraint(e)
            if constraint == "sede_nombre_activa_unico":
                raise Duplicate(["nombre"]) from e
            raise
        return _venue(row, space_count=0)

    def _check_bookings(self, values: dict[str, Any], before: Row[Any]) -> None:
        outside = int(
            self._conn.execute(
                text(
                    "SELECT count(*) FROM reserva r"
                    " JOIN espacio e ON e.id = r.espacio_id"
                    " WHERE e.sede_id = :id AND r.estado = 'activa'"
                    " AND r.inicio > now()"
                    f" AND {_outside('')} AND NOT {_outside('antes_')}"
                ),
                values
                | {
                    "antes_apertura": before.apertura,
                    "antes_cierre": before.cierre,
                    "antes_dias": list(before.dias),
                },
            ).scalar_one()
        )
        if outside:
            raise BookingsOutsideHours(outside)

    def _save(self, values: dict[str, Any]) -> None:
        self._conn.execute(
            text(
                "UPDATE sede SET nombre = :nombre, calle = :calle, altura = :altura,"
                " apertura = :apertura, cierre = :cierre, dias = CAST(:dias AS smallint[]),"
                " modificado_por = :autor, modificado_en = now() WHERE id = :id"
            ),
            values,
        )

    def update(self, venue_id: UUID, data: NewVenue, author: UUID, *, confirm: bool) -> Venue:
        values = {
            "id": venue_id,
            "nombre": data.name,
            "calle": data.street,
            "altura": data.street_number,
            "apertura": data.opens_at,
            "cierre": data.closes_at,
            "dias": list(data.open_days),
            "autor": author,
        }
        try:
            with in_transaction(self._conn):
                # Exclusive: a booking being made at the venue finishes first, or waits for the
                # new schedule and is validated again with it.
                before = self._conn.execute(
                    text(
                        "SELECT apertura, cierre, dias FROM sede"
                        " WHERE id = :id AND activa FOR UPDATE"
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
            if constraint == "sede_nombre_activa_unico":
                raise Duplicate(["nombre"]) from e
            raise
        saved = next((s for s in self.active() if s.id == venue_id), None)
        if saved is None:
            raise NotFound("la sede se dio de baja apenas se guardó")
        return saved

    def deactivate(self, venue_id: UUID, author: UUID) -> None:
        params = {"id": venue_id, "autor": author}
        with in_transaction(self._conn):
            # Exclusive: a booking being made at the venue finishes first and is seen here, or
            # waits and finds the venue deactivated.
            if (
                self._conn.execute(
                    text("SELECT 1 FROM sede WHERE id = :id AND activa FOR UPDATE"), params
                ).first()
                is None
            ):
                raise NotFound("la sede ya no está activa")
            pending: int = self._conn.execute(
                text(
                    "SELECT count(*) FROM reserva r JOIN espacio e ON e.id = r.espacio_id"
                    " WHERE e.sede_id = :id AND r.estado = 'activa' AND r.fin > now()"
                ),
                params,
            ).scalar_one()
            if pending:
                raise HasFutureBookings("la sede tiene reservas que todavía no terminaron")
            SpacesSql(self._conn).deactivate_venue_spaces(venue_id, author)
            self._conn.execute(
                text(
                    "UPDATE sede SET activa = false, dado_de_baja_en = now(),"
                    " dado_de_baja_por = :autor, modificado_por = :autor, modificado_en = now()"
                    " WHERE id = :id"
                ),
                params,
            )


def venue_repository(conn: DbConnection) -> VenuesSql:
    return VenuesSql(conn)
