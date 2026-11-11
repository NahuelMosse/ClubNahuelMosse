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

router = APIRouter(tags=["notifications"])


class DeviceRequest(BaseModel):
    token: str
    platform: Literal["android", "ios"]
    permission_granted: bool


class DeviceUnregistration(BaseModel):
    token: str


class Errors(BaseModel):
    errors: dict[str, str]


@router.put(
    "/devices",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        403: {"description": "An administrator does not receive notices"},
        409: {"description": "The account is no longer active"},
        422: {"model": Errors},
    },
    summary="Register the phone to receive notices",
    description=(
        "`permission_granted` is what the operating system answered about notifications: "
        "without permission the notices stay only in the center. If the token was already in "
        "the name of another account, it moves to the requester."
    ),
)
def register(
    request: DeviceRequest,
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
) -> Response:
    try:
        register_device(
            notifications, profile, request.token, request.platform, request.permission_granted
        )
    except Unavailable:
        return Response(status_code=status.HTTP_409_CONFLICT)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/devices/unregister",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": NoSession}},
    summary="Unregister the phone when the session closes",
    description=(
        "Stops receiving notices for this account. If it was not registered, it answers the same."
    ),
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
    kind: NoticeKind
    title: str
    body: str
    booking_id: UUID | None
    created_at: datetime
    read: bool


class Center(BaseModel):
    notifications: list[NotificationView]
    unread: int


def _view(n: Notification) -> NotificationView:
    return NotificationView(
        id=n.id,
        kind=n.kind,
        title=n.title,
        body=n.body,
        booking_id=n.booking_id,
        created_at=n.created_at,
        read=n.read,
    )


@router.get(
    "/notifications",
    response_model=Center,
    responses={401: {"model": NoSession}},
    summary="The notification center of whoever asks",
    description=("The latest 100, from newest to oldest, and how many are unread in total."),
)
def center(
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
) -> Center:
    items, unread = my_notifications(notifications, profile)
    return Center(notifications=[_view(n) for n in items], unread=unread)


@router.post(
    "/notifications/read-all",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": NoSession}},
    summary="Mark all notifications as read",
)
def read_all(
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
) -> Response:
    mark_all_read(notifications, profile)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/notifications/{notification_id}/read",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        404: {"description": "The requester has no notification with that number"},
    },
    summary="Mark a notification as read",
    description="Marking one that was already read answers the same.",
)
def read(
    profile: Annotated[Profile, Depends(current_user)],
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
    notification_id: Annotated[Identifier, Path()],
) -> Response:
    mark_read(notifications, profile, notification_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
