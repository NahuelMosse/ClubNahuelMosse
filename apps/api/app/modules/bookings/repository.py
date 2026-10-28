# kit-shape: the bookings repository and the function that hands it to the routes go together
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Row, text
from sqlalchemy.exc import IntegrityError

from app.modules.availability import AvailabilitySql, OpeningHours, opening_hours_of_row
from app.modules.bookings.rules import (
    PAGE_SIZE,
    Booking,
    BookingHistory,
    BookingHistoryEntry,
    Counters,
    HistoryFilters,
    When,
)
from app.modules.notifications import (
    BookingData,
    NotificationsSql,
    cancellation_message,
    enqueue_forced_cancellation,
)
from app.shared.club_timezone import CLUB_TIMEZONE_NAME
from app.shared.db import RETRY_WINDOW, DbConnection, in_transaction
from app.shared.errors import (
    ConcurrentChange,
    NotFound,
    OpeningHoursChanged,
    SlotTaken,
    Unavailable,
)

# SQLSTATE of the exclusion constraint: another active booking overlaps the slot.
EXCLUSION_VIOLATION = "23P01"

# The total of a booking: the price times the whole hours between the start and the end.
_TOTAL_SQL = (
    ":precio * (extract(epoch FROM CAST(:fin AS timestamptz)"
    " - CAST(:inicio AS timestamptz))::integer / 3600)"
)

_COMMON_COLUMNS = (
    "r.id, r.espacio_id AS space_id, e.sede_id AS venue_id, e.nombre AS space,"
    " e.deporte AS sport, e.tipo AS kind, s.nombre AS venue,"
    " s.calle || ' ' || s.altura AS address, r.inicio AS starts_at, r.fin AS ends_at,"
    " r.precio_por_hora AS price_per_hour, r.total, r.estado_actual AS status,"
    " r.motivo AS reason,"
)
_COLUMNS = f"{_COMMON_COLUMNS} (r.estado_actual = 'activa' AND r.inicio > now()) AS cancelable"
_HISTORY_COLUMNS = (
    f"{_COMMON_COLUMNS}"
    " r.usuario_id AS user_id, u.nombre || ' ' || u.apellido AS user,"
    " r.creado_en AS created_at, r.cancelada_en AS canceled_at,"
    " administrador.nombre || ' ' || administrador.apellido AS canceled_by_name,"
    " (NOT e.activo OR NOT s.activa) AS space_deactivated,"
    " (r.estado_actual = 'activa' AND r.inicio > now()) AS voidable,"
    # A pending notice is not yet part of the traceability.
    " CASE WHEN aviso.envio IN ('pendiente', 'enviando') THEN NULL ELSE aviso.envio END"
    " AS notice_delivery,"
    " CASE WHEN aviso.envio IN ('pendiente', 'enviando') THEN NULL"
    " WHEN aviso.envio = 'enviada' THEN aviso.enviada_en ELSE aviso.creado_en END AS notice_at"
)
_FROM_BOOKING = (
    " FROM reserva_con_estado r"
    " JOIN espacio e ON e.id = r.espacio_id"
    " JOIN sede s ON s.id = e.sede_id"
)
# What the filters of the global history look at: enough to count.
_FILTER_JOIN = f"{_FROM_BOOKING} JOIN usuario u ON u.id = r.usuario_id"
_HISTORY_JOIN = (
    f"{_FILTER_JOIN}"
    " LEFT JOIN usuario administrador ON administrador.id = r.cancelada_por"
    " LEFT JOIN notificacion_reserva vinculo ON vinculo.reserva_id = r.id"
    " LEFT JOIN notificacion aviso ON aviso.id = vinculo.notificacion_id"
)
_SHARED_VENUE = (
    "SELECT s.apertura, s.cierre, s.dias FROM sede s JOIN espacio e"
    " ON e.sede_id = s.id WHERE e.id = :espacio AND s.activa FOR SHARE OF s"
)

# The days of the filter are cut at midnight of the club, not of the Postgres session (UTC).
_CLUB_ZONE = f"'{CLUB_TIMEZONE_NAME}'"


