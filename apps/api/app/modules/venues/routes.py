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

router = APIRouter(tags=["sedes"])


class VenueView(BaseModel):
    id: UUID
    nombre: str
    direccion: str
    apertura: str
    cierre: str
    dias: list[int]
    canchas: int
    deportes: list[str]


class VenueList(BaseModel):
    sedes: list[VenueView]


class VenueErrors(BaseModel):
    errores: dict[str, str]


def _hour(value: time) -> str:
    return value.strftime("%H:%M")


def _view(venue: Venue) -> VenueView:
    return VenueView(
        id=venue.id,
        nombre=venue.name,
        direccion=venue.address,
        apertura=_hour(venue.opens_at),
        cierre=_hour(venue.closes_at),
        dias=list(venue.open_days),
        canchas=venue.space_count,
        deportes=list(venue.sports),
    )


@router.get(
    "/sedes",
    operation_id="listar_sedes_sedes_get",
    response_model=VenueList,
    responses={401: {"model": NoSession}},
    summary="Las sedes activas, por nombre, con sus canchas y los deportes que ofrecen",
)
def list_venues(
    _: Annotated[Profile, Depends(current_user)],
    venues: Annotated[VenuesSql, Depends(venue_repository)],
) -> VenueList:
    return VenueList(sedes=[_view(v) for v in active_venues(venues)])


class VenueRequest(BaseModel):
    nombre: str = ""
    direccion: str = ""
    apertura: str = ""
    cierre: str = ""
    # Weekdays go from 1 to 7: more than seven makes no sense.
    dias: Annotated[list[int], Field(max_length=7)] = []


def _data(request: VenueRequest) -> VenueData:
    return VenueData(
        name=request.nombre,
        address=request.direccion,
        opens_at=parse_time(request.apertura),
        closes_at=parse_time(request.cierre),
        open_days=tuple(request.dias),
    )


@router.post(
    "/sedes",
    operation_id="alta_de_sede_sedes_post",
    status_code=status.HTTP_201_CREATED,
    response_model=VenueView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Sólo un administrador da de alta sedes"},
        409: {"model": VenueErrors, "description": "Otra sede activa ya tiene ese nombre"},
        422: {"model": VenueErrors},
    },
    summary="Dar de alta una sede",
    description="Horas en punto; un cierre a las 00:00 es la medianoche del mismo día.",
)
def add_venue(
    request: VenueRequest,
    profile: Annotated[Profile, Depends(current_user)],
    venues: Annotated[VenuesSql, Depends(venue_repository)],
) -> VenueView | Response:
    try:
        venue = create_venue(profile, _data(request), venues)
    except Duplicate:
        return conflict({"nombre": "Ya existe una sede con ese nombre"})
    return _view(venue)


class VenueEditRequest(VenueRequest):
    # Save anyway a schedule that leaves future bookings outside.
    confirmar: bool = False


class BookingsOutside(BaseModel):
    reservas_afuera: int


@router.put(
    "/sedes/{sede_id}",
    operation_id="edicion_de_sede_sedes__sede_id__put",
    response_model=VenueView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Sólo un administrador edita sedes"},
        404: {"description": "La sede ya no está activa"},
        409: {
            "model": VenueErrors | BookingsOutside,
            "description": "Otra sede activa ya tiene ese nombre, o el horario nuevo deja "
            "afuera reservas futuras y falta `confirmar`",
        },
        422: {"model": VenueErrors},
    },
    summary="Editar una sede",
    description=(
        "Los mismos datos y reglas que el alta. Las reservas ya hechas se mantienen aunque "
        "queden fuera del horario nuevo, que rige para las que vengan."
    ),
)
def edit_venue(
    request: VenueEditRequest,
    profile: Annotated[Profile, Depends(current_user)],
    venues: Annotated[VenuesSql, Depends(venue_repository)],
    sede_id: Annotated[Identifier, Path()],
) -> VenueView | Response:
    try:
        venue = update_venue(
            profile, sede_id, _data(request), confirm=request.confirmar, venues=venues
        )
    except Duplicate:
        return conflict({"nombre": "Ya existe una sede con ese nombre"})
    except BookingsOutsideHours as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT, content={"reservas_afuera": e.count}
        )
    return _view(venue)


@router.delete(
    "/sedes/{sede_id}",
    operation_id="baja_de_sede_sedes__sede_id__delete",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        403: {"description": "Sólo un administrador da de baja sedes"},
        404: {"description": "La sede ya no está activa"},
        409: {"model": VenueErrors, "description": "La sede tiene reservas que no terminaron"},
    },
    summary="Dar de baja una sede",
    description=(
        "Baja lógica: la sede y sus espacios dejan de verse y de poder reservarse, y el "
        "historial los sigue nombrando. No se permite con reservas activas sin terminar."
    ),
)
def remove_venue(
    profile: Annotated[Profile, Depends(current_user)],
    venues: Annotated[VenuesSql, Depends(venue_repository)],
    sede_id: Annotated[Identifier, Path()],
) -> Response:
    try:
        deactivate_venue(profile, sede_id, venues)
    except HasFutureBookings:
        return conflict(
            {"sede": "No se puede dar de baja la sede porque posee reservas futuras asociadas."}
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
