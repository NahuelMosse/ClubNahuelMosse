# kit-shape: the spaces repository contract and the use cases that rely on it are read together
from collections.abc import Callable
from typing import Protocol
from uuid import UUID

from app.modules.session import Profile
from app.modules.spaces.rules import (
    CATALOG,
    NewSpace,
    Space,
    SpaceChange,
    SpaceData,
    SpaceVenue,
    Sport,
    SuggestedName,
    catalog_kind,
    composite_name,
    validate_change,
    validate_space,
)
from app.shared.errors import Forbidden, InvalidData, Unavailable


class Spaces(Protocol):
    def active(
        self,
        venue_id: UUID | None = None,
        sport: str | None = None,
        kind: str | None = None,
    ) -> list[Space]: ...

    def next_number(
        self,
        venue_id: UUID,
        sport: str,
        kind: str,
        name: Callable[[SpaceVenue, int], str],
    ) -> SuggestedName | None:
        """The number and name that come next for that kind in that venue, or `None` if the
        venue is not active. Numbers of deactivated spaces are not reused."""
        ...

    def insert(
        self,
        new: NewSpace,
        number: int | None,
        name: Callable[[SpaceVenue, int], str],
        author: UUID,
    ) -> Space:
        """Saves the space with the next number.

        If [number] is no longer the next one, raises `NumberTaken` with the one that follows,
        unless the same [author] took that number a moment ago with the same data: it is
        their own request repeated after a cut, and it is returned. Raises `Unavailable` if
        the venue is no longer active.
        """
        ...

    def update(self, space_id: UUID, change: SpaceChange, author: UUID) -> Space:
        """Saves the change of the active space [space_id]. Bookings already made keep the
        price they were made with.

        Raises `NotFound` if the space or its venue is no longer active.
        """
        ...

    def deactivate(self, space_id: UUID, author: UUID) -> None:
        """Deactivates the active space [space_id] on behalf of [author]. Past bookings
        still name it.

        Raises `NotFound` if it is no longer active and `HasFutureBookings` if it has an
        active booking that has not ended yet.
        """
        ...


def _admin_only(profile: Profile) -> None:
    if profile.role != "admin":
        raise Forbidden("sólo un administrador gestiona espacios")


def catalog() -> tuple[Sport, ...]:
    return CATALOG


def _name(sport: str, kind: str) -> Callable[[SpaceVenue, int], str]:
    return lambda venue, number: composite_name(
        venue.name, venue.street, venue.street_number, sport, kind, number
    )


def suggested_name(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    profile: Profile, venue_id: UUID, sport: str, kind: str, spaces: Spaces
) -> SuggestedName:
    """The name the next space of that kind in that venue would have."""
    _admin_only(profile)
    if catalog_kind(sport, kind) is None:
        raise InvalidData({"kind": "Elegí un tipo de la lista"})
    suggested = spaces.next_number(venue_id, sport, kind, _name(sport, kind))
    if suggested is None:
        raise Unavailable("la sede no está activa")
    return suggested


def create_space(profile: Profile, data: SpaceData, number: int | None, spaces: Spaces) -> Space:
    """Registers an active space with the composite name of the assignment (RF 5).

    [number] is the one the administrator saw: if another creation took it in the meantime,
    raises `NumberTaken` with the next one, so they see it before saving.
    """
    _admin_only(profile)
    new, errors = validate_space(data)
    if new is None:
        raise InvalidData(errors)
    return spaces.insert(new, number, _name(new.sport, new.kind), profile.id)


def active_spaces(
    spaces: Spaces,
    venue_id: UUID | None = None,
    sport: str | None = None,
    kind: str | None = None,
) -> list[Space]:
    """The spaces that can be booked, by venue, sport, kind and number; only those of
    [venue_id], [sport] and [kind] if given."""
    return spaces.active(venue_id, sport, kind)


def update_space(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    profile: Profile,
    space_id: UUID,
    covered: bool | None,  # noqa: FBT001
    lit: bool | None,  # noqa: FBT001
    price_per_hour: int | None,
    given: frozenset[str],
    spaces: Spaces,
) -> Space:
    """Corrects the covering, lighting or price of a space (CU-22); only what is in [given]
    changes. The new price applies to the bookings that come."""
    _admin_only(profile)
    change, errors = validate_change(covered, lit, price_per_hour, given=given)
    if change is None:
        raise InvalidData(errors)
    return spaces.update(space_id, change, profile.id)


def deactivate_space(profile: Profile, space_id: UUID, spaces: Spaces) -> None:
    """Withdraws a space (CU-23): it stops being shown and bookable. Not allowed with
    pending bookings (decision 5): forced cancellation belongs to CU-15."""
    _admin_only(profile)
    spaces.deactivate(space_id, profile.id)
