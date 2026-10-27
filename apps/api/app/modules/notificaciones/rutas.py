# kit-shape: las rutas de notificaciones y los modelos de sus pedidos y respuestas se leen juntos
from datetime import datetime
from typing import Annotated, Literal
from uuid import UUID

from fastapi import APIRouter, Depends, Path, Response, status
from pydantic import BaseModel

from app.modules.notificaciones.casos_de_uso import (
    dar_de_baja_dispositivo,
    marcar_leida,
    marcar_todas,
    mis_notificaciones,
    registrar_dispositivo,
)
from app.modules.notificaciones.reglas import Notificacion, TipoDeAviso
from app.modules.notificaciones.repositorio import NotificacionesSql, repositorio_notificaciones
from app.modules.session import NoSession, Profile, current_user
from app.shared.errors import Unavailable
from app.shared.input_validation import Identifier

router = APIRouter(tags=["notificaciones"])


class PedidoDeDispositivo(BaseModel):
    token: str
    plataforma: Literal["android", "ios"]
    permiso: bool


class BajaDeDispositivo(BaseModel):
    token: str


class Errores(BaseModel):
    errores: dict[str, str]


@router.put(
    "/dispositivos",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
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
    perfil: Annotated[Profile, Depends(current_user)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Response:
    try:
        registrar_dispositivo(
            notificaciones, perfil, pedido.token, pedido.plataforma, pedido.permiso
        )
    except Unavailable:
        return Response(status_code=status.HTTP_409_CONFLICT)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/dispositivos/baja",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": NoSession}},
    summary="Dar de baja el teléfono al cerrar la sesión",
    description="Deja de recibir avisos de esta cuenta. Si no estaba registrado, responde igual.",
)
def baja(
    pedido: BajaDeDispositivo,
    perfil: Annotated[Profile, Depends(current_user)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Response:
    dar_de_baja_dispositivo(notificaciones, perfil, pedido.token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class NotificacionVista(BaseModel):
    id: UUID
    tipo: TipoDeAviso
    titulo: str
    cuerpo: str
    reserva_id: UUID | None
    creada_en: datetime
    leida: bool


class Centro(BaseModel):
    notificaciones: list[NotificacionVista]
    no_leidas: int


def _vista(n: Notificacion) -> NotificacionVista:
    return NotificacionVista.model_validate(n, from_attributes=True)


@router.get(
    "/notificaciones",
    response_model=Centro,
    responses={401: {"model": NoSession}},
    summary="El centro de notificaciones de quien consulta",
    description=(
        "Las últimas 100, de la más nueva a la más vieja, y cuántas hay sin leer en total."
    ),
)
def centro(
    perfil: Annotated[Profile, Depends(current_user)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Centro:
    lista, sin_leer = mis_notificaciones(notificaciones, perfil)
    return Centro(notificaciones=[_vista(n) for n in lista], no_leidas=sin_leer)


@router.post(
    "/notificaciones/leer-todas",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": NoSession}},
    summary="Marcar todas las notificaciones como leídas",
)
def leer_todas(
    perfil: Annotated[Profile, Depends(current_user)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Response:
    marcar_todas(notificaciones, perfil)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/notificaciones/{notificacion_id}/leer",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        404: {"description": "No hay una notificación de quien pide con ese número"},
    },
    summary="Marcar una notificación como leída",
    description="Marcar una que ya estaba leída responde igual.",
)
def leer(
    perfil: Annotated[Profile, Depends(current_user)],
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
    notificacion_id: Annotated[Identifier, Path()],
) -> Response:
    marcar_leida(notificaciones, perfil, notificacion_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
