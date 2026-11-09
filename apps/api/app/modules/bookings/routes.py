# kit-shape: the booking routes and the models of their requests and responses are read together
from datetime import date as date_type
from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, Depends, Path, Query, Response, status
from pydantic import AwareDatetime, BaseModel

from app.modules.bookings.email import booking_email
from app.modules.bookings.repository import BookingsSql, bookings_repository
from app.modules.bookings.rules import HistoryFilters, Status, StatusFilter
from app.modules.bookings.use_cases import (
    When,
    admin_detail,
    book,
    cancel_booking,
    global_history,
    modify_booking,
    my_bookings,
    void_booking,
)
from app.modules.notifications import PushChannel, dispatch_for, push_channel
from app.modules.session import NoSession, Profile, current_user
from app.shared.club_timezone import CLUB_TIMEZONE
from app.shared.email import send
from app.shared.errors import ConcurrentChange, InvalidData, SlotTaken, Unavailable
from app.shared.input_validation import Identifier, parse_time
from app.shared.responses import conflict

router = APIRouter(tags=["reservas"])

# With 20 per page, ten thousand pages are two hundred thousand bookings.
MAX_PAGE = 10_000

SLOT_TAKEN_MESSAGE = "That slot was taken"
UNAVAILABLE_MESSAGE = "This court is no longer available"


class _BookingFields(BaseModel):
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


class BookingView(_BookingFields):
    cancelable: bool


class Errors(BaseModel):
    errors: dict[str, str]


class BookingList(BaseModel):
    bookings: list[BookingView]


@router.get(
    "/bookings",
    response_model=BookingList,
    responses={401: {"model": NoSession}, 422: {"model": Errors}},
    summary="The bookings of whoever asks",
    description=(
        "`upcoming`: the active ones that have not ended, from the nearest to the farthest. "
        "`history`: the completed, cancelled and voided ones, from the most recent to the "
        "oldest. The total is the one saved when booking."
    ),
)
def list_bookings(
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    when: Annotated[When, Query()] = "upcoming",
) -> BookingList:
    return BookingList(
        bookings=[
            BookingView.model_validate(b, from_attributes=True)
            for b in my_bookings(repository, profile, when)
        ]
    )


class BookingRequest(BaseModel):
    space_id: Identifier
    date: date_type
    start_hour: str
    # No bound here: the use case rejects an out-of-range duration before computing anything.
    hours: int


@router.post(
    "/bookings",
    status_code=status.HTTP_201_CREATED,
    response_model=BookingView,
    responses={
        401: {"model": NoSession},
        403: {"description": "An administrator does not book"},
        409: {"model": Errors, "description": "Another active booking overlaps that slot"},
        422: {"model": Errors},
    },
    summary="Book a space",
    description=(
        "`hours` hours from `start_hour` (`HH:MM`, in the club's time) on `date`. Whole "
        "hours, from 1 to 4, in the future, within the next 7 days and inside the venue's "
        "opening hours; "
        "if the same person repeats the same request within five minutes, it returns the "
        "booking already made."
    ),
)
def create_booking(
    payload: BookingRequest,
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    after: BackgroundTasks,
) -> BookingView | Response:
    try:
        booking = book(
            repository,
            profile,
            payload.space_id,
            payload.date,
            parse_time(payload.start_hour),
            payload.hours,
            datetime.now(CLUB_TIMEZONE),
        )
    except Unavailable:
        raise InvalidData({"space_id": UNAVAILABLE_MESSAGE}) from None
    except SlotTaken:
        return conflict({"slot": SLOT_TAKEN_MESSAGE})
    after.add_task(send, booking_email(profile, booking))
    return BookingView.model_validate(booking, from_attributes=True)


CHANGED_MESSAGE = "This changed in the meantime"


@router.post(
    "/bookings/{booking_id}/cancel",
    response_model=BookingView,
    responses={
        401: {"model": NoSession},
        404: {"description": "The requester has no booking with that number"},
        409: {"model": Errors, "description": "The booking is no longer active or has started"},
    },
    summary="Cancel your own booking",
    description=(
        "Until the slot starts. The slot becomes free again, the booking moves to the "
        "history as cancelled and the confirmation stays in the notification center and goes out "
        "by push. Cancelling one the same person already cancelled answers the same."
    ),
)
def cancel(
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    booking_id: Annotated[Identifier, Path()],
    background: BackgroundTasks,
    channel: Annotated[PushChannel, Depends(push_channel)],
) -> BookingView | Response:
    try:
        booking = cancel_booking(repository, profile, booking_id)
    except ConcurrentChange:
        return conflict({"booking": CHANGED_MESSAGE})
    background.add_task(dispatch_for, profile.id, channel)
    return BookingView.model_validate(booking, from_attributes=True)


class BookingChangeRequest(BaseModel):
    space_id: Identifier
    date: date_type
    start_hour: str


