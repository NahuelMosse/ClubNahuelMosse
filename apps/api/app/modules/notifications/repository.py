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
    total = len(fresh) + (0 if previous is None else int(previous.cantidad))
    notification_id = _open_notice(conn, user_id, fresh, total)
    if previous is not None:
        _replace_notice(conn, previous, notification_id)
    for r in fresh:
        conn.execute(
            text(
                "INSERT INTO notificacion_reserva (notificacion_id, reserva_id)"
                " VALUES (:notificacion, :reserva)"
            ),
            {"notificacion": notification_id, "reserva": r.booking_id},
        )


def _lock_voidings(conn: Connection, user_id: UUID) -> None:
    # It is the last lock of the transaction: simultaneous voidings of the same person wait
    # here, after the locks of the account, the venue, the space and the booking.
    conn.execute(
        text("SELECT pg_advisory_xact_lock(:ns, hashtext(CAST(:usuario AS text)))"),
        {"ns": _VOIDING_LOCK, "usuario": user_id},
    )


def _voided_without_notice(
    conn: Connection, user_id: UUID, booking_ids: Sequence[UUID]
) -> list[VoidedBooking]:
    rows = conn.execute(
        text(
            "SELECT r.id, r.inicio, e.deporte, e.tipo, s.nombre AS sede, r.motivo"
            " FROM reserva r JOIN espacio e ON e.id = r.espacio_id"
            " JOIN sede s ON s.id = e.sede_id"
            " WHERE r.id = ANY(:ids) AND r.usuario_id = :usuario AND r.estado = 'anulada'"
            " AND NOT EXISTS (SELECT 1 FROM notificacion_reserva nr WHERE nr.reserva_id = r.id)"
            " ORDER BY r.inicio, r.id"
        ),
        {"ids": list(booking_ids), "usuario": user_id},
    ).all()
    return [
        VoidedBooking(
            booking_id=row.id,
            starts_at=row.inicio,
            sport=row.deporte,
            kind=row.tipo,
            venue=row.sede,
            reason=row.motivo or "",
        )
        for row in rows
    ]


def _unread_notice(conn: Connection, user_id: UUID) -> Row[Any] | None:
    return conn.execute(
        text(
            "SELECT n.id, n.envio, coalesce(n.cantidad, 1) AS cantidad FROM notificacion n"
            " WHERE n.usuario_id = :usuario AND n.tipo = 'cancelacion_forzosa'"
            " AND n.leida_en IS NULL AND n.reemplazada_por IS NULL"
            " ORDER BY n.id DESC LIMIT 1 FOR UPDATE"
        ),
        {"usuario": user_id},
    ).first()


def _open_notice(conn: Connection, user_id: UUID, fresh: list[VoidedBooking], total: int) -> UUID:
    notice = (
        forced_cancellations_message(total) if total > 1 else forced_cancellation_message(fresh)
    )
    single = fresh[0] if total == 1 else None
    notification_id: UUID = conn.execute(
        text(
            "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
            " reserva_inicio, envio, cantidad) VALUES (:usuario, 'cancelacion_forzosa',"
            " :titulo, :cuerpo, :reserva, :inicio, 'pendiente', :cantidad) RETURNING id"
        ),
        {
            "usuario": user_id,
            "titulo": notice.title,
            "cuerpo": notice.body,
            "reserva": None if single is None else single.booking_id,
            "inicio": None if single is None else single.starts_at,
            "cantidad": total,
        },
    ).scalar_one()
    return notification_id


def _replace_notice(conn: Connection, previous: Row[Any], notification_id: UUID) -> None:
    conn.execute(
        text("UPDATE notificacion SET reemplazada_por = :nuevo WHERE id = :id"),
        {"nuevo": notification_id, "id": previous.id},
    )
    if previous.envio == "pendiente":
        conn.execute(
            text(
                "UPDATE notificacion_reserva SET notificacion_id = :nuevo"
                " WHERE notificacion_id = :id"
            ),
            {"nuevo": notification_id, "id": previous.id},
        )


