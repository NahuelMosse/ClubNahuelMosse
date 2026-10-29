# kit-shape: the bookings repository and the function that hands it to the routes go together
from collections.abc import Iterator, Mapping
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
from app.shared.stored_values import contract, stored

# SQLSTATE of the exclusion constraint: another active booking overlaps the slot.
EXCLUSION_VIOLATION = "23P01"

# The total of a booking: the price times the whole hours between the start and the end.
_TOTAL_SQL = (
    ":price * (extract(epoch FROM CAST(:ends_at AS timestamptz)"
    " - CAST(:starts_at AS timestamptz))::integer / 3600)"
)

_COMMON_COLUMNS = (
    "r.id, r.space_id, e.venue_id, e.name AS space,"
    " e.sport, e.kind, s.name AS venue,"
    " s.street || ' ' || s.street_number AS address, r.starts_at, r.ends_at,"
    " r.price_per_hour, r.total, r.current_status AS status,"
    " r.reason,"
)
_CANCELABLE = "(r.current_status = 'active' AND r.starts_at > now())"
_COLUMNS = f"{_COMMON_COLUMNS} {_CANCELABLE} AS cancelable"
_HISTORY_COLUMNS = (
    f"{_COMMON_COLUMNS}"
    " r.user_id, u.first_name || ' ' || u.last_name AS user,"
    " r.created_at, r.canceled_at,"
    " canceler.first_name || ' ' || canceler.last_name AS canceled_by_name,"
    " (NOT e.active OR NOT s.active) AS space_deactivated,"
    f" {_CANCELABLE} AS voidable,"
    # A pending notice is not yet part of the traceability.
    " CASE WHEN notice.delivery IN ('pending', 'sending') THEN NULL ELSE notice.delivery END"
    " AS notice_delivery,"
    " CASE WHEN notice.delivery IN ('pending', 'sending') THEN NULL"
    " WHEN notice.delivery = 'sent' THEN notice.sent_at ELSE notice.created_at END AS notice_at"
)
_FROM_BOOKING = (
    " FROM booking_with_status r"
    " JOIN space e ON e.id = r.space_id"
    " JOIN venue s ON s.id = e.venue_id"
)
# What the filters of the global history look at: enough to count.
_FILTER_JOIN = f"{_FROM_BOOKING} JOIN app_user u ON u.id = r.user_id"
_HISTORY_JOIN = (
    f"{_FILTER_JOIN}"
    " LEFT JOIN app_user canceler ON canceler.id = r.canceled_by"
    " LEFT JOIN notification_booking link ON link.booking_id = r.id"
    " LEFT JOIN notification notice ON notice.id = link.notification_id"
)
_SHARED_VENUE = (
    "SELECT s.opens_at, s.closes_at, s.open_days FROM venue s JOIN space e"
    " ON e.venue_id = s.id WHERE e.id = :space_id AND s.active FOR SHARE OF s"
)

# The days of the filter are cut at midnight of the club, not of the Postgres session (UTC).
_CLUB_ZONE = f"'{CLUB_TIMEZONE_NAME}'"


def _booking_values(mapping: Mapping[Any, Any]) -> dict[str, Any]:
    """The columns of a row with the enumerations spoken as the contract does."""
    values = dict(mapping)
    values["status"] = contract(values["status"])
    if values.get("notice_delivery") is not None:
        values["notice_delivery"] = contract(values["notice_delivery"])
    return values


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
        conditions.append("e.venue_id = :venue_id")
        params["venue_id"] = filters.venue_id
    if filters.sport is not None:
        conditions.append("e.sport = :sport")
        params["sport"] = filters.sport
    if filters.since is not None:
        conditions.append(
            f"r.starts_at >= (CAST(:since AS date)::timestamp AT TIME ZONE {_CLUB_ZONE})"
        )
        params["since"] = filters.since
    if filters.until is not None:
        conditions.append(
            f"r.starts_at < ((CAST(:until AS date) + 1)::timestamp AT TIME ZONE {_CLUB_ZONE})"
        )
        params["until"] = filters.until
    if filters.q is not None and filters.q.strip():
        conditions.append(
            "(u.first_name || ' ' || u.last_name ILIKE :q ESCAPE '\\'"
            " OR s.name ILIKE :q ESCAPE '\\' OR e.name ILIKE :q ESCAPE '\\')"
        )
        literal = filters.q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        params["q"] = f"%{literal}%"
    return conditions, params


class BookingsSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def of_user(self, user_id: UUID, when: When) -> list[Booking]:
        order = (
            " AND r.current_status = 'active' ORDER BY r.starts_at, r.id"
            if when == "proximas"
            else " AND r.current_status <> 'active' ORDER BY r.starts_at DESC, r.id DESC"
        )
        rows = self._conn.execute(
            text(f"SELECT {_COLUMNS}{_FROM_BOOKING} WHERE r.user_id = :user_id{order}"),
            {"user_id": user_id},
        ).all()
        self._conn.rollback()
        return [Booking(**_booking_values(r._mapping)) for r in rows]

    def opening_hours(self, space_id: UUID) -> OpeningHours | None:
        return AvailabilitySql(self._conn).opening_hours(space_id)

    def _repeated_id(self, params: dict[str, Any]) -> UUID | None:
        """The active booking that the same request already made a moment ago, if any."""
        row = self._conn.execute(
            text(
                "SELECT id FROM booking WHERE user_id = :user_id"
                " AND space_id = :space_id AND starts_at = :starts_at AND ends_at = :ends_at"
                " AND status = 'active'"
                f" AND created_at > now() - interval '{RETRY_WINDOW}'"
            ),
            params,
        ).first()
        return None if row is None else row.id

    def repeated(
        self, user_id: UUID, space_id: UUID, starts_at: datetime, ends_at: datetime
    ) -> Booking | None:
        repeated_id = self._repeated_id(
            {
                "user_id": user_id,
                "space_id": space_id,
                "starts_at": starts_at,
                "ends_at": ends_at,
            }
        )
        booking = None if repeated_id is None else self._one(repeated_id)
        self._conn.rollback()
        return booking

    def _one(self, booking_id: UUID) -> Booking:
        row = self._conn.execute(
            text(f"SELECT {_COLUMNS}{_FROM_BOOKING} WHERE r.id = :id"), {"id": booking_id}
        ).one()
        return Booking(**_booking_values(row._mapping))

    def own(self, user_id: UUID, booking_id: UUID) -> Booking | None:
        row = self._conn.execute(
            text(f"SELECT {_COLUMNS}{_FROM_BOOKING} WHERE r.id = :id AND r.user_id = :user_id"),
            {"id": booking_id, "user_id": user_id},
        ).first()
        self._conn.rollback()
        return None if row is None else Booking(**_booking_values(row._mapping))

    def space_kind(self, space_id: UUID) -> tuple[UUID, str, str] | None:
        row = self._conn.execute(
            text("SELECT venue_id, sport, kind FROM space WHERE id = :id"),
            {"id": space_id},
        ).first()
        self._conn.rollback()
        return None if row is None else (row.venue_id, row.sport, row.kind)

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
            "user_id": user_id,
            "id": booking_id,
            "before_space_id": before[0],
            "before_starts_at": before[1],
            "space_id": space_id,
            "starts_at": starts_at,
            "ends_at": ends_at,
        }
        with _slot_taken(), in_transaction(self._conn):
            # As when booking: shared venue, exclusive spaces (by number: two crossed changes
            # between the same courts wait for each other, not deadlock) and the booking.
            venue = self._current_venue(params, opening_hours)
            spaces = self._lock_spaces(params)
            self._require_movable_booking(params)
            space = spaces.get(space_id)
            if venue is None or space is None or not space.active:
                raise Unavailable("el espacio nuevo ya no está activo")
            # The previous slot is released in the same transaction that takes the new one.
            self._conn.execute(
                text(
                    "UPDATE booking SET space_id = :space_id, starts_at = :starts_at,"
                    f" ends_at = :ends_at, price_per_hour = :price, total = {_TOTAL_SQL}"
                    " WHERE id = :id"
                ),
                params | {"price": int(space.price_per_hour)},
            )
        booking = self._one(booking_id)
        self._conn.rollback()
        return booking

    def _lock_spaces(self, params: dict[str, Any]) -> dict[UUID, Row[Any]]:
        rows = self._conn.execute(
            text(
                "SELECT id, price_per_hour, active FROM space"
                " WHERE id IN (:before_space_id, :space_id) ORDER BY id FOR NO KEY UPDATE"
            ),
            params,
        )
        return {e.id: e for e in rows}

    def _require_movable_booking(self, params: dict[str, Any]) -> None:
        row = self._conn.execute(
            text(
                "SELECT status, starts_at <= now() AS started,"
                " space_id = :before_space_id AND starts_at = :before_starts_at AS was_there"
                " FROM booking WHERE id = :id AND user_id = :user_id FOR UPDATE"
            ),
            params,
        ).first()
        if row is None:
            raise NotFound("no hay una reserva suya con ese número")
        if row.status != stored("activa") or row.started or not row.was_there:
            raise ConcurrentChange("la reserva ya no está activa, ya empezó o ya se movió")

    def cancel(self, user_id: UUID, booking_id: UUID) -> Booking:
        params = {"user_id": user_id, "id": booking_id}
        with in_transaction(self._conn):
            row = self._conn.execute(
                text(
                    "SELECT status, canceled_by, starts_at <= now() AS started FROM booking"
                    " WHERE id = :id AND user_id = :user_id FOR UPDATE"
                ),
                params,
            ).first()
            if row is None:
                raise NotFound("no hay una reserva suya con ese número")
            if row.status == stored("cancelada") and row.canceled_by == user_id:
                self._conn.rollback()
                return self._one(booking_id)
            if row.status != stored("activa") or row.started:
                raise ConcurrentChange("la reserva ya no está activa o ya empezó")
            self._conn.execute(
                text(
                    "UPDATE booking SET status = 'canceled', canceled_at = now(),"
                    " canceled_by = :user_id WHERE id = :id"
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
                "UPDATE booking SET status = 'canceled', canceled_at = clock_timestamp(),"
                " canceled_by = :id WHERE user_id = :id AND status = 'active'"
                " AND starts_at > clock_timestamp()"
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
            text("SELECT 1 FROM app_user WHERE id = :user_id AND active FOR SHARE"), params
        ).first()
        venue = self._current_venue(params, opening_hours)
        space = self._conn.execute(
            text(
                "SELECT price_per_hour FROM space WHERE id = :space_id AND active"
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
        params = {
            "user_id": user_id,
            "space_id": space_id,
            "starts_at": starts_at,
            "ends_at": ends_at,
        }
        with _slot_taken(), in_transaction(self._conn):
            space = self._lock_for_insert(params, opening_hours)
            repeated_id = self._repeated_id(params)
            if repeated_id is not None:
                self._conn.rollback()
                return self._one(repeated_id)
            new_id: UUID = self._conn.execute(
                text(
                    "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                    " total) VALUES (:user_id, :space_id, :starts_at, :ends_at, :price,"
                    f" {_TOTAL_SQL}) RETURNING id"
                ),
                params | {"price": int(space.price_per_hour)},
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
                "SELECT r.user_id, r.space_id, e.venue_id FROM booking r"
                " JOIN space e ON e.id = r.space_id WHERE r.id = :id"
            ),
            params,
        ).first()
        if previous is None:
            raise NotFound("no hay una reserva con ese número")
        params |= {
            "user_id": previous.user_id,
            "venue_id": previous.venue_id,
            "previous_space_id": previous.space_id,
        }
        self._conn.execute(text("SELECT 1 FROM app_user WHERE id = :user_id FOR SHARE"), params)
        self._conn.execute(text("SELECT 1 FROM venue WHERE id = :venue_id FOR SHARE"), params)
        self._conn.execute(
            text("SELECT 1 FROM space WHERE id = :previous_space_id FOR NO KEY UPDATE"), params
        )
        return previous

    def _lock_booking_to_void(self, params: dict[str, Any]) -> Row[Any]:
        row = self._conn.execute(
            text(
                "SELECT status, reason, canceled_by, starts_at <= now() AS started,"
                " space_id = :previous_space_id AND space_id = :space_id"
                " AND starts_at = CAST(:starts_at AS timestamptz) AS as_seen"
                " FROM booking WHERE id = :id FOR UPDATE"
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
            "admin_id": admin_id,
            "id": booking_id,
            "reason": reason,
            "space_id": space_id,
            "starts_at": starts_at,
        }
        with in_transaction(self._conn):
            previous = self._lock_for_void(params)
            row = self._lock_booking_to_void(params)
            if (
                row.status == stored("anulada")
                and row.canceled_by == admin_id
                and row.reason == reason
            ):
                self._conn.rollback()
                return self._detail(booking_id)
            if row.status != stored("activa") or row.started or not row.as_seen:
                raise ConcurrentChange("la reserva ya no está activa, ya empezó o cambió")
            self._conn.execute(
                text(
                    "UPDATE booking SET status = 'voided', reason = :reason,"
                    " canceled_at = now(), canceled_by = :admin_id WHERE id = :id"
                ),
                params,
            )
            # The notice is queued in the same transaction, after the usual locks.
            enqueue_forced_cancellation(self._conn, previous.user_id, [booking_id])
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
                " count(*) FILTER (WHERE r.current_status = 'active') AS active_count,"
                " count(*) FILTER (WHERE r.current_status = 'completed') AS completed_count,"
                " count(*) FILTER (WHERE r.current_status = 'voided') AS voided_count"
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
            conditions.append("r.current_status = :status")
            params["status"] = stored(filters.status)
            total_of = "count(*) FILTER (WHERE r.current_status = :status)"
        total, counters = self._count(common, total_of, params)
        page = max(1, filters.page)
        rows = self._conn.execute(
            text(
                f"SELECT {_HISTORY_COLUMNS}{_HISTORY_JOIN}"
                f" WHERE {' AND '.join(['true', *conditions])}"
                " ORDER BY r.starts_at DESC, r.id DESC LIMIT :page_size OFFSET :offset"
            ),
            params | {"page_size": PAGE_SIZE, "offset": (page - 1) * PAGE_SIZE},
        ).all()
        self._conn.rollback()
        return BookingHistory(
            bookings=[BookingHistoryEntry(**_booking_values(r._mapping)) for r in rows],
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
        return None if row is None else BookingHistoryEntry(**_booking_values(row._mapping))


def bookings_repository(conn: DbConnection) -> BookingsSql:
    return BookingsSql(conn)
