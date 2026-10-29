# kit-shape: the spaces repository and the functions that build its entity go together
from collections.abc import Callable
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Row, text
from sqlalchemy.exc import IntegrityError

from app.modules.spaces.rules import (
    NewSpace,
    Space,
    SpaceChange,
    SpaceVenue,
    SuggestedName,
)
from app.shared.db import RETRY_WINDOW, DbConnection, in_transaction, violated_constraint
from app.shared.errors import (
    Duplicate,
    HasFutureBookings,
    NotFound,
    NumberTaken,
    Unavailable,
)

SPACE_COLUMNS = (
    "e.id, e.name, e.venue_id, s.name AS venue, e.sport, e.kind, e.number, e.covered,"
    " e.lit, e.price_per_hour"
)
# First argument of this table's advisory locks: keeps its key space apart from the other
# locks of the database.
_NUMBERING_LOCK = 21


def space_of_row(row: Any) -> Space:
    return Space(
        id=row.id,
        name=row.name,
        venue_id=row.venue_id,
        venue=row.venue,
        sport=row.sport,
        kind=row.kind,
        number=int(row.number),
        covered=bool(row.covered),
        lit=bool(row.lit),
        price_per_hour=int(row.price_per_hour),
    )


class SpacesSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def active(
        self,
        venue_id: UUID | None = None,
        sport: str | None = None,
        kind: str | None = None,
    ) -> list[Space]:
        rows = self._conn.execute(
            text(
                f"SELECT {SPACE_COLUMNS} FROM space e JOIN venue s ON s.id = e.venue_id"
                " WHERE e.active AND s.active"
                " AND (CAST(:venue AS uuid) IS NULL OR e.venue_id = :venue)"
                " AND (CAST(:sport AS text) IS NULL OR e.sport = :sport)"
                " AND (CAST(:kind AS text) IS NULL OR e.kind = :kind)"
                " ORDER BY lower(s.name), s.id, e.sport, e.kind, e.number"
            ),
            {"venue": venue_id, "sport": sport, "kind": kind},
        ).all()
        self._conn.rollback()
        return [space_of_row(r) for r in rows]

    def _venue(self, venue_id: UUID, *, lock: bool) -> SpaceVenue | None:
        row = self._conn.execute(
            text(
                "SELECT name, street, street_number FROM venue WHERE id = :id AND active"
                + (" FOR SHARE" if lock else "")
            ),
            {"id": venue_id},
        ).first()
        return None if row is None else SpaceVenue(row.name, row.street, int(row.street_number))

    def _compute(
        self,
        venue_id: UUID,
        sport: str,
        kind: str,
        name: Callable[[int], str],
    ) -> SuggestedName:
        number = int(
            self._conn.execute(
                text(
                    "SELECT coalesce(max(number), 0) + 1 FROM space"
                    " WHERE venue_id = :venue AND sport = :sport AND kind = :kind"
                ),
                {"venue": venue_id, "sport": sport, "kind": kind},
            ).scalar_one()
        )
        # Another venue can build the same composite name (one deactivated and created again
        # identically, or "Haedo" and "Sede Haedo" on the same street): that number is skipped.
        while self._conn.execute(
            text("SELECT 1 FROM space WHERE name = :n"), {"n": name(number)}
        ).first():
            number += 1
        return SuggestedName(name(number), number)

    def next_number(
        self,
        venue_id: UUID,
        sport: str,
        kind: str,
        name: Callable[[SpaceVenue, int], str],
    ) -> SuggestedName | None:
        try:
            venue = self._venue(venue_id, lock=False)
            if venue is None:
                return None
            return self._compute(venue_id, sport, kind, lambda n: name(venue, n))
        finally:
            self._conn.rollback()

    def _repeated(self, new: NewSpace, number: int, author: UUID) -> Space | None:
        row = self._conn.execute(
            text(
                f"SELECT {SPACE_COLUMNS} FROM space e JOIN venue s ON s.id = e.venue_id"
                " WHERE e.venue_id = :venue AND e.sport = :sport AND e.kind = :kind"
                " AND e.number = :number AND e.active AND e.created_by = :author"
                " AND e.covered = :covered AND e.lit = :lit"
                " AND e.price_per_hour = :price"
                f" AND e.created_at > now() - interval '{RETRY_WINDOW}'"
            ),
            {
                "venue": new.venue_id,
                "sport": new.sport,
                "kind": new.kind,
                "number": number,
                "author": author,
                "covered": new.covered,
                "lit": new.lit,
                "price": new.price_per_hour,
            },
        ).first()
        return None if row is None else space_of_row(row)

    def insert(
        self,
        new: NewSpace,
        number: int | None,
        name: Callable[[SpaceVenue, int], str],
        author: UUID,
    ) -> Space:
        try:
            with in_transaction(self._conn):
                venue = self._lock_numbering(new)
                following = self._compute(
                    new.venue_id, new.sport, new.kind, lambda n: name(venue, n)
                )
                if number is not None and number != following.number:
                    return self._number_taken(new, number, following, author)
                row = self._insert_row(new, following, author)
        except IntegrityError as e:
            index = violated_constraint(e)
            # A creation in another venue took the same name between the computation and the
            # INSERT.
            if index == "space_name_key":
                raise Duplicate(["name"]) from e
            raise
        return space_of_row(row)

    def _lock_numbering(self, new: NewSpace) -> SpaceVenue:
        # The venue is taken shared so it cannot be deactivated in between, and the numbering
        # of that kind in that venue exclusive: two creations at once do not compute the same
        # number.
        venue = self._venue(new.venue_id, lock=True)
        if venue is None:
            raise Unavailable("la sede no está activa")
        self._conn.execute(
            text("SELECT pg_advisory_xact_lock(:space, hashtext(:c))"),
            {
                "space": _NUMBERING_LOCK,
                "c": f"{new.venue_id}:{new.sport}:{new.kind}",
            },
        )
        return venue

    def _number_taken(
        self, new: NewSpace, number: int, following: SuggestedName, author: UUID
    ) -> Space:
        repeated = self._repeated(new, number, author)
        self._conn.rollback()
        if repeated is not None:
            return repeated
        raise NumberTaken(following.number, following.name)

    def _insert_row(self, new: NewSpace, following: SuggestedName, author: UUID) -> Row[Any]:
        return self._conn.execute(
            text(
                "WITH created AS ("
                " INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour, created_by, updated_by)"
                " VALUES (:venue, :sport, :kind, :number, :name, :covered, :lit,"
                " :price, :author, :author) RETURNING *)"
                f" SELECT {SPACE_COLUMNS} FROM created e"
                " JOIN venue s ON s.id = e.venue_id"
            ),
            {
                "venue": new.venue_id,
                "sport": new.sport,
                "kind": new.kind,
                "number": following.number,
                "name": following.name,
                "covered": new.covered,
                "lit": new.lit,
                "price": new.price_per_hour,
                "author": author,
            },
        ).one()

    def update(self, space_id: UUID, change: SpaceChange, author: UUID) -> Space:
        params = {
            "id": space_id,
            "covered": change.covered,
            "lit": change.lit,
            "price": change.price_per_hour,
            "author": author,
        }
        with in_transaction(self._conn):
            self._lock_space_venue(params)
            self._modify(params)
            row = self._conn.execute(
                text(
                    f"SELECT {SPACE_COLUMNS} FROM space e JOIN venue s ON s.id = e.venue_id"
                    " WHERE e.id = :id"
                ),
                params,
            ).one()
        return space_of_row(row)

    def _lock_space_venue(self, params: dict[str, Any]) -> None:
        # The shared venue and then the space row, the order of a booking: the one being
        # saved takes the price from before or from now, whole.
        venue = self._conn.execute(
            text(
                "SELECT s.id FROM venue s JOIN space e ON e.venue_id = s.id"
                " WHERE e.id = :id AND e.active AND s.active FOR SHARE OF s"
            ),
            {"id": params["id"]},
        ).first()
        if venue is None:
            raise NotFound("el espacio ya no está activo")

    def _modify(self, params: dict[str, Any]) -> None:
        # The space may have been deactivated between the check and here: if no row was
        # touched, nothing was saved.
        touched = self._conn.execute(
            text(
                "UPDATE space SET"
                " covered = coalesce(CAST(:covered AS boolean), covered),"
                " lit = coalesce(CAST(:lit AS boolean), lit),"
                " price_per_hour = coalesce(CAST(:price AS integer), price_per_hour),"
                " updated_by = :author, updated_at = now()"
                " WHERE id = :id AND active RETURNING id"
            ),
            params,
        ).first()
        if touched is None:
            raise NotFound("el espacio se dio de baja mientras tanto")

    def deactivate(self, space_id: UUID, author: UUID) -> None:
        params = {"id": space_id, "author": author}
        with in_transaction(self._conn):
            # The shared venue and then the exclusive space, the order of a booking: the one
            # being made finishes first and is seen here, or waits and finds the space
            # deactivated.
            row = self._conn.execute(
                text(
                    "SELECT e.id FROM space e JOIN venue s ON s.id = e.venue_id"
                    " WHERE e.id = :id AND e.active FOR SHARE OF s FOR UPDATE OF e"
                ),
                {"id": space_id},
            ).first()
            if row is None:
                raise NotFound("el espacio ya no está activo")
            pending: int = self._conn.execute(
                text(
                    "SELECT count(*) FROM booking WHERE space_id = :id"
                    " AND status = :active_status AND ends_at > now()"
                ),
                {"id": space_id, "active_status": "active"},
            ).scalar_one()
            if pending:
                raise HasFutureBookings("el espacio tiene reservas que todavía no terminaron")
            self._conn.execute(
                text(
                    "UPDATE space SET active = false, deactivated_at = now(),"
                    " deactivated_by = :author, updated_by = :author, updated_at = now()"
                    " WHERE id = :id"
                ),
                params,
            )

    def deactivate_venue_spaces(self, venue_id: UUID, author: UUID) -> None:
        """Deactivates the active spaces of a venue, inside the caller's transaction:
        no commit."""
        self._conn.execute(
            text(
                "UPDATE space SET active = false, deactivated_at = now(),"
                " deactivated_by = :author, updated_by = :author, updated_at = now()"
                " WHERE venue_id = :id AND active"
            ),
            {"id": venue_id, "author": author},
        )


def spaces_repository(conn: DbConnection) -> SpacesSql:
    return SpacesSql(conn)
