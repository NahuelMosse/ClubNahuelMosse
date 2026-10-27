from collections.abc import Callable
from datetime import date, datetime, time, timedelta
from uuid import UUID

from app.modules.bookings.rules import (
    Booking,
    BookingHistory,
    BookingHistoryEntry,
    HistoryFilters,
)
from app.modules.bookings.rules import When as When
from app.modules.bookings.store import Bookings
from app.modules.horarios import DIAS_A_LA_VISTA, Agenda, error_de_duracion, rango, validar_reserva
from app.modules.sesion import Perfil
from app.shared.errors import (
    Forbidden,
    InvalidData,
    NotFound,
    OpeningHoursChanged,
    SlotTaken,
    Unavailable,
)

# Maximum length of the reason of a voiding.
MAX_REASON_LENGTH = 500
# How many times it is validated again if the opening hours of the venue change while saving.
ATTEMPTS_WITH_NEW_HOURS = 3


def _with_current_hours(
    bookings: Bookings,
    space_id: UUID,
    validate: Callable[[Agenda], dict[str, str]],
    save: Callable[[Agenda], Booking],
) -> Booking:
    """Validates the slot with the opening hours of the venue and saves. If an administrator
    changed the hours in between, it validates again with the new ones: what is saved respects
    the hours in force when it is saved (RF 3)."""
    for _ in range(ATTEMPTS_WITH_NEW_HOURS):
        opening_hours = bookings.opening_hours(space_id)
        if opening_hours is None:
            raise Unavailable("el espacio no está activo")
        errors = validate(opening_hours)
        if errors:
            raise InvalidData(errors)
        try:
            return save(opening_hours)
        except OpeningHoursChanged:
            continue
    raise SlotTaken("el horario de la sede cambió varias veces seguidas")


def my_bookings(bookings: Bookings, perfil: Perfil, when: When) -> list[Booking]:
    """The bookings of whoever asks and of nobody else (RF 3, RF 6)."""
    return bookings.of_user(perfil.id, when)


def _require_day_in_view(day: date, now: datetime) -> None:
    """A date beyond the booking window is rejected before computing the end of the slot:
    near `date.max` that computation overflows."""
    if day >= now.date() + timedelta(days=DIAS_A_LA_VISTA):
        raise InvalidData({"fecha": f"Elegí un día de los próximos {DIAS_A_LA_VISTA}"})


def _require_same_kind(bookings: Bookings, current: Booking, space_id: UUID) -> None:
    new = bookings.space_kind(space_id)
    if new is None or new != (current.venue_id, current.sport, current.kind):
        raise InvalidData({"espacio_id": "Elegí una cancha del mismo tipo en la misma sede"})


def book(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    bookings: Bookings,
    perfil: Perfil,
    space_id: UUID,
    day: date,
    start_time: time | None,
    hours: int,
    now: datetime,
) -> Booking:
    """Books [hours] hours of the space from [start_time] on [day], in the club time that
    [now] carries (RF 3). The backend validates the slot and the overlap before saving.

    Raises `Forbidden` if whoever asks is an administrator, `InvalidData` if the slot cannot
    be booked, `Unavailable` and `SlotTaken` as `Bookings.insert`.
    """
    if perfil.rol != "usuario":
        raise Forbidden("sólo un usuario reserva")
    if start_time is None:
        raise InvalidData({"desde": "Elegí una hora en punto"})
    if error := error_de_duracion(hours):
        # Before computing the end of the slot: with an excessive duration that computation
        # overflows. `hasta` is the field the clients already read.
        raise InvalidData({"horas": error, "hasta": error})
    _require_day_in_view(day, now)
    starts_at, _ = rango(day, start_time, start_time, now.tzinfo)
    ends_at = starts_at + timedelta(hours=hours)
    # A retry after a cut can arrive when the slot already started: if the booking was made,
    # it is returned without validating the slot again.
    if already := bookings.repeated(perfil.id, space_id, starts_at, ends_at):
        return already
    return _with_current_hours(
        bookings,
        space_id,
        lambda opening_hours: validar_reserva(opening_hours, day, start_time, hours, now),
        lambda opening_hours: bookings.insert(
            perfil.id, space_id, starts_at, ends_at, opening_hours
        ),
    )


