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
    "e.id, e.nombre, e.sede_id, s.nombre AS sede, e.deporte, e.tipo, e.numero, e.techada,"
    " e.iluminada, e.precio_por_hora"
)
# First argument of this table's advisory locks: keeps its key space apart from the other
# locks of the database.
_NUMBERING_LOCK = 21


def space_of_row(row: Any) -> Space:
    return Space(
        id=row.id,
        name=row.nombre,
        venue_id=row.sede_id,
        venue=row.sede,
        sport=row.deporte,
        kind=row.tipo,
        number=int(row.numero),
        covered=bool(row.techada),
        lit=bool(row.iluminada),
        price_per_hour=int(row.precio_por_hora),
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
                f"SELECT {SPACE_COLUMNS} FROM espacio e JOIN sede s ON s.id = e.sede_id"
                " WHERE e.activo AND s.activa"
                " AND (CAST(:sede AS uuid) IS NULL OR e.sede_id = :sede)"
                " AND (CAST(:deporte AS text) IS NULL OR e.deporte = :deporte)"
                " AND (CAST(:tipo AS text) IS NULL OR e.tipo = :tipo)"
                " ORDER BY lower(s.nombre), s.id, e.deporte, e.tipo, e.numero"
            ),
            {"sede": venue_id, "deporte": sport, "tipo": kind},
        ).all()
        self._conn.rollback()
        return [space_of_row(r) for r in rows]

    def _venue(self, venue_id: UUID, *, lock: bool) -> SpaceVenue | None:
        row = self._conn.execute(
            text(
                "SELECT nombre, calle, altura FROM sede WHERE id = :id AND activa"
                + (" FOR SHARE" if lock else "")
            ),
            {"id": venue_id},
        ).first()
        return None if row is None else SpaceVenue(row.nombre, row.calle, int(row.altura))

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
                    "SELECT coalesce(max(numero), 0) + 1 FROM espacio"
                    " WHERE sede_id = :sede AND deporte = :deporte AND tipo = :tipo"
                ),
                {"sede": venue_id, "deporte": sport, "tipo": kind},
            ).scalar_one()
        )
        # Another venue can build the same composite name (one deactivated and created again
        # identically, or "Haedo" and "Sede Haedo" on the same street): that number is skipped.
        while self._conn.execute(
            text("SELECT 1 FROM espacio WHERE nombre = :n"), {"n": name(number)}
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
                f"SELECT {SPACE_COLUMNS} FROM espacio e JOIN sede s ON s.id = e.sede_id"
                " WHERE e.sede_id = :sede AND e.deporte = :deporte AND e.tipo = :tipo"
                " AND e.numero = :numero AND e.activo AND e.creado_por = :autor"
                " AND e.techada = :techada AND e.iluminada = :iluminada"
                " AND e.precio_por_hora = :precio"
                f" AND e.creado_en > now() - interval '{RETRY_WINDOW}'"
            ),
            {
                "sede": new.venue_id,
                "deporte": new.sport,
                "tipo": new.kind,
                "numero": number,
                "autor": author,
                "techada": new.covered,
                "iluminada": new.lit,
                "precio": new.price_per_hour,
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
            if index == "espacio_nombre_key":
                raise Duplicate(["nombre"]) from e
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
            text("SELECT pg_advisory_xact_lock(:espacio, hashtext(:c))"),
            {
                "espacio": _NUMBERING_LOCK,
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
                "WITH nuevo AS ("
                " INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora, creado_por, modificado_por)"
                " VALUES (:sede, :deporte, :tipo, :numero, :nombre, :techada, :iluminada,"
                " :precio, :autor, :autor) RETURNING *)"
                f" SELECT {SPACE_COLUMNS} FROM nuevo e"
                " JOIN sede s ON s.id = e.sede_id"
            ),
            {
                "sede": new.venue_id,
                "deporte": new.sport,
                "tipo": new.kind,
                "numero": following.number,
                "nombre": following.name,
                "techada": new.covered,
                "iluminada": new.lit,
                "precio": new.price_per_hour,
                "autor": author,
            },
        ).one()

    def update(self, space_id: UUID, change: SpaceChange, author: UUID) -> Space:
        params = {
            "id": space_id,
            "techada": change.covered,
            "iluminada": change.lit,
            "precio": change.price_per_hour,
            "autor": author,
        }
        with in_transaction(self._conn):
            self._lock_space_venue(params)
            self._modify(params)
            row = self._conn.execute(
                text(
                    f"SELECT {SPACE_COLUMNS} FROM espacio e JOIN sede s ON s.id = e.sede_id"
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
                "SELECT s.id FROM sede s JOIN espacio e ON e.sede_id = s.id"
                " WHERE e.id = :id AND e.activo AND s.activa FOR SHARE OF s"
            ),
            params,
        ).first()
        if venue is None:
            raise NotFound("el espacio ya no está activo")

    def _modify(self, params: dict[str, Any]) -> None:
        # The space may have been deactivated between the check and here: if no row was
        # touched, nothing was saved.
        touched = self._conn.execute(
            text(
                "UPDATE espacio SET"
                " techada = coalesce(CAST(:techada AS boolean), techada),"
                " iluminada = coalesce(CAST(:iluminada AS boolean), iluminada),"
                " precio_por_hora = coalesce(CAST(:precio AS integer), precio_por_hora),"
                " modificado_por = :autor, modificado_en = now()"
                " WHERE id = :id AND activo RETURNING id"
            ),
            params,
        ).first()
        if touched is None:
            raise NotFound("el espacio se dio de baja mientras tanto")

    def deactivate(self, space_id: UUID, author: UUID) -> None:
        params = {"id": space_id, "autor": author}
        with in_transaction(self._conn):
            # The shared venue and then the exclusive space, the order of a booking: the one
            # being made finishes first and is seen here, or waits and finds the space
            # deactivated.
            row = self._conn.execute(
                text(
                    "SELECT e.id FROM espacio e JOIN sede s ON s.id = e.sede_id"
                    " WHERE e.id = :id AND e.activo FOR SHARE OF s FOR UPDATE OF e"
                ),
                params,
            ).first()
            if row is None:
                raise NotFound("el espacio ya no está activo")
            pending: int = self._conn.execute(
                text(
                    "SELECT count(*) FROM reserva WHERE espacio_id = :id"
                    " AND estado = 'activa' AND fin > now()"
                ),
                params,
            ).scalar_one()
            if pending:
                raise HasFutureBookings("el espacio tiene reservas que todavía no terminaron")
            self._conn.execute(
                text(
                    "UPDATE espacio SET activo = false, dado_de_baja_en = now(),"
                    " dado_de_baja_por = :autor, modificado_por = :autor, modificado_en = now()"
                    " WHERE id = :id"
                ),
                params,
            )

    def deactivate_venue_spaces(self, venue_id: UUID, author: UUID) -> None:
        """Deactivates the active spaces of a venue, inside the caller's transaction:
        no commit."""
        self._conn.execute(
            text(
                "UPDATE espacio SET activo = false, dado_de_baja_en = now(),"
                " dado_de_baja_por = :autor, modificado_por = :autor, modificado_en = now()"
                " WHERE sede_id = :id AND activo"
            ),
            {"id": venue_id, "autor": author},
        )


def spaces_repository(conn: DbConnection) -> SpacesSql:
    return SpacesSql(conn)
