from datetime import time
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from app.modules.sedes.casos_de_uso import (
    dar_de_alta_sede,
    dar_de_baja_sede,
    editar_sede,
    sedes_activas,
)
from app.modules.sedes.reglas import DatosSede, Sede
from app.modules.sedes.repositorio import SedesSql, repositorio_sedes
from app.modules.sesion import Perfil, SinSesion, usuario_actual
from app.shared.entradas import Identificador, leer_hora
from app.shared.errores import ConReservasFuturas, Duplicado, ReservasAfuera
from app.shared.respuestas import conflicto

router = APIRouter(tags=["sedes"])


class SedeVista(BaseModel):
    id: int
    nombre: str
    direccion: str
    apertura: str
    cierre: str
    dias: list[int]
    canchas: int
    deportes: list[str]


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
        deportes=list(sede.deportes),
    )


@router.get(
    "/sedes",
    response_model=Sedes,
    responses={401: {"model": SinSesion}},
    summary="Las sedes activas, por nombre, con sus canchas y los deportes que ofrecen",
)
def listar_sedes(
    _: Annotated[Perfil, Depends(usuario_actual)],
    sedes: Annotated[SedesSql, Depends(repositorio_sedes)],
) -> Sedes:
    return Sedes(sedes=[_vista(s) for s in sedes_activas(sedes)])


class PedidoDeSede(BaseModel):
    nombre: str = ""
    direccion: str = ""
    apertura: str = ""
    cierre: str = ""
    # Los días de la semana van de 1 a 7: más de siete no tiene sentido.
    dias: Annotated[list[int], Field(max_length=7)] = []


def _datos(pedido: PedidoDeSede) -> DatosSede:
    return DatosSede(
        nombre=pedido.nombre,
        direccion=pedido.direccion,
        apertura=leer_hora(pedido.apertura),
        cierre=leer_hora(pedido.cierre),
        dias=tuple(pedido.dias),
    )


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
    sedes: Annotated[SedesSql, Depends(repositorio_sedes)],
) -> SedeVista | Response:
    try:
        sede = dar_de_alta_sede(perfil, _datos(pedido), sedes)
    except Duplicado:
        return conflicto({"nombre": "Ya existe una sede con ese nombre"})
    return _vista(sede)


class PedidoDeEdicionDeSede(PedidoDeSede):
    # Guardar igual un horario que deja reservas futuras afuera.
    confirmar: bool = False


class ReservasFueraDelHorario(BaseModel):
    reservas_afuera: int


@router.put(
    "/sedes/{sede_id}",
    response_model=SedeVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador edita sedes"},
        404: {"description": "La sede ya no está activa"},
        409: {
            "model": ErroresDeSede | ReservasFueraDelHorario,
            "description": "Otra sede activa ya tiene ese nombre, o el horario nuevo deja "
            "afuera reservas futuras y falta `confirmar`",
        },
        422: {"model": ErroresDeSede},
    },
    summary="Editar una sede",
    description=(
        "Los mismos datos y reglas que el alta. Las reservas ya hechas se mantienen aunque "
        "queden fuera del horario nuevo, que rige para las que vengan."
    ),
)
def edicion_de_sede(
    pedido: PedidoDeEdicionDeSede,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    sedes: Annotated[SedesSql, Depends(repositorio_sedes)],
    sede_id: Annotated[Identificador, Path()],
) -> SedeVista | Response:
    try:
        sede = editar_sede(perfil, sede_id, _datos(pedido), pedido.confirmar, sedes)
    except Duplicado:
        return conflicto({"nombre": "Ya existe una sede con ese nombre"})
    except ReservasAfuera as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT, content={"reservas_afuera": e.cantidad}
        )
    return _vista(sede)


@router.delete(
    "/sedes/{sede_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador da de baja sedes"},
        404: {"description": "La sede ya no está activa"},
        409: {"model": ErroresDeSede, "description": "La sede tiene reservas que no terminaron"},
    },
    summary="Dar de baja una sede",
    description=(
        "Baja lógica: la sede y sus espacios dejan de verse y de poder reservarse, y el "
        "historial los sigue nombrando. No se permite con reservas activas sin terminar."
    ),
)
def baja_de_sede(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    sedes: Annotated[SedesSql, Depends(repositorio_sedes)],
    sede_id: Annotated[Identificador, Path()],
) -> Response:
    try:
        dar_de_baja_sede(perfil, sede_id, sedes)
    except ConReservasFuturas:
        return conflicto(
            {"sede": "No se puede dar de baja la sede porque posee reservas futuras asociadas."}
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
