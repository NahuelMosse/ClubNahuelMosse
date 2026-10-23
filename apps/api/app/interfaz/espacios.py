from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.errores import (
    ConReservasFuturas,
    DatosInvalidos,
    Duplicado,
    NoDisponible,
    NoEncontrada,
    NumeroOcupado,
    Prohibido,
)
from app.aplicacion.espacios import (
    catalogo,
    dar_de_alta_espacio,
    dar_de_baja_espacio,
    editar_espacio,
    espacios_activos,
    nombre_sugerido,
)
from app.dominio.espacios import DatosEspacio, Espacio
from app.dominio.usuarios import Perfil
from app.infraestructura.db import conexion
from app.infraestructura.espacios import EspaciosSql
from app.interfaz.entradas import Identificador, Texto40
from app.interfaz.respuestas import conflicto, datos_invalidos, no_encontrado, sin_permiso
from app.interfaz.sesion import SinSesion, usuario_actual

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
        deportes=[
            DeporteVista(
                clave=d.clave,
                nombre=d.nombre,
                tipos=[TipoVista(clave=t.clave, nombre=t.nombre) for t in d.tipos],
            )
            for d in catalogo()
        ]
    )


class EspacioVista(BaseModel):
    id: int
    nombre: str
    sede_id: int
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
    return EspacioVista(
        id=e.id,
        nombre=e.nombre,
        sede_id=e.sede_id,
        sede=e.sede,
        deporte=e.deporte,
        tipo=e.tipo,
        numero=e.numero,
        techada=e.techada,
        iluminada=e.iluminada,
        precio_por_hora=e.precio_por_hora,
    )


@router.get(
    "/espacios",
    response_model=ListaDeEspacios,
    responses={401: {"model": SinSesion}},
    summary="Los espacios activos de las sedes activas, por sede, deporte, tipo y número",
)
def listar_espacios(
    _: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    sede_id: Annotated[int | None, Query(ge=1, le=2**63 - 1)] = None,
    deporte: Annotated[Texto40 | None, Query(min_length=1)] = None,
    tipo: Annotated[Texto40 | None, Query(min_length=1)] = None,
) -> ListaDeEspacios:
    espacios = espacios_activos(EspaciosSql(conn), sede_id, deporte, tipo)
    return ListaDeEspacios(espacios=[vista_de_espacio(e) for e in espacios])


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
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    sede_id: Annotated[Identificador, Query()],
    deporte: Annotated[Texto40, Query()],
    tipo: Annotated[Texto40, Query()],
) -> Sugerencia | Response:
    try:
        s = nombre_sugerido(perfil, sede_id, deporte, tipo, EspaciosSql(conn))
    except Prohibido:
        return sin_permiso()
    except DatosInvalidos as e:
        return datos_invalidos(e.errores)
    except NoDisponible:
        return datos_invalidos({"sede_id": SEDE_NO_DISPONIBLE})
    return Sugerencia(nombre=s.nombre, numero=s.numero)


class PedidoDeEspacio(BaseModel):
    sede_id: Identificador | None = None
    deporte: Texto40 = ""
    tipo: Texto40 = ""
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
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> EspacioVista | Response:
    datos = DatosEspacio(
        sede_id=pedido.sede_id,
        deporte=pedido.deporte,
        tipo=pedido.tipo,
        techada=pedido.techada,
        iluminada=pedido.iluminada,
        precio_por_hora=pedido.precio_por_hora,
    )
    espacios = EspaciosSql(conn)
    try:
        espacio = dar_de_alta_espacio(perfil, datos, pedido.numero, espacios)
    except Prohibido:
        return sin_permiso()
    except DatosInvalidos as e:
        return datos_invalidos(e.errores)
    except NoDisponible:
        return datos_invalidos({"sede_id": SEDE_NO_DISPONIBLE})
    except NumeroOcupado as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"errores": {"nombre": DUPLICADO}, "nombre": e.nombre, "numero": e.siguiente},
        )
    except Duplicado:
        contenido: dict[str, object] = {"errores": {"nombre": DUPLICADO}}
        if pedido.sede_id is not None:
            try:
                s = nombre_sugerido(perfil, pedido.sede_id, pedido.deporte, pedido.tipo, espacios)
                contenido |= {"nombre": s.nombre, "numero": s.numero}
            except (NoDisponible, DatosInvalidos):
                pass
        return JSONResponse(status_code=status.HTTP_409_CONFLICT, content=contenido)
    return vista_de_espacio(espacio)


class PedidoDeCambio(BaseModel):
    # El deporte y el tipo no cambian: se aceptan y se ignoran, para que un cliente que reenvía
    # el espacio entero siga andando, pero tienen que ser texto válido.
    deporte: Texto40 | None = None
    tipo: Texto40 | None = None
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
    pedido: PedidoDeCambio,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    espacio_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
) -> EspacioVista | Response:
    try:
        espacio = editar_espacio(
            perfil,
            espacio_id,
            pedido.techada,
            pedido.iluminada,
            pedido.precio_por_hora,
            frozenset(pedido.model_fields_set),
            EspaciosSql(conn),
        )
    except Prohibido:
        return sin_permiso()
    except NoEncontrada:
        return no_encontrado()
    except DatosInvalidos as e:
        return datos_invalidos(e.errores)
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
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    espacio_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
) -> Response:
    try:
        dar_de_baja_espacio(perfil, espacio_id, EspaciosSql(conn))
    except Prohibido:
        return sin_permiso()
    except NoEncontrada:
        return no_encontrado()
    except ConReservasFuturas:
        return conflicto(
            {"espacio": "No se puede dar de baja el espacio porque posee reservas futuras."}
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
