# kit-shape: the availability repository contract and its use case are read together
from datetime import date, datetime, timedelta
from typing import Protocol
from uuid import UUID

from app.modules.availability.rules import OpeningHours, SlotGrid, slot_grid, validate_query
from app.shared.errors import InvalidData, Unavailable


class Availability(Protocol):
    def opening_hours(self, space_id: UUID) -> OpeningHours | None:
        """The hours of the venue of the space, or `None` if the space or its venue are not
        active."""
        ...

    def taken(
        self,
        space_id: UUID,
        since: datetime,
        until: datetime,
        excluding: tuple[UUID, UUID] | None = None,
    ) -> list[tuple[datetime, datetime]]:
        """Start and end of the active bookings of the space that overlap [since, until),
        except the booking [excluding] = (number, user) if it belongs to that user."""
        ...


def available_slots(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    availability: Availability,
    space_id: UUID,
    day: date | None,
    hours: int,
    now: datetime,
    excluding: tuple[UUID, UUID] | None = None,
) -> SlotGrid:
    """The grid of the space for [day] (today if absent) with slots of [hours].

    Raises `InvalidData` if the date or the duration cannot be queried and
    `Unavailable` if the space can no longer be booked.
    """
    today = now.date()
    queried = day or today
    errors = validate_query(queried, today, hours)
    if errors:
        raise InvalidData(errors)
    opening_hours = availability.opening_hours(space_id)
    if opening_hours is None:
        raise Unavailable("el espacio no está activo")
    since = datetime.combine(queried, datetime.min.time(), tzinfo=now.tzinfo)
    taken = availability.taken(space_id, since, since + timedelta(days=2), excluding)
    return slot_grid(opening_hours, queried, hours, now, taken)
