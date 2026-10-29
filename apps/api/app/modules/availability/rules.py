"""The slots that can be booked in a space: whole hours, inside the opening hours of its
venue and in the future (RF 3)."""

from collections.abc import Sequence
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta, tzinfo

MIN_HOURS = 1
MAX_HOURS = 4
DAYS_IN_VIEW = 7
HOURS_PER_DAY = 24


@dataclass(frozen=True)
class OpeningHours:
    """The hours of the venue of a space: opens at [opens_at] and closes at [closes_at] on
    the [open_days] of the week (1 is Monday). A closing at 00:00 is the midnight of the same
    day."""

    opens_at: time
    closes_at: time
    open_days: tuple[int, ...]


@dataclass(frozen=True)
class Slot:
    start: datetime
    end: datetime
    available: bool


@dataclass(frozen=True)
class SlotGrid:
    day: date
    today: date
    opens: bool
    slots: tuple[Slot, ...]

    @property
    def unavailable(self) -> int:
        return sum(1 for s in self.slots if not s.available)


def validate_query(day: date, today: date, hours: int) -> dict[str, str]:
    """The errors of a slot query, by field (keys are the JSON names of the API)."""
    errors: dict[str, str] = {}
    if not today <= day < today + timedelta(days=DAYS_IN_VIEW):
        errors["date"] = f"Elegí un día de los próximos {DAYS_IN_VIEW}"
    if not MIN_HOURS <= hours <= MAX_HOURS:
        errors["hours"] = f"La duración va de {MIN_HOURS} a {MAX_HOURS} horas"
    return errors


def slot_grid(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    opening_hours: OpeningHours,
    day: date,
    hours: int,
    now: datetime,
    taken: Sequence[tuple[datetime, datetime]],
) -> SlotGrid:
    """Every start on the hour from the opening whose slot of [hours] ends before the
    closing and has not started at [now], which carries the club's time zone. It is
    available if it does not overlap any of the [taken] ones."""
    today = now.date()
    if day.isoweekday() not in opening_hours.open_days:
        return SlotGrid(day=day, today=today, opens=False, slots=())
    zone = now.tzinfo
    closing = datetime.combine(day, opening_hours.closes_at, tzinfo=zone)
    if opening_hours.closes_at == time(0, 0):
        closing += timedelta(days=1)
    duration = timedelta(hours=hours)
    start = datetime.combine(day, opening_hours.opens_at, tzinfo=zone)
    slots: list[Slot] = []
    while start + duration <= closing:
        end = start + duration
        if start > now:
            free = not any(since < end and until > start for since, until in taken)
            slots.append(Slot(start=start, end=end, available=free))
        start += timedelta(hours=1)
    return SlotGrid(day=day, today=today, opens=True, slots=tuple(slots))


def _hhmm(hour: time) -> str:
    return hour.strftime("%H:%M")


def time_range(
    day: date, since: time, until: time, zone: tzinfo | None
) -> tuple[datetime, datetime]:
    """Start and end of [since, until) on [day]; an [until] of 00:00 is the midnight."""
    start = datetime.combine(day, since, tzinfo=zone)
    end = datetime.combine(day, until, tzinfo=zone)
    if until == time(0, 0):
        end += timedelta(days=1)
    return start, end


def _date_error(opening_hours: OpeningHours, day: date, today: date) -> str | None:
    if day < today:
        return "La fecha tiene que ser futura"
    if day >= today + timedelta(days=DAYS_IN_VIEW):
        return f"Elegí un día de los próximos {DAYS_IN_VIEW}"
    if day.isoweekday() not in opening_hours.open_days:
        return "La sede no abre ese día"
    return None


def _end_error(
    opening_hours: OpeningHours, start: datetime, end: datetime, closing: datetime
) -> str | None:
    if end - start < timedelta(hours=MIN_HOURS):
        return "La duración mínima es de una hora"
    if end - start > timedelta(hours=MAX_HOURS):
        return f"La duración máxima es de {MAX_HOURS} horas"
    if end > closing:
        return f"La sede cierra a las {_hhmm(opening_hours.closes_at)}"
    return None


def validate_range(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    opening_hours: OpeningHours, day: date, since: time, until: time, now: datetime
) -> dict[str, str]:
    """The errors of a queried range, by field: in the future, in whole hours, of 1 to 4
    hours and inside the opening hours of the venue (RF 3). Keys are the JSON names of the
    API."""
    errors: dict[str, str] = {}
    date_error = _date_error(opening_hours, day, now.date())
    if date_error:
        errors["date"] = date_error
    for field, hour in (("start_hour", since), ("until", until)):
        if (hour.minute, hour.second, hour.microsecond) != (0, 0, 0):
            errors[field] = "Elegí una hora en punto"
    if errors.keys() & {"start_hour", "until"} or day >= date.max - timedelta(days=1):
        return errors
    start, end = time_range(day, since, until, now.tzinfo)
    opening, closing = time_range(day, opening_hours.opens_at, opening_hours.closes_at, now.tzinfo)
    end_error = _end_error(opening_hours, start, end, closing)
    if end_error:
        errors["until"] = end_error
    if start < opening:
        errors["start_hour"] = f"La sede abre a las {_hhmm(opening_hours.opens_at)}"
    elif "date" not in errors and start <= now:
        errors["start_hour"] = "El horario tiene que ser futuro"
    return errors


def duration_error(hours: int) -> str | None:
    """Why [hours] is not a bookable duration, or `None` if it is."""
    if hours < MIN_HOURS:
        return "La duración mínima es de una hora"
    if hours > MAX_HOURS:
        return f"La duración máxima es de {MAX_HOURS} horas"
    return None


def validate_booking(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    opening_hours: OpeningHours, day: date, since: time, hours: int, now: datetime
) -> dict[str, str]:
    """The errors of booking [hours] hours from [since] on [day]: those of a range (RF 3)
    plus a whole duration that does not go past midnight."""
    if error := duration_error(hours):
        errors = validate_range(opening_hours, day, since, since, now)
        errors["until"] = error
        return errors
    end = since.hour + hours
    if end > HOURS_PER_DAY:
        errors = validate_range(opening_hours, day, since, time(0, 0), now)
        errors["until"] = f"La sede cierra a las {_hhmm(opening_hours.closes_at)}"
        return errors
    return validate_range(opening_hours, day, since, time(end % HOURS_PER_DAY, since.minute), now)
