import re
from datetime import time
from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.errores import DatosInvalidos, Duplicado, Prohibido
from app.aplicacion.sedes import dar_de_alta_sede, sedes_activas
from app.dominio.sedes import DatosSede, Sede
from app.dominio.usuarios import Perfil
from app.infraestructura.db import conexion
from app.infraestructura.sedes import SedesSql
from app.interfaz.sesion import SinSesion, usuario_actual

router = APIRouter(tags=["sedes"])


class SedeVista(BaseModel):
    id: int
    nombre: str
    direccion: str
    apertura: str
    cierre: str
    dias: list[int]
    canchas: int


class Sedes(BaseModel):
    sedes: list[SedeVista]


class ErroresDeSede(BaseModel):
    errores: dict[str, str]


def _hora(valor: time) -> str:
    return valor.strftime("%H:%M")


def _vista(sede: Sede) -> SedeVista:
    return SedeVista(
        id=sede.id,
        nombre=sede.nombre,
        direccion=sede.direccion,
        apertura=_hora(sede.apertura),
        cierre=_hora(sede.cierre),
        dias=list(sede.dias),
        canchas=sede.canchas,
    )


@router.get(
    "/sedes",
    response_model=Sedes,
    responses={401: {"model": SinSesion}},
    summary="Las sedes activas, por nombre, con cuántas canchas tiene cada una",
)
def listar_sedes(
    _: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> Sedes:
    return Sedes(sedes=[_vista(s) for s in sedes_activas(SedesSql(conn))])


class PedidoDeSede(BaseModel):
    nombre: str = ""
    direccion: str = ""
    apertura: str = ""
    cierre: str = ""
    dias: list[int] = []


_HORA = re.compile(r"\d{2}:\d{2}", re.ASCII)


def _leer_hora(valor: str) -> time | None:
    """`HH:MM` y nada más: `fromisoformat` también acepta zonas y formatos que no van."""
    if not _HORA.fullmatch(valor):
        return None
    try:
        return time.fromisoformat(valor)
    except ValueError:
        return None


@router.post(
    "/sedes",
    status_code=status.HTTP_201_CREATED,
    response_model=SedeVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador da de alta sedes"},
        409: {"model": ErroresDeSede, "description": "Otra sede activa ya tiene ese nombre"},
        422: {"model": ErroresDeSede},
    },
    summary="Dar de alta una sede",
    description="Horas en punto; un cierre a las 00:00 es la medianoche del mismo día.",
)
def alta_de_sede(
    pedido: PedidoDeSede,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> SedeVista | Response:
    datos = DatosSede(
        nombre=pedido.nombre,
        direccion=pedido.direccion,
        apertura=_leer_hora(pedido.apertura),
        cierre=_leer_hora(pedido.cierre),
        dias=tuple(pedido.dias),
    )
    try:
        sede = dar_de_alta_sede(perfil, datos, SedesSql(conn))
    except Prohibido:
        return Response(status_code=status.HTTP_403_FORBIDDEN)
    except DatosInvalidos as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
        )
    except Duplicado:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"errores": {"nombre": "Ya existe una sede con ese nombre"}},
        )
    return _vista(sede)