@contextmanager
def _slot_taken() -> Iterator[None]:
    """An overlap with another active booking comes out as `SlotTaken`."""
    try:
        yield
    except IntegrityError as e:
        if getattr(e.orig, "sqlstate", None) == EXCLUSION_VIOLATION:
            raise SlotTaken("otra reserva activa pisa ese horario") from e
        raise


def _common_conditions(filters: HistoryFilters) -> tuple[list[str], dict[str, Any]]:
    """The conditions that hold for the total and for the counters, and their parameters."""
    conditions: list[str] = []
    params: dict[str, Any] = {}
    if filters.venue_id is not None:
        conditions.append("e.sede_id = :sede_id")
        params["sede_id"] = filters.venue_id
    if filters.sport is not None:
        conditions.append("e.deporte = :deporte")
        params["deporte"] = filters.sport
    if filters.since is not None:
        conditions.append(
            f"r.inicio >= (CAST(:desde AS date)::timestamp AT TIME ZONE {_CLUB_ZONE})"
        )
        params["desde"] = filters.since
    if filters.until is not None:
        conditions.append(
            f"r.inicio < ((CAST(:hasta AS date) + 1)::timestamp AT TIME ZONE {_CLUB_ZONE})"
        )
        params["hasta"] = filters.until
    if filters.q is not None and filters.q.strip():
        conditions.append(
            "(u.nombre || ' ' || u.apellido ILIKE :q ESCAPE '\\'"
            " OR s.nombre ILIKE :q ESCAPE '\\' OR e.nombre ILIKE :q ESCAPE '\\')"
        )
        literal = filters.q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        params["q"] = f"%{literal}%"
    return conditions, params


class BookingsSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def of_user(self, user_id: UUID, when: When) -> list[Booking]:
        order = (
            " AND r.estado_actual = 'activa' ORDER BY r.inicio, r.id"
            if when == "proximas"
            else " AND r.estado_actual <> 'activa' ORDER BY r.inicio DESC, r.id DESC"
        )
        rows = self._conn.execute(
            text(f"SELECT {_COLUMNS}{_FROM_BOOKING} WHERE r.usuario_id = :usuario{order}"),
            {"usuario": user_id},
        ).all()
        self._conn.rollback()
        return [Booking(**r._mapping) for r in rows]

    def opening_hours(self, space_id: UUID) -> OpeningHours | None:
        return AvailabilitySql(self._conn).opening_hours(space_id)

    def _repeated_id(self, params: dict[str, Any]) -> UUID | None:
        """The active booking that the same request already made a moment ago, if any."""
        row = self._conn.execute(
            text(
                "SELECT id FROM reserva WHERE usuario_id = :usuario"
                " AND espacio_id = :espacio AND inicio = :inicio AND fin = :fin"
                " AND estado = 'activa'"
                f" AND creado_en > now() - interval '{RETRY_WINDOW}'"
            ),
            params,
        ).first()
        return None if row is None else row.id

    def repeated(
        self, user_id: UUID, space_id: UUID, starts_at: datetime, ends_at: datetime
    ) -> Booking | None:
        repeated_id = self._repeated_id(
            {"usuario": user_id, "espacio": space_id, "inicio": starts_at, "fin": ends_at}
        )
        booking = None if repeated_id is None else self._one(repeated_id)
        self._conn.rollback()
        return booking

    def _one(self, booking_id: UUID) -> Booking:
        row = self._conn.execute(
            text(f"SELECT {_COLUMNS}{_FROM_BOOKING} WHERE r.id = :id"), {"id": booking_id}
        ).one()
        return Booking(**row._mapping)

    def own(self, user_id: UUID, booking_id: UUID) -> Booking | None:
        row = self._conn.execute(
            text(f"SELECT {_COLUMNS}{_FROM_BOOKING} WHERE r.id = :id AND r.usuario_id = :usuario"),
            {"id": booking_id, "usuario": user_id},
        ).first()
        self._conn.rollback()
        return None if row is None else Booking(**row._mapping)

    def space_kind(self, space_id: UUID) -> tuple[UUID, str, str] | None:
        row = self._conn.execute(
            text("SELECT sede_id, deporte, tipo FROM espacio WHERE id = :id"),
            {"id": space_id},
        ).first()
        self._conn.rollback()
        return None if row is None else (row.sede_id, row.deporte, row.tipo)

    def _current_venue(
        self, params: dict[str, Any], opening_hours: OpeningHours
    ) -> Row[Any] | None:
        """Takes the venue of the space in shared mode, which fixes its hours: if they changed
        since the booking was validated, it is validated again with the new ones."""
        venue = self._conn.execute(text(_SHARED_VENUE), params).first()
        if venue is not None and opening_hours_of_row(venue) != opening_hours:
            raise OpeningHoursChanged("la sede cambió de horario")
        return venue

    def move(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self,
        user_id: UUID,
        booking_id: UUID,
        before: tuple[UUID, datetime],
        space_id: UUID,
        starts_at: datetime,
        ends_at: datetime,
        opening_hours: OpeningHours,
    ) -> Booking:
        params = {
            "usuario": user_id,
            "id": booking_id,
            "antes": before[0],
            "desde_antes": before[1],
            "espacio": space_id,
            "inicio": starts_at,
            "fin": ends_at,
        }
        with _slot_taken(), in_transaction(self._conn):
            # As when booking: shared venue, exclusive spaces (by number: two crossed changes
            # between the same courts wait for each other, not deadlock) and the booking.
            venue = self._current_venue(params, opening_hours)
            spaces = self._lock_spaces(params)
            self._require_movable_booking(params)
            space = spaces.get(space_id)
            if venue is None or space is None or not space.activo:
                raise Unavailable("el espacio nuevo ya no está activo")
            # The previous slot is released in the same transaction that takes the new one: if
            # the new one collides with another booking, nothing changes.
            self._conn.execute(
                text(
                    "UPDATE reserva SET espacio_id = :espacio, inicio = :inicio, fin = :fin,"
                    f" precio_por_hora = :precio, total = {_TOTAL_SQL} WHERE id = :id"
                ),
                params | {"precio": int(space.precio_por_hora)},
            )
        booking = self._one(booking_id)
        self._conn.rollback()
        return booking

    def _lock_spaces(self, params: dict[str, Any]) -> dict[UUID, Row[Any]]:
        rows = self._conn.execute(
            text(
                "SELECT id, precio_por_hora, activo FROM espacio"
                " WHERE id IN (:antes, :espacio) ORDER BY id FOR NO KEY UPDATE"
            ),
            params,
        )
        return {e.id: e for e in rows}

    def _require_movable_booking(self, params: dict[str, Any]) -> None:
        row = self._conn.execute(
            text(
                "SELECT estado, inicio <= now() AS empezo,"
                " espacio_id = :antes AND inicio = :desde_antes AS donde_estaba"
                " FROM reserva WHERE id = :id AND usuario_id = :usuario FOR UPDATE"
            ),
            params,
        ).first()
        if row is None:
            raise NotFound("no hay una reserva suya con ese número")
        if row.estado != "activa" or row.empezo or not row.donde_estaba:
            raise ConcurrentChange("la reserva ya no está activa, ya empezó o ya se movió")

    def cancel(self, user_id: UUID, booking_id: UUID) -> Booking:
        params = {"usuario": user_id, "id": booking_id}
        with in_transaction(self._conn):
            row = self._conn.execute(
                text(
                    "SELECT estado, cancelada_por, inicio <= now() AS empezo FROM reserva"
                    " WHERE id = :id AND usuario_id = :usuario FOR UPDATE"
                ),
                params,
            ).first()
            if row is None:
                raise NotFound("no hay una reserva suya con ese número")
            if row.estado == "cancelada" and row.cancelada_por == user_id:
                self._conn.rollback()
                return self._one(booking_id)
            if row.estado != "activa" or row.empezo:
                raise ConcurrentChange("la reserva ya no está activa o ya empezó")
            self._conn.execute(
                text(
                    "UPDATE reserva SET estado = 'cancelada', cancelada_en = now(),"
                    " cancelada_por = :usuario WHERE id = :id"
                ),
                params,
            )
            booking = self._one(booking_id)
            # The confirmation is queued in the same transaction: if the cancellation does not
            # complete there is no notice, and the unique index avoids repeating it.
            booking_data = BookingData(
                booking.id, booking.sport, booking.kind, booking.venue, booking.starts_at
            )
            NotificationsSql(self._conn).enqueue_user_cancellation(
                user_id, booking_id, booking.starts_at, cancellation_message(booking_data)
            )
        return booking

    def cancel_future_of(self, user_id: UUID) -> None:
        """Cancels the active bookings that have not started yet of an account being
        deactivated, inside the transaction of the caller: no commit."""
        self._conn.execute(
            text(
                "UPDATE reserva SET estado = 'cancelada', cancelada_en = clock_timestamp(),"
                " cancelada_por = :id WHERE usuario_id = :id AND estado = 'activa'"
                " AND inicio > clock_timestamp()"
            ),
            {"id": user_id},
        )

    def _lock_for_insert(self, params: dict[str, Any], opening_hours: OpeningHours) -> Row[Any]:
        """The account and the venue are taken in shared mode, so neither is deactivated in
        between; the space, exclusive: two bookings of the same space go one at a time.
        Without that, each one sees in the exclusion index the unconfirmed row of the other
        and the database aborts one by deadlock instead of rejecting it as an overlap. The
        venue goes before the space, the order of a venue deactivation. Returns the space."""
        account = self._conn.execute(
            text("SELECT 1 FROM usuario WHERE id = :usuario AND activo FOR SHARE"), params
        ).first()
        venue = self._current_venue(params, opening_hours)
        space = self._conn.execute(
            text(
                "SELECT precio_por_hora FROM espacio WHERE id = :espacio AND activo"
                " FOR NO KEY UPDATE"
            ),
            params,
        ).first()
        if account is None or venue is None or space is None:
            raise Unavailable("la cuenta o el espacio ya no están activos")
        return space

    def insert(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self,
        user_id: UUID,
        space_id: UUID,
        starts_at: datetime,
        ends_at: datetime,
        opening_hours: OpeningHours,
    ) -> Booking:
        params = {"usuario": user_id, "espacio": space_id, "inicio": starts_at, "fin": ends_at}
        with _slot_taken(), in_transaction(self._conn):
            space = self._lock_for_insert(params, opening_hours)
            repeated_id = self._repeated_id(params)
            if repeated_id is not None:
                self._conn.rollback()
                return self._one(repeated_id)
            new_id: UUID = self._conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    f" total) VALUES (:usuario, :espacio, :inicio, :fin, :precio, {_TOTAL_SQL})"
                    " RETURNING id"
                ),
                params | {"precio": int(space.precio_por_hora)},
            ).scalar_one()
        booking = self._one(new_id)
        self._conn.rollback()
        return booking

    def _lock_for_void(self, params: dict[str, Any]) -> Row[Any]:
        """Without locking, it looks at who the booking belongs to in order to take the locks
        in the usual order: the account and the venue shared, the space exclusive and only
        then the booking. If the booking moved to another space in between, the locked space
        is no longer its own and it is rejected as changed. Completes `params` with the
        account, the venue and the space and returns the row of the booking."""
        previous = self._conn.execute(
            text(
                "SELECT r.usuario_id, r.espacio_id, e.sede_id FROM reserva r"
                " JOIN espacio e ON e.id = r.espacio_id WHERE r.id = :id"
            ),
            params,
        ).first()
        if previous is None:
            raise NotFound("no hay una reserva con ese número")
        params |= {
            "usuario": previous.usuario_id,
            "sede": previous.sede_id,
            "espacio_previo": previous.espacio_id,
        }
        self._conn.execute(text("SELECT 1 FROM usuario WHERE id = :usuario FOR SHARE"), params)
        self._conn.execute(text("SELECT 1 FROM sede WHERE id = :sede FOR SHARE"), params)
        self._conn.execute(
            text("SELECT 1 FROM espacio WHERE id = :espacio_previo FOR NO KEY UPDATE"), params
        )
        return previous

    def _lock_booking_to_void(self, params: dict[str, Any]) -> Row[Any]:
        row = self._conn.execute(
            text(
                "SELECT estado, motivo, cancelada_por, inicio <= now() AS empezo,"
                " espacio_id = :espacio_previo AND espacio_id = :espacio"
                " AND inicio = CAST(:inicio AS timestamptz) AS como_se_vio"
                " FROM reserva WHERE id = :id FOR UPDATE"
            ),
            params,
        ).first()
        if row is None:
            raise NotFound("no hay una reserva con ese número")
        return row

    def void(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self, admin_id: UUID, booking_id: UUID, reason: str, space_id: UUID, starts_at: datetime
    ) -> BookingHistoryEntry:
        params: dict[str, Any] = {
            "admin": admin_id,
            "id": booking_id,
            "motivo": reason,
            "espacio": space_id,
            "inicio": starts_at,
        }
        with in_transaction(self._conn):
            previous = self._lock_for_void(params)
            row = self._lock_booking_to_void(params)
            if row.estado == "anulada" and row.cancelada_por == admin_id and row.motivo == reason:
                self._conn.rollback()
                return self._detail(booking_id)
            if row.estado != "activa" or row.empezo or not row.como_se_vio:
                raise ConcurrentChange("la reserva ya no está activa, ya empezó o cambió")
            self._conn.execute(
                text(
                    "UPDATE reserva SET estado = 'anulada', motivo = :motivo,"
                    " cancelada_en = now(), cancelada_por = :admin WHERE id = :id"
                ),
                params,
            )
            # The notice is queued in the same transaction, after the usual locks.
            enqueue_forced_cancellation(self._conn, previous.usuario_id, [booking_id])
        return self._detail(booking_id)

    def _detail(self, booking_id: UUID) -> BookingHistoryEntry:
        detail = self.any_one(booking_id)
        if detail is None:
            raise NotFound("no hay una reserva con ese número")
        return detail

    def _count(
        self, common: list[str], total_of: str, params: dict[str, Any]
    ) -> tuple[int, Counters]:
        """The total and the four counters come out of a single pass over the rows that pass
        the common filters, without the joins that are only needed to show each booking."""
        row = self._conn.execute(
            text(
                f"SELECT {total_of} AS total, count(*) AS all_count,"
                " count(*) FILTER (WHERE r.estado_actual = 'activa') AS active_count,"
                " count(*) FILTER (WHERE r.estado_actual = 'completada') AS completed_count,"
                " count(*) FILTER (WHERE r.estado_actual = 'anulada') AS voided_count"
                f"{_FILTER_JOIN} WHERE {' AND '.join(['true', *common])}"
            ),
            params,
        ).one()
        counters = Counters(
            all=int(row.all_count),
            active=int(row.active_count),
            completed=int(row.completed_count),
            voided=int(row.voided_count),
        )
        return int(row.total), counters

    def history(self, filters: HistoryFilters) -> BookingHistory:
        common, params = _common_conditions(filters)
        conditions = list(common)
        total_of = "count(*)"
        if filters.status is not None:
            conditions.append("r.estado_actual = :estado")
            params["estado"] = filters.status
            total_of = "count(*) FILTER (WHERE r.estado_actual = :estado)"
        total, counters = self._count(common, total_of, params)
        page = max(1, filters.page)
        rows = self._conn.execute(
            text(
                f"SELECT {_HISTORY_COLUMNS}{_HISTORY_JOIN}"
                f" WHERE {' AND '.join(['true', *conditions])}"
                " ORDER BY r.inicio DESC, r.id DESC LIMIT :limite OFFSET :offset"
            ),
            params | {"limite": PAGE_SIZE, "offset": (page - 1) * PAGE_SIZE},
        ).all()
        self._conn.rollback()
        return BookingHistory(
            bookings=[BookingHistoryEntry(**r._mapping) for r in rows],
            total=total,
            page=page,
            per_page=PAGE_SIZE,
            counters=counters,
        )

    def any_one(self, booking_id: UUID) -> BookingHistoryEntry | None:
        row = self._conn.execute(
            text(f"SELECT {_HISTORY_COLUMNS}{_HISTORY_JOIN} WHERE r.id = :id"),
            {"id": booking_id},
        ).first()
        self._conn.rollback()
        return None if row is None else BookingHistoryEntry(**row._mapping)


def bookings_repository(conn: DbConnection) -> BookingsSql:
    return BookingsSql(conn)
