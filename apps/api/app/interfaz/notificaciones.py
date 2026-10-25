from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Path, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.aplicacion.errores import DatosInvalidos, NoDisponible, NoEncontrada, Prohibido
from app.aplicacion.notificaciones import (
    dar_de_baja_dispositivo,
    marcar_leida,
    marcar_todas,
    mis_notificaciones,
    registrar_dispositivo,
)
from app.dependencias import NotificacionesSql, repositorio_notificaciones
from app.dominio.notificaciones import Notificacion, TipoDeAviso
from app.dominio.usuarios import Perfil
from app.interfaz.entradas import TokenDeDispositivo
from app.interfaz.reservas import Errores
from app.interfaz.sesion import SinSesion, usuario_actual

router = APIRouter(tags=["notificaciones"])


class PedidoDeDispositivo(BaseModel):
    token: TokenDeDispositivo
    plataforma: Literal["android", "ios"]
    permiso: bool


class BajaDeDispositivo(BaseModel):
    token: TokenDeDispositivo


@router.put(
    "/dispositivos",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": SinSesion},
        403: {"description": "El administrador no recibe avisos"},
        409: {"description": "La cuenta ya no está activa"},
        422: {"model": Errores},
    },
    summary="Registrar el teléfono para recibir avisos",
    description=(
        "`permiso` es lo que el sistema operativo contestó sobre las notificaciones: sin "
        "permiso los avisos quedan sólo en el centro. Si el token ya estaba a nombre de otra "
        "cuenta, pasa a quien pide."
    ),
)
def registrar(
    pedido: PedidoDeDispositivo,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Response:
    try:
        registrar_dispositivo(
            notificaciones, perfil, pedido.token, pedido.plataforma, pedido.permiso
        )
    except Prohibido:
        return Response(status_code=status.HTTP_403_FORBIDDEN)
    except DatosInvalidos as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
        )
    except NoDisponible:
        return Response(status_code=status.HTTP_409_CONFLICT)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/dispositivos/baja",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": SinSesion}},
    summary="Dar de baja el teléfono al cerrar la sesión",
    description="Deja de recibir avisos de esta cuenta. Si no estaba registrado, responde igual.",
)
def baja(
    pedido: BajaDeDispositivo,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Response:
    dar_de_baja_dispositivo(notificaciones, perfil, pedido.token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class NotificacionVista(BaseModel):
    id: int
    tipo: TipoDeAviso
    titulo: str
    cuerpo: str
    reserva_id: int | None
    creada_en: datetime
    leida: bool


class Centro(BaseModel):
    notificaciones: list[NotificacionVista]
    no_leidas: int


def _vista(n: Notificacion) -> NotificacionVista:
    return NotificacionVista(
        id=n.id,
        tipo=n.tipo,
        titulo=n.titulo,
        cuerpo=n.cuerpo,
        reserva_id=n.reserva_id,
        creada_en=n.creada_en,
        leida=n.leida,
    )


@router.get(
    "/notificaciones",
    response_model=Centro,
    responses={401: {"model": SinSesion}},
    summary="El centro de notificaciones de quien consulta",
    description=(
        "Las últimas 100, de la más nueva a la más vieja, y cuántas hay sin leer en total."
    ),
)
def centro(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Centro:
    lista, sin_leer = mis_notificaciones(notificaciones, perfil)
    return Centro(notificaciones=[_vista(n) for n in lista], no_leidas=sin_leer)


@router.post(
    "/notificaciones/leer-todas",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": SinSesion}},
    summary="Marcar todas las notificaciones como leídas",
)
def leer_todas(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Response:
    marcar_todas(notificaciones, perfil)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/notificaciones/{notificacion_id}/leer",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": SinSesion},
        404: {"description": "No hay una notificación de quien pide con ese número"},
    },
    summary="Marcar una notificación como leída",
    description="Marcar una que ya estaba leída responde igual.",
)
def leer(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
    notificacion_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
) -> Response:
    try:
        marcar_leida(notificaciones, perfil, notificacion_id)
    except NoEncontrada:
        return Response(status_code=status.HTTP_404_NOT_FOUND)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
