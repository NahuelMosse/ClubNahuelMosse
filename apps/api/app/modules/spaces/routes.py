# kit-shape: the spaces routes and the models of their requests and responses are read together
#
# The fields of the Pydantic models and the names of the query and path parameters are the
# JSON and URL names of the API contract.
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, Query, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.session import NoSession, Profile, current_user
from app.modules.spaces.repository import SpacesSql, spaces_repository
from app.modules.spaces.rules import Space, SpaceData
from app.modules.spaces.use_cases import (
    active_spaces,
    catalog,
    create_space,
    deactivate_space,
    suggested_name,
    update_space,
)
from app.shared.errors import (
    Duplicate,
    HasFutureBookings,
    InvalidData,
    NumberTaken,
    Unavailable,
)
from app.shared.input_validation import Identifier
from app.shared.responses import conflict

router = APIRouter(tags=["espacios"])

DUPLICATE = "A sports space with that name already exists in the selected venue."
VENUE_UNAVAILABLE = "The venue is no longer available"


class KindView(BaseModel):
    key: str
    name: str


class SportView(BaseModel):
    key: str
    name: str
    kinds: list[KindView]


class CatalogView(BaseModel):
    sports: list[SportView]


@router.get(
    "/spaces/catalog",
    response_model=CatalogView,
    responses={401: {"model": NoSession}},
    summary="The sports and their court kinds",
)
def show_catalog(_: Annotated[Profile, Depends(current_user)]) -> CatalogView:
    return CatalogView(
        sports=[
            SportView(
                key=s.key,
                name=s.name,
                kinds=[KindView(key=k.key, name=k.name) for k in s.kinds],
            )
            for s in catalog()
        ]
    )


class SpaceView(BaseModel):
    id: UUID
    name: str
    venue_id: UUID
    venue: str
    sport: str
    kind: str
    number: int
    covered: bool
    lit: bool
    price_per_hour: int


class SpaceList(BaseModel):
    spaces: list[SpaceView]


def space_view(space: Space) -> SpaceView:
    return SpaceView(
        id=space.id,
        name=space.name,
        venue_id=space.venue_id,
        venue=space.venue,
        sport=space.sport,
        kind=space.kind,
        number=space.number,
        covered=space.covered,
        lit=space.lit,
        price_per_hour=space.price_per_hour,
    )


@router.get(
    "/spaces",
    response_model=SpaceList,
    responses={401: {"model": NoSession}},
    summary="The active spaces of the active venues, by venue, sport, kind and number",
)
def list_spaces(
    _: Annotated[Profile, Depends(current_user)],
    repository: Annotated[SpacesSql, Depends(spaces_repository)],
    venue_id: Annotated[Identifier | None, Query()] = None,
    sport: Annotated[str | None, Query(min_length=1)] = None,
    kind: Annotated[str | None, Query(min_length=1)] = None,
) -> SpaceList:
    active = active_spaces(repository, venue_id, sport, kind)
    return SpaceList(spaces=[space_view(s) for s in active])


class Suggestion(BaseModel):
    name: str
    number: int


class ErrorBody(BaseModel):
    errors: dict[str, str]


@router.get(
    "/spaces/name",
    response_model=Suggestion,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator creates spaces"},
        422: {"model": ErrorBody},
    },
    summary="The name the next space of that kind in that venue would have",
)
def suggest_name(  # noqa: PLR0913, PLR0917 -- one parameter per query field of the route
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[SpacesSql, Depends(spaces_repository)],
    venue_id: Annotated[Identifier, Query()],
    sport: Annotated[str, Query()],
    kind: Annotated[str, Query()],
) -> Suggestion:
    try:
        suggested = suggested_name(profile, venue_id, sport, kind, repository)
    except Unavailable:
        raise InvalidData({"venue_id": VENUE_UNAVAILABLE}) from None
    return Suggestion(name=suggested.name, number=suggested.number)


class SpaceRequest(BaseModel):
    venue_id: Identifier | None = None
    sport: str = ""
    kind: str = ""
    covered: bool | None = None
    lit: bool | None = None
    price_per_hour: int | None = None
    number: int | None = None


@router.post(
    "/spaces",
    status_code=status.HTTP_201_CREATED,
    response_model=SpaceView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator creates spaces"},
        409: {
            "description": (
                "The number shown was already taken by another creation: it returns with the next "
                "name and number"
            )
        },
        422: {"model": ErrorBody},
    },
    summary="Create a sports space",
    description=(
        "The name is built from the venue, the address, the sport, the kind and the next number "
        "of that kind in that venue. `number` is the one the administrator saw; if "
        "omitted, the next one is used."
    ),
)
def create_space_route(
    request: SpaceRequest,
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[SpacesSql, Depends(spaces_repository)],
) -> SpaceView | Response:
    data = SpaceData(
        venue_id=request.venue_id,
        sport=request.sport,
        kind=request.kind,
        covered=request.covered,
        lit=request.lit,
        price_per_hour=request.price_per_hour,
    )
    try:
        space = create_space(profile, data, request.number, repository)
    except Unavailable:
        raise InvalidData({"venue_id": VENUE_UNAVAILABLE}) from None
    except NumberTaken as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"errors": {"name": DUPLICATE}, "name": e.name, "number": e.next_number},
        )
    except Duplicate:
        content: dict[str, object] = {"errors": {"name": DUPLICATE}}
        if request.venue_id is not None:
            try:
                s = suggested_name(
                    profile, request.venue_id, request.sport, request.kind, repository
                )
                content |= {"name": s.name, "number": s.number}
            except (Unavailable, InvalidData):
                pass
        return JSONResponse(status_code=status.HTTP_409_CONFLICT, content=content)
    return space_view(space)


class SpaceChangeRequest(BaseModel):
    # The sport and the kind do not change: they are accepted and ignored, so a client that
    # resends the whole space keeps working, but they must be valid text.
    sport: str | None = None
    kind: str | None = None
    covered: bool | None = None
    lit: bool | None = None
    price_per_hour: int | None = None


@router.put(
    "/spaces/{space_id}",
    response_model=SpaceView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator edits spaces"},
        404: {"description": "The space or its venue is no longer active"},
        422: {"model": ErrorBody},
    },
    summary="Edit a space",
    description=(
        "Condition, lighting and price per hour; what is not sent stays as it is. The venue, "
        "the sport, the kind and the composite name do not change; bookings already made "
        "keep their price."
    ),
)
def update_space_route(
    request: SpaceChangeRequest,
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[SpacesSql, Depends(spaces_repository)],
    space_id: Annotated[Identifier, Path()],
) -> SpaceView:
    space = update_space(
        profile,
        space_id,
        request.covered,
        request.lit,
        request.price_per_hour,
        frozenset(request.model_fields_set),
        repository,
    )
    return space_view(space)


@router.delete(
    "/spaces/{space_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        403: {"description": "Only an administrator deletes spaces"},
        404: {"description": "The space is no longer active"},
        409: {"model": ErrorBody, "description": "The space has bookings that have not ended"},
    },
    summary="Delete a space",
    description=(
        "Soft delete: the space stops being shown and bookable, and the history keeps "
        "naming it. Not allowed with active bookings that have not ended."
    ),
)
def deactivate_space_route(
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[SpacesSql, Depends(spaces_repository)],
    space_id: Annotated[Identifier, Path()],
) -> Response:
    try:
        deactivate_space(profile, space_id, repository)
    except HasFutureBookings:
        return conflict(
            {"space": "The space cannot be deleted because it has future bookings."}
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
