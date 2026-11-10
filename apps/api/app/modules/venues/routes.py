# kit-shape: the venue routes and the models of their requests and responses are read together
from datetime import time
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from app.modules.session import NoSession, Profile, current_user
from app.modules.venues.repository import VenuesSql, venue_repository
from app.modules.venues.rules import Venue, VenueData
from app.modules.venues.use_cases import (
    active_venues,
    create_venue,
    deactivate_venue,
    update_venue,
)
from app.shared.errors import BookingsOutsideHours, Duplicate, HasFutureBookings
from app.shared.input_validation import Identifier, parse_time
from app.shared.responses import conflict

router = APIRouter(tags=["venues"])


class VenueView(BaseModel):
    id: UUID
    name: str
    address: str
    opens_at: str
    closes_at: str
    open_days: list[int]
    space_count: int
    sports: list[str]


class VenueList(BaseModel):
    venues: list[VenueView]


class VenueErrors(BaseModel):
    errors: dict[str, str]


def _hour(value: time) -> str:
    return value.strftime("%H:%M")


def _view(venue: Venue) -> VenueView:
    return VenueView(
        id=venue.id,
        name=venue.name,
        address=venue.address,
        opens_at=_hour(venue.opens_at),
        closes_at=_hour(venue.closes_at),
        open_days=list(venue.open_days),
        space_count=venue.space_count,
        sports=list(venue.sports),
    )


@router.get(
    "/venues",
    response_model=VenueList,
    responses={401: {"model": NoSession}},
    summary="The active venues, by name, with their courts and the sports they offer",
)
def list_venues(
    _: Annotated[Profile, Depends(current_user)],
    venues: Annotated[VenuesSql, Depends(venue_repository)],
) -> VenueList:
    return VenueList(venues=[_view(v) for v in active_venues(venues)])


class VenueRequest(BaseModel):
    name: str = ""
    address: str = ""
    opens_at: str = ""
    closes_at: str = ""
    # Weekdays go from 1 to 7: more than seven makes no sense.
    open_days: Annotated[list[int], Field(max_length=7)] = []


def _data(request: VenueRequest) -> VenueData:
    return VenueData(
        name=request.name,
        address=request.address,
        opens_at=parse_time(request.opens_at),
        closes_at=parse_time(request.closes_at),
        open_days=tuple(request.open_days),
    )


@router.post(
    "/venues",
    status_code=status.HTTP_201_CREATED,
    response_model=VenueView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator creates venues"},
        409: {"model": VenueErrors, "description": "Another active venue already has that name"},
        422: {"model": VenueErrors},
    },
    summary="Create a venue",
    description="On-the-hour times; a closing at 00:00 is midnight of the same day.",
)
def add_venue(
    request: VenueRequest,
    profile: Annotated[Profile, Depends(current_user)],
    venues: Annotated[VenuesSql, Depends(venue_repository)],
) -> VenueView | Response:
    try:
        venue = create_venue(profile, _data(request), venues)
    except Duplicate:
        return conflict({"name": "A venue with that name already exists"})
    return _view(venue)


class VenueEditRequest(VenueRequest):
    # Save anyway a schedule that leaves future bookings outside.
    confirm: bool = False


class BookingsOutside(BaseModel):
    bookings_outside: int


@router.put(
    "/venues/{venue_id}",
    response_model=VenueView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator edits venues"},
        404: {"description": "The venue is no longer active"},
        409: {
            "model": VenueErrors | BookingsOutside,
            "description": "Another active venue already has that name, or the new hours leave "
            "future bookings out and `confirm` is missing",
        },
        422: {"model": VenueErrors},
    },
    summary="Edit a venue",
    description=(
        "The same data and rules as creation. Bookings already made are kept even if they "
        "fall outside the new hours, which apply to the ones to come."
    ),
)
def edit_venue(
    request: VenueEditRequest,
    profile: Annotated[Profile, Depends(current_user)],
    venues: Annotated[VenuesSql, Depends(venue_repository)],
    venue_id: Annotated[Identifier, Path()],
) -> VenueView | Response:
    try:
        venue = update_venue(
            profile, venue_id, _data(request), confirm=request.confirm, venues=venues
        )
    except Duplicate:
        return conflict({"name": "A venue with that name already exists"})
    except BookingsOutsideHours as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT, content={"bookings_outside": e.count}
        )
    return _view(venue)


@router.delete(
    "/venues/{venue_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator deletes venues"},
        404: {"description": "The venue is no longer active"},
        409: {"model": VenueErrors, "description": "The venue has bookings that have not ended"},
    },
    summary="Delete a venue",
    description=(
        "Soft delete: the venue and its spaces stop being shown and bookable, and the "
        "history keeps naming it. Not allowed with active bookings that have not ended."
    ),
)
def remove_venue(
    profile: Annotated[Profile, Depends(current_user)],
    venues: Annotated[VenuesSql, Depends(venue_repository)],
    venue_id: Annotated[Identifier, Path()],
) -> Response:
    try:
        deactivate_venue(profile, venue_id, venues)
    except HasFutureBookings:
        return conflict({"venue": "The venue cannot be deleted because it has future bookings."})
    return Response(status_code=status.HTTP_204_NO_CONTENT)
