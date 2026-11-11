# kit-shape: the availability routes and the models of their responses are read together
#
# The fields of the Pydantic models and the names of the query and path parameters are the
# JSON and URL names of the API contract.
from datetime import date as date_type
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.availability.repository import AvailabilitySql, availability_repository
from app.modules.availability.rules import MAX_HOURS, MIN_HOURS
from app.modules.availability.slots import available_spaces
from app.modules.availability.use_cases import available_slots
from app.modules.session import NoSession, Profile, current_user
from app.modules.spaces import SpaceList, space_view
from app.shared.club_timezone import CLUB_TIMEZONE as ZONE
from app.shared.errors import InvalidData, Unavailable
from app.shared.input_validation import Identifier, parse_time

router = APIRouter(tags=["availability"])

SPACE_UNAVAILABLE = "This court is no longer available"


class SlotView(BaseModel):
    starts_at: str
    ends_at: str
    available: bool


class SlotGridView(BaseModel):
    date: date_type
    today: date_type
    opens: bool
    slots: list[SlotView]
    unavailable: int


class ErrorBody(BaseModel):
    errors: dict[str, str]


def _hour(moment: datetime) -> str:
    return moment.astimezone(ZONE).strftime("%H:%M")


@router.get(
    "/spaces/{space_id}/slots",
    response_model=SlotGridView,
    responses={
        401: {"model": NoSession},
        404: {"model": ErrorBody, "description": "The space or its venue is no longer active"},
        422: {"model": ErrorBody},
    },
    summary="The slots of a space for a day and a duration",
    description=(
        "Every on-the-hour start time that fits the venue's opening hours with that "
        "duration and has not started yet, in the club's time; `available` says whether they "
        "do not overlap an active booking. Without `date`, today's. `opens` is false if the "
        "venue is closed that day."
    ),
)
def show_slots(  # noqa: PLR0913, PLR0917 -- one parameter per query/path field of the route
    profile: Annotated[Profile, Depends(current_user)],
    availability: Annotated[AvailabilitySql, Depends(availability_repository)],
    space_id: Annotated[Identifier, Path()],
    date: Annotated[date_type | None, Query()] = None,
    hours: Annotated[int, Query(ge=MIN_HOURS, le=MAX_HOURS)] = MIN_HOURS,
    booking_id: Annotated[Identifier | None, Query()] = None,
) -> SlotGridView | JSONResponse:
    try:
        grid = available_slots(
            availability,
            space_id,
            date,
            hours,
            datetime.now(ZONE),
            None if booking_id is None else (booking_id, profile.id),
        )
    except Unavailable:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"errors": {"space_id": SPACE_UNAVAILABLE}},
        )
    return SlotGridView(
        date=grid.day,
        today=grid.today,
        opens=grid.opens,
        slots=[
            SlotView(starts_at=_hour(s.start), ends_at=_hour(s.end), available=s.available)
            for s in grid.slots
        ],
        unavailable=grid.unavailable,
    )


VENUE_UNAVAILABLE = "The venue is no longer available"


@router.get(
    "/spaces/available",
    response_model=SpaceList,
    responses={401: {"model": NoSession}, 422: {"model": ErrorBody}},
    summary="The courts of a venue that are free over a whole range",
    description=(
        "The active spaces of the venue, of the sport and kind if given, with no active bookings "
        "overlapping [since, until) on `date`, in the club's time. `until` at 00:00 is "
        "midnight. The range must be in the future, of whole hours, from 1 to 4 hours, within the "
        "next 7 days and inside the venue's opening hours: otherwise 422 with each field's error."
    ),
)
def show_available(  # noqa: PLR0913, PLR0917 -- one parameter per query field of the route
    _: Annotated[Profile, Depends(current_user)],
    availability: Annotated[AvailabilitySql, Depends(availability_repository)],
    venue_id: Annotated[Identifier, Query()],
    sport: Annotated[str, Query(min_length=1)],
    date: Annotated[date_type, Query()],
    since: Annotated[str, Query()],
    until: Annotated[str, Query()],
    kind: Annotated[str | None, Query(min_length=1)] = None,
) -> SpaceList:
    start, end = parse_time(since), parse_time(until)
    errors = {
        field: "Choose an on-the-hour time"
        for field, hour in (("start_hour", start), ("until", end))
        if hour is None
    }
    if start is None or end is None:
        raise InvalidData(errors)
    try:
        free = available_spaces(
            availability, venue_id, sport, kind, date, start, end, datetime.now(ZONE)
        )
    except Unavailable:
        raise InvalidData({"venue_id": VENUE_UNAVAILABLE}) from None
    return SpaceList(spaces=[space_view(s) for s in free])