def _reminder_of(row: Row[Any], kind: ReminderKind) -> Reminder:
    return Reminder(
        booking_id=row.id,
        user_id=row.usuario_id,
        starts_at=row.inicio,
        ends_at=row.fin,
        sport=row.deporte,
        kind=row.tipo,
        venue=row.sede,
        email=row.correo,
        name=row.nombre_usuario,
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
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                " reserva_inicio, envio) VALUES (:usuario, 'cancelacion_usuario', :titulo,"
                " :cuerpo, :id, :inicio, 'pendiente')"
                " ON CONFLICT (reserva_id) WHERE tipo = 'cancelacion_usuario' DO NOTHING"
            ),
            {
                "usuario": user_id,
                "id": booking_id,
                "titulo": notice.title,
                "cuerpo": notice.body,
                "inicio": starts_at,
            },
        )

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        return [r for kind in LEAD_TIME_BY_KIND for r in self._due_of(kind, now, user_id)]

    def _due_of(self, kind: ReminderKind, now: datetime, user_id: UUID | None) -> list[Reminder]:
        rows = self._conn.execute(
            text(
                "SELECT r.id, r.usuario_id, r.inicio, r.fin, e.deporte, e.tipo, s.nombre AS sede,"
                " u.correo, u.nombre AS nombre_usuario"
                " FROM reserva r JOIN espacio e ON e.id = r.espacio_id"
                " JOIN sede s ON s.id = e.sede_id JOIN usuario u ON u.id = r.usuario_id"
                " WHERE r.estado = 'activa' AND u.activo"
                " AND r.inicio > :ahora"
                " AND r.inicio <= :ahora + CAST(:anticipacion AS interval)"
                # A booking made or moved with less lead time than the notice gets no notice.
                " AND greatest(r.creado_en, r.modificado_en)"
                " <= r.inicio - CAST(:anticipacion AS interval)"
                " AND (CAST(:usuario AS uuid) IS NULL OR r.usuario_id = :usuario)"
                " AND NOT EXISTS (SELECT 1 FROM notificacion n WHERE n.reserva_id = r.id"
                " AND n.tipo = :clase AND n.reserva_inicio = r.inicio)"
                " ORDER BY r.inicio, r.id"
            ),
            {
                "ahora": now,
                "usuario": user_id,
                "anticipacion": LEAD_TIME_BY_KIND[kind],
                "clase": kind,
            },
        ).all()
        self._conn.rollback()
        return [_reminder_of(row, kind) for row in rows]

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        params = {
            "usuario": reminder.user_id,
            "titulo": notice.title,
            "cuerpo": notice.body,
            "reserva": reminder.booking_id,
            "inicio": reminder.starts_at,
            "anticipacion": LEAD_TIME_BY_KIND[reminder.reminder_kind],
            "clase": reminder.reminder_kind,
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
                    "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                    " reserva_inicio, envio) VALUES (:usuario, :clase, :titulo, :cuerpo,"
                    " :reserva, :inicio, 'pendiente')"
                    # No target: each class has its own partial unique index, and one whose
                    # predicate has a parameter cannot be inferred.
                    " ON CONFLICT DO NOTHING RETURNING id"
                ),
                params,
            ).first()
        return None if row is None else row.id

    def _still_current(self, params: dict[str, Any]) -> bool:
        account = self._conn.execute(
            text("SELECT 1 FROM usuario WHERE id = :usuario AND activo FOR SHARE"), params
        ).first()
        if account is None:
            return False
        current = self._conn.execute(
            text(
                "SELECT 1 FROM reserva WHERE id = :reserva AND estado = 'activa'"
                " AND inicio = :inicio AND inicio > now()"
                " AND greatest(creado_en, modificado_en)"
                " <= inicio - CAST(:anticipacion AS interval)"
                " FOR SHARE"
            ),
            params,
        ).first()
        return current is not None

    def recipient(self, user_id: UUID) -> Recipient | None:
        row = self._conn.execute(
            text("SELECT correo, nombre FROM usuario WHERE id = :usuario AND activo"),
            {"usuario": user_id},
        ).first()
        self._conn.rollback()
        return None if row is None else Recipient(email=row.correo, name=row.nombre)

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        rows = self._conn.execute(
            text(
                "SELECT token FROM dispositivo WHERE usuario_id = :usuario AND activo"
                " AND permiso ORDER BY id"
            ),
            {"usuario": user_id},
        ).all()
        self._conn.rollback()
        return [row.token for row in rows]

    def has_devices(self, user_id: UUID) -> bool:
        exists: bool = self._conn.execute(
            text(
                "SELECT EXISTS (SELECT 1 FROM dispositivo WHERE usuario_id = :usuario AND activo)"
            ),
            {"usuario": user_id},
        ).scalar_one()
        self._conn.rollback()
        return bool(exists)

    def fail_stranded(self, user_id: UUID | None) -> list[LostNotice]:
        with in_transaction(self._conn):
            # A registered reminder whose slot already started or was cancelled never goes out.
            dead = self._conn.execute(
                text(
                    "UPDATE notificacion n SET envio = 'fallida' WHERE n.envio = 'pendiente'"
                    " AND n.tipo IN ('recordatorio', 'recordatorio_cinco')"
                    " AND (CAST(:usuario AS uuid) IS NULL OR n.usuario_id = :usuario)"
                    " AND NOT EXISTS (SELECT 1 FROM reserva r WHERE r.id = n.reserva_id"
                    " AND r.estado = 'activa' AND r.inicio = n.reserva_inicio"
                    " AND r.inicio > now()) RETURNING n.id, n.tipo"
                ),
                {"usuario": user_id},
            ).all()
            # One that stays `enviando` too long was left mid-send: it is not sent again.
            stuck = self._conn.execute(
                text(
                    "UPDATE notificacion SET envio = 'fallida' WHERE envio = 'enviando'"
                    " AND enviando_desde < now() - CAST(:espera AS interval)"
                    " AND (CAST(:usuario AS uuid) IS NULL OR usuario_id = :usuario)"
                    " RETURNING id, tipo"
                ),
                {"usuario": user_id, "espera": SENDING_TIMEOUT},
            ).all()
        return [LostNotice(row.id, row.tipo) for row in [*dead, *stuck]]

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
        # The ones that go out: the pending ones, and reminders only if still current and the
        # minute of whoever registered them has passed. `enviando` is the claim: it avoids
        # sending it twice.
        row = self._conn.execute(
            text(
                "UPDATE notificacion SET envio = 'enviando', enviando_desde = now() WHERE id = ("
                " SELECT n.id FROM notificacion n LEFT JOIN reserva r ON r.id = n.reserva_id"
                " WHERE n.reemplazada_por IS NULL"
                " AND (CAST(:usuario AS uuid) IS NULL OR n.usuario_id = :usuario)"
                " AND n.envio = 'pendiente'"
                " AND (n.tipo NOT IN ('recordatorio', 'recordatorio_cinco')"
                " OR (n.creado_en < now() - CAST(:espera AS interval)"
                " AND r.estado = 'activa' AND r.inicio = n.reserva_inicio AND r.inicio > now()))"
                " ORDER BY n.id LIMIT 1 FOR UPDATE OF n SKIP LOCKED)"
                " RETURNING id, usuario_id, tipo, titulo, cuerpo, reserva_id"
            ),
            {"usuario": user_id, "espera": REMINDER_GRACE},
        ).first()
        self._conn.commit()
        if row is None:
            return None
        return PendingNotice(
            notification_id=row.id,
            user_id=row.usuario_id,
            notice=Notice(
                title=row.titulo,
                body=row.cuerpo,
                data=notice_data(row.tipo, None if row.reserva_id is None else row.reserva_id),
            ),
        )

    def mark_delivery(self, notification_id: UUID, delivery: Delivery) -> None:
        self._conn.execute(
            text(
                "UPDATE notificacion SET envio = CAST(:envio AS text),"
                " enviada_en = CASE WHEN CAST(:envio AS text) = 'enviada' THEN now() END"
                " WHERE id = :id"
            ),
            {"envio": delivery, "id": notification_id},
        )
        self._conn.commit()

    def deactivate_tokens(self, tokens: Sequence[str]) -> None:
        if not tokens:
            return
        self._conn.execute(
            text(
                "UPDATE dispositivo SET activo = false, dado_de_baja_en = now()"
                " WHERE token = ANY(:tokens) AND activo"
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
            "usuario": user_id,
            "token": token,
            "plataforma": platform,
            "permiso": permission,
        }
        with in_transaction(self._conn):
            # The account is taken shared, as when booking: it is not closed in between.
            account = self._conn.execute(
                text("SELECT 1 FROM usuario WHERE id = :usuario AND activo FOR SHARE"), params
            ).first()
            if account is None:
                self._conn.rollback()
                return False
            self._conn.execute(
                text(
                    "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
                    " VALUES (:usuario, :token, :plataforma, :permiso)"
                    " ON CONFLICT (token) WHERE activo DO UPDATE SET"
                    " usuario_id = EXCLUDED.usuario_id, plataforma = EXCLUDED.plataforma,"
                    " permiso = EXCLUDED.permiso, modificado_en = now()"
                    " WHERE dispositivo.usuario_id = EXCLUDED.usuario_id"
                ),
                params,
            )
        return True

    def unregister_device(self, user_id: UUID, token: str) -> None:
        self._conn.execute(
            text(
                "UPDATE dispositivo SET activo = false, dado_de_baja_en = now()"
                " WHERE usuario_id = :usuario AND token = :token AND activo"
            ),
            {"usuario": user_id, "token": token},
        )
        self._conn.commit()

    def of_user(self, user_id: UUID) -> tuple[list[Notification], int]:
        rows = self._conn.execute(
            text(
                "SELECT id, tipo, titulo, cuerpo, reserva_id, creado_en AS creada_en,"
                " leida_en IS NOT NULL AS leida FROM notificacion WHERE usuario_id = :usuario"
                " AND reemplazada_por IS NULL"
                f" ORDER BY creado_en DESC, id DESC LIMIT {CENTER_LIMIT}"
            ),
            {"usuario": user_id},
        ).all()
        unread: int = self._conn.execute(
            text(
                "SELECT count(*) FROM notificacion WHERE usuario_id = :usuario AND leida_en IS NULL"
                " AND reemplazada_por IS NULL"
            ),
            {"usuario": user_id},
        ).scalar_one()
        self._conn.rollback()
        return (
            [
                Notification(
                    id=row.id,
                    kind=row.tipo,
                    title=row.titulo,
                    body=row.cuerpo,
                    booking_id=None if row.reserva_id is None else row.reserva_id,
                    created_at=row.creada_en,
                    read=bool(row.leida),
                )
                for row in rows
            ],
            int(unread),
        )

    def read(self, user_id: UUID, notification_id: UUID) -> bool:
        row = self._conn.execute(
            text(
                "UPDATE notificacion SET leida_en = coalesce(leida_en, now())"
                " WHERE id = :id AND usuario_id = :usuario RETURNING id"
            ),
            {"id": notification_id, "usuario": user_id},
        ).first()
        self._conn.commit()
        return row is not None

    def read_all(self, user_id: UUID) -> None:
        self._conn.execute(
            text(
                "UPDATE notificacion SET leida_en = now()"
                " WHERE usuario_id = :usuario AND leida_en IS NULL"
            ),
            {"usuario": user_id},
        )
        self._conn.commit()


def notifications_repository(conn: DbConnection) -> NotificationsSql:
    return NotificationsSql(conn)
