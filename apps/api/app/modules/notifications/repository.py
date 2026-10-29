# kit-shape: the notice repository and the function that builds its row go together
from collections.abc import Sequence
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Row, text

from app.modules.notifications.rules import (
    LEAD_TIME_BY_KIND,
    REMINDER_GRACE,
    SENDING_TIMEOUT,
    Delivery,
    LostNotice,
    Notice,
    Notification,
    PendingNotice,
    Recipient,
    Reminder,
    ReminderKind,
    VoidedBooking,
    forced_cancellation_message,
    forced_cancellations_message,
    notice_data,
)
from app.shared.db import DbConnection, in_transaction
from app.shared.stored_values import contract, stored

# How many notifications the center brings: the newest ones.
CENTER_LIMIT = 100


# First number of the `pg_advisory_xact_lock` pair used to serialize, per person, the grouping
# of voiding notices.
_VOIDING_LOCK = 2402


def enqueue_forced_cancellation(
    conn: Connection, user_id: UUID, booking_ids: Sequence[UUID]
) -> None:
    """Registers in the center of [user_id] the notice of the bookings the club cancelled, with
    the delivery pending, inside the caller's transaction: no commit, so if the cancellation
    does not complete there is no notice.

    A booking that already has a notice is skipped. If the person has an unread voiding
    notice, a new one opens with the total count and the previous one is replaced, whether or
    not it is going out right now: each booking stays linked to the notice that informed it. If
    the previous one had not gone out, its bookings move to the new one.
    """
    _lock_voidings(conn, user_id)
    fresh = _voided_without_notice(conn, user_id, booking_ids)
    if not fresh:
        return
    previous = _unread_notice(conn, user_id)
    # One that is going out is also replaced: it goes out anyway and its push is overwritten by
    # the new one in the tray, but the center has to show only one.
    total = len(fresh) + (0 if previous is None else int(previous.total))
    notification_id = _open_notice(conn, user_id, fresh, total)
    if previous is not None:
        _replace_notice(conn, previous, notification_id)
    for r in fresh:
        conn.execute(
            text(
                "INSERT INTO notification_booking (notification_id, booking_id)"
                " VALUES (:notification, :booking)"
            ),
            {"notification": notification_id, "booking": r.booking_id},
        )


def _lock_voidings(conn: Connection, user_id: UUID) -> None:
    # It is the last lock of the transaction: simultaneous voidings of the same person wait
    # here, after the locks of the account, the venue, the space and the booking.
    conn.execute(
        text("SELECT pg_advisory_xact_lock(:ns, hashtext(CAST(:user_id AS text)))"),
        {"ns": _VOIDING_LOCK, "user_id": user_id},
    )


def _voided_without_notice(
    conn: Connection, user_id: UUID, booking_ids: Sequence[UUID]
) -> list[VoidedBooking]:
    rows = conn.execute(
        text(
            "SELECT b.id, b.starts_at, s.sport, s.kind, v.name AS venue, b.reason"
            " FROM booking b JOIN space s ON s.id = b.space_id"
            " JOIN venue v ON v.id = s.venue_id"
            " WHERE b.id = ANY(:ids) AND b.user_id = :user_id AND b.status = :voided"
            " AND NOT EXISTS (SELECT 1 FROM notification_booking nb WHERE nb.booking_id = b.id)"
            " ORDER BY b.starts_at, b.id"
        ),
        {"ids": list(booking_ids), "user_id": user_id, "voided": stored("anulada")},
    ).all()
    return [
        VoidedBooking(
            booking_id=row.id,
            starts_at=row.starts_at,
            sport=row.sport,
            kind=row.kind,
            venue=row.venue,
            reason=row.reason or "",
        )
        for row in rows
    ]


def _unread_notice(conn: Connection, user_id: UUID) -> Row[Any] | None:
    return conn.execute(
        text(
            "SELECT n.id, n.delivery, coalesce(n.count, 1) AS total FROM notification n"
            " WHERE n.user_id = :user_id AND n.kind = :kind"
            " AND n.read_at IS NULL AND n.replaced_by IS NULL"
            " ORDER BY n.id DESC LIMIT 1 FOR UPDATE"
        ),
        {"user_id": user_id, "kind": stored("cancelacion_forzosa")},
    ).first()


