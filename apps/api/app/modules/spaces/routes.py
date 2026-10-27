# kit-shape: the spaces routes and the models of their requests and responses are read together
#
# The fields of the Pydantic models and the names of the query and path parameters are the
# JSON and URL names of the API contract, so they stay as published; the Python names are
# English.
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, Query, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.sesion import Perfil, SinSesion, usuario_actual
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

DUPLICATE = "Ya existe un espacio deportivo con ese nombre en la sede seleccionada."
VENUE_UNAVAILABLE = "La sede ya no está disponible"


class KindView(BaseModel):
    clave: str
    nombre: str


class SportView(BaseModel):
    clave: str
    nombre: str
    tipos: list[KindView]


class CatalogView(BaseModel):
    deportes: list[SportView]


@router.get(
    "/espacios/catalogo",
    response_model=CatalogView,
    responses={401: {"model": SinSesion}},
    summary="Los deportes y sus tipos de cancha",
    operation_id="ver_catalogo_espacios_catalogo_get",
)
def show_catalog(_: Annotated[Perfil, Depends(usuario_actual)]) -> CatalogView:
    return CatalogView(
        deportes=[
            SportView(
                clave=s.key,
                nombre=s.name,
                tipos=[KindView(clave=k.key, nombre=k.name) for k in s.kinds],
            )
            for s in catalog()
        ]
    )


class SpaceView(BaseModel):
    id: UUID
    nombre: str
    sede_id: UUID
    sede: str
    deporte: str
    tipo: str
    numero: int
    techada: bool
    iluminada: bool
    precio_por_hora: int


class SpaceList(BaseModel):
    espacios: list[SpaceView]


def space_view(space: Space) -> SpaceView:
    return SpaceView(
        id=space.id,
        nombre=space.name,
        sede_id=space.venue_id,
        sede=space.venue,
        deporte=space.sport,
        tipo=space.kind,
        numero=space.number,
        techada=space.covered,
        iluminada=space.lit,
        precio_por_hora=space.price_per_hour,
    )


@router.get(
    "/espacios",
    response_model=SpaceList,
    responses={401: {"model": SinSesion}},
    summary="Los espacios activos de las sedes activas, por sede, deporte, tipo y número",
    operation_id="listar_espacios_espacios_get",
)
def list_spaces(
    _: Annotated[Perfil, Depends(usuario_actual)],
    spaces: Annotated[SpacesSql, Depends(spaces_repository)],
    venue_id: Annotated[Identifier | None, Query(alias="sede_id")] = None,
    sport: Annotated[str | None, Query(alias="deporte", min_length=1)] = None,
    kind: Annotated[str | None, Query(alias="tipo", min_length=1)] = None,
) -> SpaceList:
    active = active_spaces(spaces, venue_id, sport, kind)
    return SpaceList(espacios=[space_view(s) for s in active])


class Suggestion(BaseModel):
    nombre: str
    numero: int


class ErrorBody(BaseModel):
    errores: dict[str, str]


@router.get(
    "/espacios/nombre",
    response_model=Suggestion,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador da de alta espacios"},
        422: {"model": ErrorBody},
    },
    summary="El nombre que tendría el próximo espacio de ese tipo en esa sede",
    operation_id="sugerir_nombre_espacios_nombre_get",
)
def suggest_name(  # noqa: PLR0913, PLR0917 -- one parameter per query field of the route
    profile: Annotated[Perfil, Depends(usuario_actual)],
    spaces: Annotated[SpacesSql, Depends(spaces_repository)],
    venue_id: Annotated[Identifier, Query(alias="sede_id")],
    sport: Annotated[str, Query(alias="deporte")],
    kind: Annotated[str, Query(alias="tipo")],
) -> Suggestion:
    try:
        suggested = suggested_name(profile, venue_id, sport, kind, spaces)
    except Unavailable:
        raise InvalidData({"sede_id": VENUE_UNAVAILABLE}) from None
    return Suggestion(nombre=suggested.name, numero=suggested.number)


class SpaceRequest(BaseModel):
    sede_id: Identifier | None = None
    deporte: str = ""
    tipo: str = ""
    techada: bool | None = None
    iluminada: bool | None = None
    precio_por_hora: int | None = None
    numero: int | None = None


