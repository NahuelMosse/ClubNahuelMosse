# kit-shape: the availability routes and the models of their responses are read together
#
# The fields of the Pydantic models and the names of the query and path parameters are the
# JSON and URL names of the API contract, so they stay as published; the Python names are
# English.
from datetime import date, datetime
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

router = APIRouter(tags=["horarios"])

SPACE_UNAVAILABLE = "Esta cancha ya no está disponible"


class SlotView(BaseModel):
    inicio: str
    fin: str
    disponible: bool


class SlotGridView(BaseModel):
    fecha: date
    hoy: date
    abre: bool
    franjas: list[SlotView]
    no_disponibles: int


class ErrorBody(BaseModel):
    errores: dict[str, str]


def _hour(moment: datetime) -> str:
    return moment.astimezone(ZONE).strftime("%H:%M")


@router.get(
    "/espacios/{espacio_id}/horarios",
    response_model=SlotGridView,
    responses={
        401: {"model": NoSession},
        404: {"model": ErrorBody, "description": "El espacio o su sede ya no están activos"},
        422: {"model": ErrorBody},
    },
    summary="Las franjas de un espacio para un día y una duración",
    description=(
        "Todas las horas de inicio en punto que entran en el horario de la sede con esa "
        "duración y todavía no empezaron, en la hora del club; `disponible` dice si no pisan "
        "una reserva activa. Sin `fecha`, la de hoy. `abre` es falso si la sede no abre ese día."
    ),
    operation_id="ver_horarios_espacios__espacio_id__horarios_get",
)
def show_slots(  # noqa: PLR0913, PLR0917 -- one parameter per query/path field of the route
    profile: Annotated[Profile, Depends(current_user)],
    availability: Annotated[AvailabilitySql, Depends(availability_repository)],
    space_id: Annotated[Identifier, Path(alias="espacio_id")],
    day: Annotated[date | None, Query(alias="fecha")] = None,
    hours: Annotated[int, Query(alias="horas", ge=MIN_HOURS, le=MAX_HOURS)] = MIN_HOURS,
    booking_id: Annotated[Identifier | None, Query(alias="reserva_id")] = None,
) -> SlotGridView | JSONResponse:
    try:
        grid = available_slots(
            availability,
            space_id,
            day,
            hours,
            datetime.now(ZONE),
            None if booking_id is None else (booking_id, profile.id),
        )
    except Unavailable:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"errores": {"espacio_id": SPACE_UNAVAILABLE}},
        )
    return SlotGridView(
        fecha=grid.day,
        hoy=grid.today,
        abre=grid.opens,
        franjas=[
            SlotView(inicio=_hour(s.start), fin=_hour(s.end), disponible=s.available)
            for s in grid.slots
        ],
        no_disponibles=grid.unavailable,
    )


VENUE_UNAVAILABLE = "La sede ya no está disponible"


@router.get(
    "/espacios/disponibles",
    response_model=SpaceList,
    responses={401: {"model": NoSession}, 422: {"model": ErrorBody}},
    summary="Las canchas de una sede libres en todo un rango",
    description=(
        "Los espacios activos de la sede, del deporte y del tipo si viene, sin reservas activas "
        "que pisen [desde, hasta) el día `fecha`, en la hora del club. `hasta` a las 00:00 es la "
        "medianoche. El rango tiene que ser futuro, de horas completas, de 1 a 4 horas, de los "
        "próximos 7 días y dentro del horario de la sede: si no, 422 con el error de cada campo."
    ),
    operation_id="ver_disponibles_espacios_disponibles_get",
)
def show_available(  # noqa: PLR0913, PLR0917 -- one parameter per query field of the route
    _: Annotated[Profile, Depends(current_user)],
    availability: Annotated[AvailabilitySql, Depends(availability_repository)],
    venue_id: Annotated[Identifier, Query(alias="sede_id")],
    sport: Annotated[str, Query(alias="deporte", min_length=1)],
    day: Annotated[date, Query(alias="fecha")],
    since: Annotated[str, Query(alias="desde")],
    until: Annotated[str, Query(alias="hasta")],
    kind: Annotated[str | None, Query(alias="tipo", min_length=1)] = None,
) -> SpaceList:
    start, end = parse_time(since), parse_time(until)
    errors = {
        field: "Elegí una hora en punto"
        for field, hour in (("desde", start), ("hasta", end))
        if hour is None
    }
    if start is None or end is None:
        raise InvalidData(errors)
    try:
        free = available_spaces(
            availability, venue_id, sport, kind, day, start, end, datetime.now(ZONE)
        )
    except Unavailable:
        raise InvalidData({"sede_id": VENUE_UNAVAILABLE}) from None
    return SpaceList(espacios=[space_view(s) for s in free])
