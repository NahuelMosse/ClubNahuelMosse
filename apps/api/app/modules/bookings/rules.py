# kit-shape: the types of a booking are read together
from dataclasses import dataclass
from datetime import date, datetime
from typing import Literal
from uuid import UUID

Status = Literal["active", "completed", "canceled", "voided"]
# The four tabs of the global history (CU-14): "canceled" has no tab of its own, it only
# shows up inside "all".
StatusFilter = Literal["active", "completed", "voided"]
When = Literal["upcoming", "history"]


# How many bookings each page of the global history brings.
PAGE_SIZE = 20


@dataclass(frozen=True)
class Booking:
    """A booking as seen by whoever made it: the space (its name does not change), the venue
    as it is today, the total stored when booking and the status as of now (an active one
    that already ended is completed)."""

    id: UUID
    space_id: UUID
    venue_id: UUID
    space: str
    sport: str
    kind: str
    venue: str
    address: str
    starts_at: datetime
    ends_at: datetime
    price_per_hour: int
    total: int
    status: Status
    reason: str | None
    # Active and not started, by the server clock: the app does not decide with its own.
    cancelable: bool = False


@dataclass(frozen=True)
class HistoryFilters:
    """What an administrator chose to narrow the global history (CU-14). `None` in any
    field means that filter is not applied."""

    status: StatusFilter | None = None
    venue_id: UUID | None = None
    sport: str | None = None
    since: date | None = None
    until: date | None = None
    q: str | None = None
    page: int = 1


@dataclass(frozen=True)
class BookingHistoryEntry:
    """A booking as seen by an administrator: who made it, when it was created and, if it
    applies, who canceled or voided it and when."""

    id: UUID
    space_id: UUID
    venue_id: UUID
    space: str
    sport: str
    kind: str
    venue: str
    address: str
    starts_at: datetime
    ends_at: datetime
    price_per_hour: int
    total: int
    status: Status
    reason: str | None
    user_id: UUID
    user: str
    created_at: datetime
    canceled_at: datetime | None
    canceled_by_name: str | None
    # The space or its venue is no longer active: the booking stays in the history (FA8),
    # under the technical name it had when booked.
    space_deactivated: bool
    # Active and not started, by the server clock: the app does not decide with its own.
    voidable: bool = False
    # How the notice of the voiding went out to whoever booked, and when; `None` if there was
    # no notice or it has not gone out yet.
    notice_delivery: str | None = None
    notice_at: datetime | None = None


@dataclass(frozen=True)
class Counters:
    """How many bookings are in each tab, with the same filters except the status one."""

    all: int
    active: int
    completed: int
    voided: int


@dataclass(frozen=True)
class BookingHistory:
    """A page of the global history, with the total and the counters of the tabs."""

    bookings: list[BookingHistoryEntry]
    total: int
    page: int
    per_page: int
    counters: Counters
