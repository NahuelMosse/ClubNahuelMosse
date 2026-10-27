from datetime import datetime
from typing import Protocol
from uuid import UUID

from app.modules.bookings.rules import (
    Booking,
    BookingHistory,
    BookingHistoryEntry,
    HistoryFilters,
    When,
)
from app.modules.horarios import Agenda


class Bookings(Protocol):
    def of_user(self, user_id: UUID, when: When) -> list[Booking]:
        """The upcoming ones: active that have not ended, from the nearest to the farthest.
        The history: completed, canceled and voided, from the most recent to the oldest."""
        ...

    def opening_hours(self, space_id: UUID) -> Agenda | None:
        """The opening hours of the venue of the space, or `None` if the space or its venue
        are not active."""
        ...

    def repeated(
        self, user_id: UUID, space_id: UUID, starts_at: datetime, ends_at: datetime
    ) -> Booking | None:
        """The active booking that the same person made a moment ago with that data."""
        ...

    def own(self, user_id: UUID, booking_id: UUID) -> Booking | None:
        """The booking [booking_id] if it belongs to [user_id]."""
        ...

    def space_kind(self, space_id: UUID) -> tuple[UUID, str, str] | None:
        """Venue, sport and kind of the space."""
        ...

    def move(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self,
        user_id: UUID,
        booking_id: UUID,
        before: tuple[UUID, datetime],
        space_id: UUID,
        starts_at: datetime,
        ends_at: datetime,
        opening_hours: Agenda,
    ) -> Booking:
        """Moves the booking, which was at [before] (space and start), to [space_id] from
        [starts_at] to [ends_at], at the current price of that space. The previous slot is
        released only if the new one is taken.

        Raises `NotFound`, `ConcurrentChange` (no longer active, started or no longer at
        [before]), `Unavailable` (the new space is gone), `SlotTaken` and
        `OpeningHoursChanged` if the venue no longer has the [opening_hours] it was
        validated with.
        """
        ...

    def cancel(self, user_id: UUID, booking_id: UUID) -> Booking:
        """Cancels the booking of [user_id] and stamps when and who (RF 3: the slot becomes
        free again). If that person had already canceled it, returns it anyway.

        Raises `NotFound` if it is not theirs and `ConcurrentChange` if it is no longer active
        or already started.
        """
        ...

    def insert(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self,
        user_id: UUID,
        space_id: UUID,
        starts_at: datetime,
        ends_at: datetime,
        opening_hours: Agenda,
    ) -> Booking:
        """Saves the active booking at the current price of the space.

        If the same person asked for the same thing a moment ago, it is their request repeated
        after a cut and it returns that booking. Raises `SlotTaken` if another active booking
        of the space overlaps, `Unavailable` if the space, its venue or the account are no
        longer active, and `OpeningHoursChanged` if the venue no longer has the
        [opening_hours] it was validated with.
        """
        ...

    def void(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
        self, admin_id: UUID, booking_id: UUID, reason: str, space_id: UUID, starts_at: datetime
    ) -> BookingHistoryEntry:
        """Voids the booking [booking_id], which the administrator saw in [space_id] from
        [starts_at], and stamps who, when and the [reason] (CU-15): the slot becomes free
        again. If that administrator had already voided it with that reason, returns it
        anyway.

        Raises `NotFound` if it does not exist and `ConcurrentChange` if it is no longer
        active, already started or no longer at that space and time.
        """
        ...

    def history(self, filters: HistoryFilters) -> BookingHistory:
        """The global history of all users and all venues that meets [filters] (CU-14), from
        the most recent to the oldest, paginated."""
        ...

    def any_one(self, booking_id: UUID) -> BookingHistoryEntry | None:
        """The booking [booking_id], whoever it belongs to, with its full traceability."""
        ...
