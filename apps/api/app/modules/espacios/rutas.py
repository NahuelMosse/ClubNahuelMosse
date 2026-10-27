# kit-shape: las rutas de espacios y los modelos de sus pedidos y respuestas se leen juntos
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, Query, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.espacios.casos_de_uso import (
    catalogo,
    dar_de_alta_espacio,
    dar_de_baja_espacio,
    editar_espacio,
    espacios_activos,
    nombre_sugerido,
)
from app.modules.espacios.reglas import DatosEspacio, Espacio
from app.modules.espacios.repositorio import EspaciosSql, repositorio_espacios
from app.modules.sesion import Perfil, SinSesion, usuario_actual
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

DUPLICADO = "Ya existe un espacio deportivo con ese nombre en la sede seleccionada."
SEDE_NO_DISPONIBLE = "La sede ya no está disponible"


class TipoVista(BaseModel):
    clave: str
    nombre: str


class DeporteVista(BaseModel):
    clave: str
    nombre: str
    tipos: list[TipoVista]


class Catalogo(BaseModel):
    deportes: list[DeporteVista]


@router.get(
    "/espacios/catalogo",
    response_model=Catalogo,
    responses={401: {"model": SinSesion}},
    summary="Los deportes y sus tipos de cancha",
)
def ver_catalogo(_: Annotated[Perfil, Depends(usuario_actual)]) -> Catalogo:
    return Catalogo(
        deportes=[DeporteVista.model_validate(d, from_attributes=True) for d in catalogo()]
    )


class EspacioVista(BaseModel):
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


class ListaDeEspacios(BaseModel):
    espacios: list[EspacioVista]


def vista_de_espacio(e: Espacio) -> EspacioVista:
    return EspacioVista.model_validate(e, from_attributes=True)


@router.get(
    "/espacios",
    response_model=ListaDeEspacios,
    responses={401: {"model": SinSesion}},
    summary="Los espacios activos de las sedes activas, por sede, deporte, tipo y número",
)
def listar_espacios(
    _: Annotated[Perfil, Depends(usuario_actual)],
    espacios: Annotated[EspaciosSql, Depends(repositorio_espacios)],
    sede_id: Annotated[Identifier | None, Query()] = None,
    deporte: Annotated[str | None, Query(min_length=1)] = None,
    tipo: Annotated[str | None, Query(min_length=1)] = None,
) -> ListaDeEspacios:
    activos = espacios_activos(espacios, sede_id, deporte, tipo)
    return ListaDeEspacios(espacios=[vista_de_espacio(e) for e in activos])


class Sugerencia(BaseModel):
    nombre: str
    numero: int


class Errores(BaseModel):
    errores: dict[str, str]


@router.get(
    "/espacios/nombre",
    response_model=Sugerencia,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador da de alta espacios"},
        422: {"model": Errores},
    },
    summary="El nombre que tendría el próximo espacio de ese tipo en esa sede",
)
def sugerir_nombre(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    espacios: Annotated[EspaciosSql, Depends(repositorio_espacios)],
    sede_id: Annotated[Identifier, Query()],
    deporte: Annotated[str, Query()],
    tipo: Annotated[str, Query()],
) -> Sugerencia:
    try:
        s = nombre_sugerido(perfil, sede_id, deporte, tipo, espacios)
    except Unavailable:
        raise InvalidData({"sede_id": SEDE_NO_DISPONIBLE}) from None
    return Sugerencia.model_validate(s, from_attributes=True)


class PedidoDeEspacio(BaseModel):
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
    response_model=EspacioVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador da de alta espacios"},
        409: {
            "description": (
                "El número que se mostraba ya lo tomó otro alta: vuelve con el nombre y el "
                "número siguientes"
            )
        },
        422: {"model": Errores},
    },
    summary="Dar de alta un espacio deportivo",
    description=(
        "El nombre se compone con la sede, la dirección, el deporte, el tipo y el número "
        "siguiente de ese tipo en esa sede. `numero` es el que vio el administrador; si se "
        "omite, se usa el siguiente."
    ),
)
def alta_de_espacio(
    pedido: PedidoDeEspacio,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    espacios: Annotated[EspaciosSql, Depends(repositorio_espacios)],
) -> EspacioVista | Response:
    datos = DatosEspacio(
        sede_id=pedido.sede_id,
        deporte=pedido.deporte,
        tipo=pedido.tipo,
        techada=pedido.techada,
        iluminada=pedido.iluminada,
        precio_por_hora=pedido.precio_por_hora,
    )
    try:
        espacio = dar_de_alta_espacio(perfil, datos, pedido.numero, espacios)
    except Unavailable:
        raise InvalidData({"sede_id": SEDE_NO_DISPONIBLE}) from None
    except NumberTaken as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"errores": {"nombre": DUPLICADO}, "nombre": e.name, "numero": e.next_number},
        )
    except Duplicate:
        contenido: dict[str, object] = {"errores": {"nombre": DUPLICADO}}
        if pedido.sede_id is not None:
            try:
                s = nombre_sugerido(perfil, pedido.sede_id, pedido.deporte, pedido.tipo, espacios)
                contenido |= {"nombre": s.nombre, "numero": s.numero}
            except (Unavailable, InvalidData):
                pass
        return JSONResponse(status_code=status.HTTP_409_CONFLICT, content=contenido)
    return vista_de_espacio(espacio)


class PedidoDeCambioDeEspacio(BaseModel):
    # El deporte y el tipo no cambian: se aceptan y se ignoran, para que un cliente que reenvía
    # el espacio entero siga andando, pero tienen que ser texto válido.
    deporte: str | None = None
    tipo: str | None = None
    techada: bool | None = None
    iluminada: bool | None = None
    precio_por_hora: int | None = None


@router.put(
    "/espacios/{espacio_id}",
    response_model=EspacioVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador edita espacios"},
        404: {"description": "El espacio o su sede ya no están activos"},
        422: {"model": Errores},
    },
    summary="Editar un espacio",
    description=(
        "Condición, iluminación y precio por hora; lo que no viene queda como está. La sede, "
        "el deporte, el tipo y el nombre compuesto no cambian; las reservas ya hechas "
        "conservan su precio."
    ),
)
def edicion_de_espacio(
    pedido: PedidoDeCambioDeEspacio,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    espacios: Annotated[EspaciosSql, Depends(repositorio_espacios)],
    espacio_id: Annotated[Identifier, Path()],
) -> EspacioVista:
    espacio = editar_espacio(
        perfil,
        espacio_id,
        pedido.techada,
        pedido.iluminada,
        pedido.precio_por_hora,
        frozenset(pedido.model_fields_set),
        espacios,
    )
    return vista_de_espacio(espacio)


@router.delete(
    "/espacios/{espacio_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador da de baja espacios"},
        404: {"description": "El espacio ya no está activo"},
        409: {"model": Errores, "description": "El espacio tiene reservas que no terminaron"},
    },
    summary="Dar de baja un espacio",
    description=(
        "Baja lógica: el espacio deja de verse y de poder reservarse, y el historial lo sigue "
        "nombrando. No se permite con reservas activas sin terminar."
    ),
)
def baja_de_espacio(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    espacios: Annotated[EspaciosSql, Depends(repositorio_espacios)],
    espacio_id: Annotated[Identifier, Path()],
) -> Response:
    try:
        dar_de_baja_espacio(perfil, espacio_id, espacios)
    except HasFutureBookings:
        return conflict(
            {"espacio": "No se puede dar de baja el espacio porque posee reservas futuras."}
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