def cancel_booking(bookings: Bookings, perfil: Perfil, booking_id: UUID) -> Booking:
    """Cancels an own booking that has not started yet (CU-10, decision 13: until the start,
    no minimum notice)."""
    return bookings.cancel(perfil.id, booking_id)


def modify_booking(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    bookings: Bookings,
    perfil: Perfil,
    booking_id: UUID,
    space_id: UUID,
    day: date,
    start_time: time | None,
    now: datetime,
) -> Booking:
    """Changes the court, the day or the time of an own booking, with the same duration
    (CU-11). The booking keeps its number.

    Raises `Forbidden` if whoever asks is an administrator, `NotFound` if the booking is not
    theirs, `InvalidData` if the new slot is not valid, and `Unavailable`,
    `ConcurrentChange` and `SlotTaken` as `Bookings.move`.
    """
    if perfil.rol != "usuario":
        raise Forbidden("sólo un usuario reserva")
    if start_time is None:
        raise InvalidData({"desde": "Elegí una hora en punto"})
    _require_day_in_view(day, now)
    current = bookings.own(perfil.id, booking_id)
    if current is None:
        raise NotFound("no hay una reserva suya con ese número")
    start, _ = rango(day, start_time, start_time, now.tzinfo)
    # A retry after a cut arrives with the booking already moved: it is returned as it is.
    if current.status == "activa" and (current.space_id, current.starts_at) == (space_id, start):
        return current
    _require_same_kind(bookings, current, space_id)
    duration = current.ends_at - current.starts_at
    before = (current.space_id, current.starts_at)
    return _with_current_hours(
        bookings,
        space_id,
        lambda hours: validar_reserva(hours, day, start_time, duration // timedelta(hours=1), now),
        lambda hours: bookings.move(
            perfil.id, booking_id, before, space_id, start, start + duration, hours
        ),
    )


def global_history(bookings: Bookings, perfil: Perfil, filters: HistoryFilters) -> BookingHistory:
    """The complete history of bookings of all users and all venues (CU-14, RF 6): only an
    administrator reads it. It modifies nothing (the query is read-only).

    Raises `Forbidden` if whoever asks is not an administrator and `InvalidData` if the date
    range has `since` after `until`.
    """
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador consulta el historial global")
    if filters.since is not None and filters.until is not None and filters.since > filters.until:
        raise InvalidData({"fechas": "Desde no puede ser posterior a Hasta"})
    return bookings.history(filters)


def admin_detail(bookings: Bookings, perfil: Perfil, booking_id: UUID) -> BookingHistoryEntry:
    """The detail of any booking of the system, for an administrator (CU-14).

    Raises `Forbidden` if whoever asks is not an administrator and `NotFound` if there is no
    booking with that number.
    """
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador consulta el detalle de cualquier reserva")
    detail = bookings.any_one(booking_id)
    if detail is None:
        raise NotFound("no hay una reserva con ese número")
    return detail


def void_booking(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    bookings: Bookings,
    perfil: Perfil,
    booking_id: UUID,
    reason: str,
    space_id: UUID,
    starts_at: datetime,
) -> BookingHistoryEntry:
    """Voids for an operational cause an active booking that has not started yet (CU-15,
    RF 3): the slot becomes free again and the booking keeps who voided it, when and why.

    Raises `Forbidden` if whoever asks is not an administrator, `InvalidData` if the reason
    is empty or too long, and `NotFound` and `ConcurrentChange` as `Bookings.void`.
    """
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador anula una reserva")
    clean = reason.strip()
    if not clean:
        raise InvalidData({"motivo": "El motivo es obligatorio para anular"})
    if len(clean) > MAX_REASON_LENGTH:
        raise InvalidData({"motivo": f"El motivo admite hasta {MAX_REASON_LENGTH} caracteres"})
    return bookings.void(perfil.id, booking_id, clean, space_id, starts_at)
