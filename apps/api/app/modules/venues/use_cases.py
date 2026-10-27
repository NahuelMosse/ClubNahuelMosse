# kit-shape: the venue repository contract and the use cases that rely on it are read together
from typing import Protocol
from uuid import UUID

from app.modules.session import Profile
from app.modules.venues.rules import NewVenue, Venue, VenueData, validate_venue
from app.shared.errors import Forbidden, InvalidData


class Venues(Protocol):
    def active(self) -> list[Venue]: ...

    def insert(self, new: NewVenue, author: UUID) -> Venue:
        """Raises `Duplicate(["nombre"])` if another active venue already has that name."""
        ...

    def update(self, venue_id: UUID, data: NewVenue, author: UUID, *, confirm: bool) -> Venue:
        """Saves the new data of the active venue [venue_id]. Bookings are not touched.

        Without [confirm], raises `BookingsOutsideHours` if the new schedule leaves out active
        future bookings that the previous one admitted. Raises `NotFound` if the venue is no
        longer active and `Duplicate(["nombre"])` if another active venue already has that name.
        """
        ...

    def deactivate(self, venue_id: UUID, author: UUID) -> None:
        """Deactivates the active venue [venue_id] and its spaces, on behalf of [author]. Past
        bookings keep naming them.

        Raises `NotFound` if the venue is no longer active and `HasFutureBookings` if any of
        its spaces has an active booking that has not ended yet.
        """
        ...


def create_venue(profile: Profile, data: VenueData, venues: Venues) -> Venue:
    """Registers a new venue, active right away, on behalf of the admin who loads it."""
    if profile.role != "admin":
        raise Forbidden("sólo un administrador da de alta sedes")
    new, errors = validate_venue(data)
    if new is None:
        raise InvalidData(errors)
    return venues.insert(new, author=profile.id)


def update_venue(  # noqa: PLR0913 -- public signature fixed by its callers
    profile: Profile, venue_id: UUID, data: VenueData, *, confirm: bool, venues: Venues
) -> Venue:
    """Fixes the name, address or schedule of a venue (CU-18). Bookings already made are
    respected: the new schedule applies to the ones to come (RF 3 is validated when
    booking)."""
    if profile.role != "admin":
        raise Forbidden("sólo un administrador edita sedes")
    new, errors = validate_venue(data)
    if new is None:
        raise InvalidData(errors)
    return venues.update(venue_id, new, author=profile.id, confirm=confirm)


def active_venues(venues: Venues) -> list[Venue]:
    """The venues that are visible today, by name, with the count of active spaces of each."""
    return venues.active()


def deactivate_venue(profile: Profile, venue_id: UUID, venues: Venues) -> None:
    """Retires a venue (CU-19): it stops being shown and its spaces can no longer be booked.
    Not allowed with pending bookings (decision 5): forced cancellation belongs to CU-15."""
    if profile.role != "admin":
        raise Forbidden("sólo un administrador da de baja sedes")
    venues.deactivate(venue_id, author=profile.id)
