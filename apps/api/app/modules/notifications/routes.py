# kit-shape: the notification routes and the models of their requests and responses read together
from datetime import datetime
from typing import Annotated, Literal
from uuid import UUID

from fastapi import APIRouter, Depends, Path, Response, status
from pydantic import BaseModel

from app.modules.notifications.repository import NotificationsSql, notifications_repository
from app.modules.notifications.rules import NoticeKind, Notification
from app.modules.notifications.use_cases import (
    deactivate_device,
    mark_all_read,
    mark_read,
    my_notifications,
    register_device,
)
from app.modules.session import NoSession, Profile, current_user
from app.shared.errors import Unavailable
from app.shared.input_validation import Identifier

router = APIRouter(tags=["notificaciones"])


class DeviceRequest(BaseModel):
    token: str
    plataforma: Literal["android", "ios"]
    permiso: bool


class DeviceUnregistration(BaseModel):
    token: str


class Errors(BaseModel):
    errores: dict[str, str]


@router.put(
    "/dispositivos",
    operation_id="registrar_dispositivos_put",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        403: {"description": "El administrador no recibe avisos"},
        409: {"description": "La cuenta ya no está activa"},
        422: {"model": Errors},
    },
    summary="Registrar el teléfono para recibir avisos",
    description=(
        "`permiso` es lo que el sistema operativo contestó sobre las notificaciones: sin "
        "permiso los avisos quedan sólo en el centro. Si el token ya estaba a nombre de otra "
        "cuenta, pasa a quien pide."
    ),
)
def register(
    request: DeviceRequest,
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
) -> Response:
    try:
        register_device(notifications, profile, request.token, request.plataforma, request.permiso)
    except Unavailable:
        return Response(status_code=status.HTTP_409_CONFLICT)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/dispositivos/baja",
    operation_id="baja_dispositivos_baja_post",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": NoSession}},
    summary="Dar de baja el teléfono al cerrar la sesión",
    description="Deja de recibir avisos de esta cuenta. Si no estaba registrado, responde igual.",
)
def unregister(
    request: DeviceUnregistration,
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
) -> Response:
    deactivate_device(notifications, profile, request.token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class NotificationView(BaseModel):
    id: UUID
    tipo: NoticeKind
    titulo: str
    cuerpo: str
    reserva_id: UUID | None
    creada_en: datetime
    leida: bool


class Center(BaseModel):
    notificaciones: list[NotificationView]
    no_leidas: int


def _view(n: Notification) -> NotificationView:
    return NotificationView(
        id=n.id,
        tipo=n.kind,
        titulo=n.title,
        cuerpo=n.body,
        reserva_id=n.booking_id,
        creada_en=n.created_at,
        leida=n.read,
    )


@router.get(
    "/notificaciones",
    operation_id="centro_notificaciones_get",
    response_model=Center,
    responses={401: {"model": NoSession}},
    summary="El centro de notificaciones de quien consulta",
    description=(
        "Las últimas 100, de la más nueva a la más vieja, y cuántas hay sin leer en total."
    ),
)
def center(
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
) -> Center:
    items, unread = my_notifications(notifications, profile)
    return Center(notificaciones=[_view(n) for n in items], no_leidas=unread)


@router.post(
    "/notificaciones/leer-todas",
    operation_id="leer_todas_notificaciones_leer_todas_post",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": NoSession}},
    summary="Marcar todas las notificaciones como leídas",
)
def read_all(
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
) -> Response:
    mark_all_read(notifications, profile)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/notificaciones/{notificacion_id}/leer",
    operation_id="leer_notificaciones__notificacion_id__leer_post",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        404: {"description": "No hay una notificación de quien pide con ese número"},
    },
    summary="Marcar una notificación como leída",
    description="Marcar una que ya estaba leída responde igual.",
)
def read(
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
    notification_id: Annotated[Identifier, Path(alias="notificacion_id")],
) -> Response:
    mark_read(notifications, profile, notification_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
