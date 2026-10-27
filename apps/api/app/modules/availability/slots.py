# kit-shape: the availability contract and the function that uses it are read together
from datetime import date, datetime, time
from typing import Protocol
from uuid import UUID

from app.modules.availability.rules import OpeningHours, time_range, validate_range
from app.modules.spaces import Space
from app.shared.errors import InvalidData, Unavailable


class SlotSearch(Protocol):
    def venue_opening_hours(self, venue_id: UUID) -> OpeningHours | None:
        """The hours of the venue, or `None` if it is not active."""
        ...

    def free(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self, venue_id: UUID, sport: str, kind: str | None, start: datetime, end: datetime
    ) -> list[Space]:
        """The active spaces of the venue, of the sport and of the kind if given, without
        active bookings that overlap [start, end), by sport, kind and number."""
        ...


def available_spaces(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    search: SlotSearch,
    venue_id: UUID,
    sport: str,
    kind: str | None,
    day: date,
    since: time,
    until: time,
    now: datetime,
) -> list[Space]:
    """The spaces free over the whole range (CU-13).

    Raises `Unavailable` if the venue is no longer active and `InvalidData` if the range
    cannot be booked.
    """
    opening_hours = search.venue_opening_hours(venue_id)
    if opening_hours is None:
        raise Unavailable("la sede no está activa")
    errors = validate_range(opening_hours, day, since, until, now)
    if errors:
        raise InvalidData(errors)
    start, end = time_range(day, since, until, now.tzinfo)
    return search.free(venue_id, sport, kind, start, end)