@router.post(
    "/bookings/{booking_id}/modify",
    response_model=BookingView,
    responses={
        401: {"model": NoSession},
        403: {"description": "An administrator does not book"},
        404: {"description": "The requester has no booking with that number"},
        409: {
            "model": Errors,
            "description": "The new slot was taken (`slot`) or the booking can no longer be "
            "modified (`booking`)",
        },
        422: {"model": Errors},
    },
    summary="Modify your own booking",
    description=(
        "Another court of the same kind in the same venue, another day or another slot, with "
        "the same duration. The previous slot is freed only if the new one is taken; the booking "
        "keeps its number and the total becomes the space's current price. Repeating a change "
        "already made answers the same."
    ),
)
def modify(
    payload: BookingChangeRequest,
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    booking_id: Annotated[Identifier, Path()],
) -> BookingView | Response:
    try:
        booking = modify_booking(
            repository,
            profile,
            booking_id,
            payload.space_id,
            payload.date,
            parse_time(payload.start_hour),
            datetime.now(CLUB_TIMEZONE),
        )
    except Unavailable:
        raise InvalidData({"space_id": UNAVAILABLE_MESSAGE}) from None
    except ConcurrentChange:
        return conflict({"booking": CHANGED_MESSAGE})
    except SlotTaken:
        return conflict({"slot": SLOT_TAKEN_MESSAGE})
    return BookingView.model_validate(booking, from_attributes=True)


class BookingHistoryView(_BookingFields):
    user_id: UUID
    user: str
    created_at: datetime
    canceled_at: datetime | None
    canceled_by_name: str | None
    space_deactivated: bool
    voidable: bool
    notice_delivery: str | None
    notice_at: datetime | None


class CountersView(BaseModel):
    all: int
    active: int
    completed: int
    voided: int


class HistoryView(BaseModel):
    bookings: list[BookingHistoryView]
    total: int
    page: int
    per_page: int
    counters: CountersView


@router.get(
    "/bookings/all",
    response_model=HistoryView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator reads the global history"},
        422: {"model": Errors},
    },
    summary="The global booking history (CU-14)",
    description=(
        "All users, all venues. Filters by status (`active`, `completed` or"
        " `voided`; without a filter it also brings those cancelled by their user), venue, sport,"
        " date range and text (user, venue or space); pages by 20 with `page`, from the"
        " most recent to the oldest. It changes nothing."
    ),
)
def list_all(  # noqa: PLR0913, PLR0917 -- one parameter per query filter of the route
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    status: Annotated[StatusFilter | None, Query()] = None,
    venue_id: Annotated[Identifier | None, Query()] = None,
    sport: Annotated[str | None, Query()] = None,
    since: Annotated[date_type | None, Query()] = None,
    until: Annotated[date_type | None, Query()] = None,
    q: Annotated[str | None, Query()] = None,
    page: Annotated[int, Query(ge=1, le=MAX_PAGE)] = 1,
) -> HistoryView:
    history = global_history(
        repository,
        profile,
        HistoryFilters(
            status=status,
            venue_id=venue_id,
            sport=sport,
            since=since,
            until=until,
            q=q,
            page=page,
        ),
    )
    return HistoryView(
        bookings=[
            BookingHistoryView.model_validate(b, from_attributes=True) for b in history.bookings
        ],
        total=history.total,
        page=history.page,
        per_page=history.per_page,
        counters=CountersView(
            all=history.counters.all,
            active=history.counters.active,
            completed=history.counters.completed,
            voided=history.counters.voided,
        ),
    )


@router.get(
    "/bookings/all/{booking_id}",
    response_model=BookingHistoryView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator reads the detail of any booking"},
        404: {"description": "There is no booking with that number"},
    },
    summary="The detail of any booking (CU-14)",
)
def detail(
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    booking_id: Annotated[Identifier, Path()],
) -> BookingHistoryView:
    return BookingHistoryView.model_validate(
        admin_detail(repository, profile, booking_id), from_attributes=True
    )


class VoidRequest(BaseModel):
    reason: str
    space_id: Identifier
    starts_at: AwareDatetime


@router.post(
    "/bookings/{booking_id}/void",
    response_model=BookingHistoryView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator voids a booking"},
        404: {"description": "There is no booking with that number"},
        409: {
            "model": Errors,
            "description": "The booking is no longer active, has started or changed",
        },
        422: {"model": Errors},
    },
    summary="Void a booking (CU-15)",
    description=(
        "Until the slot starts. `space_id` and `starts_at` are the court and the slot the "
        "administrator saw: if the booking is no longer there, it answers 409. The slot becomes "
        "free again and the booking keeps the reason, who voided it and when. Repeating a "
        "voiding already done by the same administrator with the same reason answers the same. "
        "It notifies whoever booked, with the reason, without repeating the notice."
    ),
)
def void(
    payload: VoidRequest,
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    booking_id: Annotated[Identifier, Path()],
    background: BackgroundTasks,
    channel: Annotated[PushChannel, Depends(push_channel)],
) -> BookingHistoryView | Response:
    try:
        booking = void_booking(
            repository,
            profile,
            booking_id,
            payload.reason,
            payload.space_id,
            payload.starts_at,
        )
    except ConcurrentChange:
        return conflict({"booking": CHANGED_MESSAGE})
    # The notice to whoever booked goes out only once the voiding is confirmed and the
    # response sent.
    background.add_task(dispatch_for, booking.user_id, channel)
    return BookingHistoryView.model_validate(booking, from_attributes=True)
