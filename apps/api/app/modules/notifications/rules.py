# kit-shape: the notice types and the functions that build their texts, a single concept
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Literal, Protocol
from uuid import UUID

from app.modules.espacios import CATALOGO
from app.shared.club_timezone import CLUB_TIMEZONE

NoticeKind = Literal["recordatorio", "cancelacion_forzosa", "cancelacion_usuario"]
Delivery = Literal["pendiente", "enviando", "enviada", "sin_permiso", "sin_canal", "fallida"]

LEAD_TIME = timedelta(hours=1)
WEEKDAYS = ("Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom")


@dataclass(frozen=True)
class Notice:
    """What the person is told and the data the app uses to know where to take them."""

    title: str
    body: str
    data: dict[str, str]


@dataclass(frozen=True)
class PendingNotice:
    """A notice already registered in the center that has not yet gone out to the phone."""

    notification_id: UUID
    user_id: UUID
    notice: Notice


@dataclass(frozen=True)
class DeliveryResult:
    """How many devices the service accepted and which tokens it rejected as invalid."""

    sent: int
    invalid: tuple[str, ...] = ()


class ChannelNotConfigured(Exception):
    """No notification service is configured: nothing went out to the phone."""


class PushChannel(Protocol):
    """The service that delivers the notice to the phone."""

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        """Raises `ChannelNotConfigured` if there is no service to send the notice to."""
        ...


@dataclass(frozen=True)
class Notification:
    """An entry of the notification center."""

    id: UUID
    kind: NoticeKind
    title: str
    body: str
    booking_id: UUID | None
    created_at: datetime
    read: bool


@dataclass(frozen=True)
class Reminder:
    """An active booking whose one-hour-ahead notice is due."""

    booking_id: UUID
    user_id: UUID
    starts_at: datetime
    ends_at: datetime
    sport: str
    kind: str
    venue: str


@dataclass(frozen=True)
class VoidedBooking:
    """A booking the club cancelled, with what is needed to tell whoever made it."""

    booking_id: UUID
    starts_at: datetime
    sport: str
    kind: str
    venue: str
    reason: str


# How much of the reason goes in the notice: the rest is read in the history.
REASON_LIMIT = 200

# A freshly registered reminder is being sent by whoever registered it: the dispatch takes it
# only if more than this has passed without it going out.
REMINDER_GRACE = timedelta(minutes=1)
# After this time a `enviando` notice is given up as lost: the API crashed mid-send.
SENDING_TIMEOUT = timedelta(minutes=10)


@dataclass(frozen=True)
class LostNotice:
    """A notice that was marked failed without going out: what the log needs."""

    notification_id: UUID
    kind: NoticeKind


def short_kind(sport: str, kind: str) -> str:
    """The kind name when it starts with the sport name; otherwise only the sport name."""
    d = next((d for d in CATALOGO if d.clave == sport), None)
    t = None if d is None else next((t for t in d.tipos if t.clave == kind), None)
    if d is None or t is None:
        return sport
    return t.nombre if t.nombre.startswith(d.nombre) else d.nombre


def _time(moment: datetime) -> str:
    return moment.astimezone(CLUB_TIMEZONE).strftime("%H:%M")


def reminder_message(r: Reminder) -> Notice:
    """The one-hour-ahead notice: short kind, venue and the time range."""
    return Notice(
        title="Tu reserva es en 1 hora",
        body=f"{short_kind(r.sport, r.kind)} · {r.venue} · {_time(r.starts_at)} – {_time(r.ends_at)}",
        data=notice_data("recordatorio", r.booking_id),
    )


def notice_data(kind: NoticeKind, booking_id: UUID | None) -> dict[str, str]:
    """The data the app uses to know where to take the person on tapping the notice."""
    return {"tipo": kind} | ({} if booking_id is None else {"reserva_id": str(booking_id)})


def _when(moment: datetime) -> str:
    """Weekday, day and time, in the club's time."""
    local = moment.astimezone(CLUB_TIMEZONE)
    return f"{WEEKDAYS[local.weekday()]} {local.day}, {_time(local)}"


@dataclass(frozen=True)
class BookingData:
    """What the cancellation notice needs to know about the cancelled booking."""

    id: UUID
    sport: str
    kind: str
    venue: str
    starts_at: datetime


def cancellation_message(r: BookingData) -> Notice:
    """The cancellation notice: short kind, venue and the slot in the club's time."""
    return Notice(
        title="Reserva cancelada",
        body=(
            f"{short_kind(r.sport, r.kind)} · {r.venue} · {_when(r.starts_at)}. "
            "El horario quedó liberado."
        ),
        data=notice_data("cancelacion_usuario", r.id),
    )


def forced_cancellation_message(voided: Sequence[VoidedBooking]) -> Notice:
    """The voiding notice with the booking and the reason; with several, only how many there
    are and without pointing to one in particular."""
    if len(voided) == 1:
        r = voided[0]
        reason = r.reason.strip()
        if len(reason) > REASON_LIMIT:
            reason = reason[: REASON_LIMIT - 1].rstrip() + "…"
        return Notice(
            title="El club anuló tu reserva",
            body=(
                f"{short_kind(r.sport, r.kind)} · {r.venue} · {_when(r.starts_at)}. "
                f"Motivo: {reason}."
            ),
            data=notice_data("cancelacion_forzosa", r.booking_id),
        )
    return forced_cancellations_message(len(voided))


def forced_cancellations_message(count: int) -> Notice:
    """The notice of [count] bookings voided by the club, which leads to the history."""
    return Notice(
        title=f"El club anuló {count} de tus reservas",
        body=f"Tenés {count} reservas anuladas por el club. Mirá el detalle en tu historial.",
        data=notice_data("cancelacion_forzosa", None),
    )