def _open_notice(conn: Connection, user_id: UUID, fresh: list[VoidedBooking], total: int) -> UUID:
    notice = (
        forced_cancellations_message(total) if total > 1 else forced_cancellation_message(fresh)
    )
    single = fresh[0] if total == 1 else None
    notification_id: UUID = conn.execute(
        text(
            "INSERT INTO notification (user_id, kind, title, body, booking_id,"
            " booking_starts_at, delivery, count) VALUES (:user_id, :kind,"
            " :title, :body, :booking, :starts_at, :delivery, :total) RETURNING id"
        ),
        {
            "user_id": user_id,
            "kind": stored("cancelacion_forzosa"),
            "title": notice.title,
            "body": notice.body,
            "booking": None if single is None else single.booking_id,
            "starts_at": None if single is None else single.starts_at,
            "delivery": stored("pendiente"),
            "total": total,
        },
    ).scalar_one()
    return notification_id


def _replace_notice(conn: Connection, previous: Row[Any], notification_id: UUID) -> None:
    conn.execute(
        text("UPDATE notification SET replaced_by = :replacement WHERE id = :id"),
        {"replacement": notification_id, "id": previous.id},
    )
    if contract(previous.delivery) == "pendiente":
        conn.execute(
            text(
                "UPDATE notification_booking SET notification_id = :replacement"
                " WHERE notification_id = :id"
            ),
            {"replacement": notification_id, "id": previous.id},
        )


def _reminder_of(row: Row[Any], kind: ReminderKind) -> Reminder:
    return Reminder(
        booking_id=row.id,
        user_id=row.user_id,
        starts_at=row.starts_at,
        ends_at=row.ends_at,
        sport=row.sport,
        kind=row.kind,
        venue=row.venue,
        email=row.email,
        name=row.user_name,
        reminder_kind=kind,
    )


class NotificationsSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def enqueue_user_cancellation(
        self, user_id: UUID, booking_id: UUID, starts_at: datetime, notice: Notice
    ) -> None:
        """Leaves the notice of the cancellation the person made, inside the caller's
        transaction: no commit. The unique index avoids repeating it."""
        self._conn.execute(
            text(
                "INSERT INTO notification (user_id, kind, title, body, booking_id,"
                " booking_starts_at, delivery) VALUES (:user_id, :kind, :title,"
                " :body, :id, :starts_at, :delivery)"
                " ON CONFLICT (booking_id) WHERE kind = 'user_cancellation' DO NOTHING"
            ),
            {
                "user_id": user_id,
                "kind": stored("cancelacion_usuario"),
                "id": booking_id,
                "title": notice.title,
                "body": notice.body,
                "starts_at": starts_at,
                "delivery": stored("pendiente"),
            },
        )

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        return [r for kind in LEAD_TIME_BY_KIND for r in self._due_of(kind, now, user_id)]

    def _due_of(self, kind: ReminderKind, now: datetime, user_id: UUID | None) -> list[Reminder]:
        rows = self._conn.execute(
            text(
                "SELECT b.id, b.user_id, b.starts_at, b.ends_at, s.sport, s.kind, v.name AS venue,"
                " u.email, u.first_name AS user_name"
                " FROM booking b JOIN space s ON s.id = b.space_id"
                " JOIN venue v ON v.id = s.venue_id JOIN app_user u ON u.id = b.user_id"
                " WHERE b.status = :active AND u.active"
                " AND b.starts_at > :now"
                " AND b.starts_at <= :now + CAST(:lead_time AS interval)"
                # A booking made or moved with less lead time than the notice gets no notice.
                " AND greatest(b.created_at, b.updated_at)"
                " <= b.starts_at - CAST(:lead_time AS interval)"
                " AND (CAST(:user_id AS uuid) IS NULL OR b.user_id = :user_id)"
                " AND NOT EXISTS (SELECT 1 FROM notification n WHERE n.booking_id = b.id"
                " AND n.kind = :notice_kind AND n.booking_starts_at = b.starts_at)"
                " ORDER BY b.starts_at, b.id"
            ),
            {
                "now": now,
                "user_id": user_id,
                "lead_time": LEAD_TIME_BY_KIND[kind],
                "notice_kind": stored(kind),
                "active": stored("activa"),
            },
        ).all()
        self._conn.rollback()
        return [_reminder_of(row, kind) for row in rows]

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        params = {
            "user_id": reminder.user_id,
            "title": notice.title,
            "body": notice.body,
            "booking": reminder.booking_id,
            "starts_at": reminder.starts_at,
            "lead_time": LEAD_TIME_BY_KIND[reminder.reminder_kind],
            "notice_kind": stored(reminder.reminder_kind),
            "active": stored("activa"),
            "delivery": stored("pendiente"),
        }
        with in_transaction(self._conn):
            # Between `due` looking and here, the booking may have been cancelled, voided or
            # moved, or the account closed. It is looked at again with the account and the
            # booking shared, in the order of the bookings, so neither changes until commit.
            if not self._still_current(params):
                self._conn.rollback()
                return None
            row = self._conn.execute(
                text(
                    "INSERT INTO notification (user_id, kind, title, body, booking_id,"
                    " booking_starts_at, delivery) VALUES (:user_id, :notice_kind, :title, :body,"
                    " :booking, :starts_at, :delivery)"
                    # No target: each kind has its own partial unique index, and one whose
                    # predicate has a parameter cannot be inferred.
                    " ON CONFLICT DO NOTHING RETURNING id"
                ),
                params,
            ).first()
        return None if row is None else row.id

    def _still_current(self, params: dict[str, Any]) -> bool:
        account = self._conn.execute(
            text("SELECT 1 FROM app_user WHERE id = :user_id AND active FOR SHARE"),
            {"user_id": params["user_id"]},
        ).first()
        if account is None:
            return False
        current = self._conn.execute(
            text(
                "SELECT 1 FROM booking WHERE id = :booking AND status = :active"
                " AND starts_at = :starts_at AND starts_at > now()"
                " AND greatest(created_at, updated_at)"
                " <= starts_at - CAST(:lead_time AS interval)"
                " FOR SHARE"
            ),
            {
                "booking": params["booking"],
                "active": params["active"],
                "starts_at": params["starts_at"],
                "lead_time": params["lead_time"],
            },
        ).first()
        return current is not None

    def recipient(self, user_id: UUID) -> Recipient | None:
        row = self._conn.execute(
            text("SELECT email, first_name FROM app_user WHERE id = :user_id AND active"),
            {"user_id": user_id},
        ).first()
        self._conn.rollback()
        return None if row is None else Recipient(email=row.email, name=row.first_name)

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        rows = self._conn.execute(
            text(
                "SELECT token FROM device WHERE user_id = :user_id AND active"
                " AND permission_granted ORDER BY id"
            ),
            {"user_id": user_id},
        ).all()
        self._conn.rollback()
        return [row.token for row in rows]

    def has_devices(self, user_id: UUID) -> bool:
        exists: bool = self._conn.execute(
            text("SELECT EXISTS (SELECT 1 FROM device WHERE user_id = :user_id AND active)"),
            {"user_id": user_id},
        ).scalar_one()
        self._conn.rollback()
        return bool(exists)

    def fail_stranded(self, user_id: UUID | None) -> list[LostNotice]:
        with in_transaction(self._conn):
            # A registered reminder whose slot already started or was cancelled never goes out.
            dead = self._conn.execute(
                text(
                    "UPDATE notification n SET delivery = :failed WHERE n.delivery = :pending"
                    " AND n.kind IN (:reminder, :five_minute_reminder)"
                    " AND (CAST(:user_id AS uuid) IS NULL OR n.user_id = :user_id)"
                    " AND NOT EXISTS (SELECT 1 FROM booking b WHERE b.id = n.booking_id"
                    " AND b.status = :active AND b.starts_at = n.booking_starts_at"
                    " AND b.starts_at > now()) RETURNING n.id, n.kind"
                ),
                {
                    "user_id": user_id,
                    "failed": stored("fallida"),
                    "pending": stored("pendiente"),
                    "reminder": stored("recordatorio"),
                    "five_minute_reminder": stored("recordatorio_cinco"),
                    "active": stored("activa"),
                },
            ).all()
            # One that stays `sending` too long was left mid-send: it is not sent again.
            stuck = self._conn.execute(
                text(
                    "UPDATE notification SET delivery = :failed WHERE delivery = :sending"
                    " AND sending_since < now() - CAST(:timeout AS interval)"
                    " AND (CAST(:user_id AS uuid) IS NULL OR user_id = :user_id)"
                    " RETURNING id, kind"
                ),
                {
                    "user_id": user_id,
                    "timeout": SENDING_TIMEOUT,
                    "failed": stored("fallida"),
                    "sending": stored("enviando"),
                },
            ).all()
        return [LostNotice(row.id, contract(row.kind)) for row in [*dead, *stuck]]

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
        # The ones that go out: the pending ones, and reminders only if still current and the
        # minute of whoever registered them has passed. `sending` is the claim: it avoids
        # sending it twice.
        row = self._conn.execute(
            text(
                "UPDATE notification SET delivery = :sending, sending_since = now() WHERE id = ("
                " SELECT n.id FROM notification n LEFT JOIN booking b ON b.id = n.booking_id"
                " WHERE n.replaced_by IS NULL"
                " AND (CAST(:user_id AS uuid) IS NULL OR n.user_id = :user_id)"
                " AND n.delivery = :pending"
                " AND (n.kind NOT IN (:reminder, :five_minute_reminder)"
                " OR (n.created_at < now() - CAST(:grace AS interval)"
                " AND b.status = :active AND b.starts_at = n.booking_starts_at"
                " AND b.starts_at > now()))"
                " ORDER BY n.id LIMIT 1 FOR UPDATE OF n SKIP LOCKED)"
                " RETURNING id, user_id, kind, title, body, booking_id"
            ),
            {
                "user_id": user_id,
                "grace": REMINDER_GRACE,
                "sending": stored("enviando"),
                "pending": stored("pendiente"),
                "reminder": stored("recordatorio"),
                "five_minute_reminder": stored("recordatorio_cinco"),
                "active": stored("activa"),
            },
        ).first()
        self._conn.commit()
        if row is None:
            return None
        return PendingNotice(
            notification_id=row.id,
            user_id=row.user_id,
            notice=Notice(
                title=row.title,
                body=row.body,
                data=notice_data(contract(row.kind), row.booking_id),
            ),
        )

    def mark_delivery(self, notification_id: UUID, delivery: Delivery) -> None:
        self._conn.execute(
            text(
                "UPDATE notification SET delivery = CAST(:delivery AS text),"
                " sent_at = CASE WHEN CAST(:delivery AS text) = :sent THEN now() END"
                " WHERE id = :id"
            ),
            {"delivery": stored(delivery), "sent": stored("enviada"), "id": notification_id},
        )
        self._conn.commit()

    def deactivate_tokens(self, tokens: Sequence[str]) -> None:
        if not tokens:
            return
        self._conn.execute(
            text(
                "UPDATE device SET active = false, deactivated_at = now()"
                " WHERE token = ANY(:tokens) AND active"
            ),
            {"tokens": list(tokens)},
        )
        self._conn.commit()

    def register_device(
        self,
        user_id: UUID,
        token: str,
        platform: str,
        permission: bool,  # noqa: FBT001
    ) -> bool:
        params = {
            "user_id": user_id,
            "token": token,
            "platform": platform,
            "permission": permission,
        }
        with in_transaction(self._conn):
            # The account is taken shared, as when booking: it is not closed in between.
            account = self._conn.execute(
                text("SELECT 1 FROM app_user WHERE id = :user_id AND active FOR SHARE"),
                {"user_id": user_id},
            ).first()
            if account is None:
                self._conn.rollback()
                return False
            self._conn.execute(
                text(
                    "INSERT INTO device (user_id, token, platform, permission_granted)"
                    " VALUES (:user_id, :token, :platform, :permission)"
                    " ON CONFLICT (token) WHERE active DO UPDATE SET"
                    " user_id = EXCLUDED.user_id, platform = EXCLUDED.platform,"
                    " permission_granted = EXCLUDED.permission_granted, updated_at = now()"
                    " WHERE device.user_id = EXCLUDED.user_id"
                ),
                params,
            )
        return True

    def unregister_device(self, user_id: UUID, token: str) -> None:
        self._conn.execute(
            text(
                "UPDATE device SET active = false, deactivated_at = now()"
                " WHERE user_id = :user_id AND token = :token AND active"
            ),
            {"user_id": user_id, "token": token},
        )
        self._conn.commit()

    def of_user(self, user_id: UUID) -> tuple[list[Notification], int]:
        rows = self._conn.execute(
            text(
                "SELECT id, kind, title, body, booking_id, created_at,"
                " read_at IS NOT NULL AS is_read FROM notification WHERE user_id = :user_id"
                " AND replaced_by IS NULL"
                f" ORDER BY created_at DESC, id DESC LIMIT {CENTER_LIMIT}"
            ),
            {"user_id": user_id},
        ).all()
        unread: int = self._conn.execute(
            text(
                "SELECT count(*) FROM notification WHERE user_id = :user_id AND read_at IS NULL"
                " AND replaced_by IS NULL"
            ),
            {"user_id": user_id},
        ).scalar_one()
        self._conn.rollback()
        return (
            [
                Notification(
                    id=row.id,
                    kind=contract(row.kind),
                    title=row.title,
                    body=row.body,
                    booking_id=row.booking_id,
                    created_at=row.created_at,
                    read=bool(row.is_read),
                )
                for row in rows
            ],
            int(unread),
        )

    def read(self, user_id: UUID, notification_id: UUID) -> bool:
        row = self._conn.execute(
            text(
                "UPDATE notification SET read_at = coalesce(read_at, now())"
                " WHERE id = :id AND user_id = :user_id RETURNING id"
            ),
            {"id": notification_id, "user_id": user_id},
        ).first()
        self._conn.commit()
        return row is not None

    def read_all(self, user_id: UUID) -> None:
        self._conn.execute(
            text(
                "UPDATE notification SET read_at = now()"
                " WHERE user_id = :user_id AND read_at IS NULL"
            ),
            {"user_id": user_id},
        )
        self._conn.commit()


def notifications_repository(conn: DbConnection) -> NotificationsSql:
    return NotificationsSql(conn)