@router.post(
    "/espacios",
    status_code=status.HTTP_201_CREATED,
    response_model=SpaceView,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador da de alta espacios"},
        409: {
            "description": (
                "El número que se mostraba ya lo tomó otro alta: vuelve con el nombre y el "
                "número siguientes"
            )
        },
        422: {"model": ErrorBody},
    },
    summary="Dar de alta un espacio deportivo",
    description=(
        "El nombre se compone con la sede, la dirección, el deporte, el tipo y el número "
        "siguiente de ese tipo en esa sede. `numero` es el que vio el administrador; si se "
        "omite, se usa el siguiente."
    ),
    operation_id="alta_de_espacio_espacios_post",
)
def create_space_route(
    request: SpaceRequest,
    profile: Annotated[Perfil, Depends(usuario_actual)],
    spaces: Annotated[SpacesSql, Depends(spaces_repository)],
) -> SpaceView | Response:
    data = SpaceData(
        venue_id=request.sede_id,
        sport=request.deporte,
        kind=request.tipo,
        covered=request.techada,
        lit=request.iluminada,
        price_per_hour=request.precio_por_hora,
    )
    try:
        space = create_space(profile, data, request.numero, spaces)
    except Unavailable:
        raise InvalidData({"sede_id": VENUE_UNAVAILABLE}) from None
    except NumberTaken as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"errores": {"nombre": DUPLICATE}, "nombre": e.name, "numero": e.next_number},
        )
    except Duplicate:
        content: dict[str, object] = {"errores": {"nombre": DUPLICATE}}
        if request.sede_id is not None:
            try:
                s = suggested_name(profile, request.sede_id, request.deporte, request.tipo, spaces)
                content |= {"nombre": s.name, "numero": s.number}
            except (Unavailable, InvalidData):
                pass
        return JSONResponse(status_code=status.HTTP_409_CONFLICT, content=content)
    return space_view(space)


class SpaceChangeRequest(BaseModel):
    # The sport and the kind do not change: they are accepted and ignored, so a client that
    # resends the whole space keeps working, but they must be valid text.
    deporte: str | None = None
    tipo: str | None = None
    techada: bool | None = None
    iluminada: bool | None = None
    precio_por_hora: int | None = None


@router.put(
    "/espacios/{espacio_id}",
    response_model=SpaceView,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador edita espacios"},
        404: {"description": "El espacio o su sede ya no están activos"},
        422: {"model": ErrorBody},
    },
    summary="Editar un espacio",
    description=(
        "Condición, iluminación y precio por hora; lo que no viene queda como está. La sede, "
        "el deporte, el tipo y el nombre compuesto no cambian; las reservas ya hechas "
        "conservan su precio."
    ),
    operation_id="edicion_de_espacio_espacios__espacio_id__put",
)
def update_space_route(
    request: SpaceChangeRequest,
    profile: Annotated[Perfil, Depends(usuario_actual)],
    spaces: Annotated[SpacesSql, Depends(spaces_repository)],
    space_id: Annotated[Identifier, Path(alias="espacio_id")],
) -> SpaceView:
    space = update_space(
        profile,
        space_id,
        request.techada,
        request.iluminada,
        request.precio_por_hora,
        frozenset(request.model_fields_set),
        spaces,
    )
    return space_view(space)


@router.delete(
    "/espacios/{espacio_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador da de baja espacios"},
        404: {"description": "El espacio ya no está activo"},
        409: {"model": ErrorBody, "description": "El espacio tiene reservas que no terminaron"},
    },
    summary="Dar de baja un espacio",
    description=(
        "Baja lógica: el espacio deja de verse y de poder reservarse, y el historial lo sigue "
        "nombrando. No se permite con reservas activas sin terminar."
    ),
    operation_id="baja_de_espacio_espacios__espacio_id__delete",
)
def deactivate_space_route(
    profile: Annotated[Perfil, Depends(usuario_actual)],
    spaces: Annotated[SpacesSql, Depends(spaces_repository)],
    space_id: Annotated[Identifier, Path(alias="espacio_id")],
) -> Response:
    try:
        deactivate_space(profile, space_id, spaces)
    except HasFutureBookings:
        return conflict(
            {"espacio": "No se puede dar de baja el espacio porque posee reservas futuras."}
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
