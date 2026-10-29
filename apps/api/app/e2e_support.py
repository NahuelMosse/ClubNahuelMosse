# kit-shape: the models of the test requests and the routes that use them are read together
"""What the scenarios need to see or force and the app cannot. It only exists with `PRUEBAS=1`.
Wire names (routes, JSON keys, query parameters) stay in Spanish; Python names are English."""

from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Response, status
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import text

from app.modules.notifications import (
    NotificationsSql,
    notifications_repository,
    push_channel,
    send_reminders,
)
from app.modules.password_recovery import hash_of
from app.shared.club_timezone import CLUB_TIMEZONE_NAME
from app.shared.db import DbConnection
from app.shared.errors import NotFound
from app.shared.stored_values import stored

router = APIRouter(prefix="/_pruebas", include_in_schema=False)


class _Wire(BaseModel):
    model_config = ConfigDict(populate_by_name=True)


class Email(_Wire):
    subject: str = Field(alias="asunto")
    body: str = Field(alias="cuerpo")


class Outbox(_Wire):
    emails: list[Email] = Field(alias="correos")


@router.get("/correos", response_model_by_alias=True)
def outbox(conn: DbConnection, recipient: Annotated[str, Query(alias="para")]) -> Outbox:
    rows = conn.execute(
        text("SELECT subject, body FROM outgoing_email WHERE recipient = :p ORDER BY id"),
        {"p": recipient.strip().lower()},
    ).all()
    return Outbox(emails=[Email(subject=r.subject, body=r.body) for r in rows])


class Occupation(_Wire):
    space: str = Field(alias="espacio")
    day: date = Field(alias="fecha")
    hour: int = Field(alias="hora")
    hours: int = Field(1, alias="horas")
    # Whose booking it is; without an email, the first account in the database.
    email: str | None = Field(None, alias="correo")
    status: str = Field("activa", alias="estado")
    reason: str | None = Field(None, alias="motivo")


@router.post("/reservas", status_code=status.HTTP_204_NO_CONTENT)
def occupy(occupation: Occupation, conn: DbConnection) -> Response:
    """A booking loaded outside the app, for [email] or for someone else."""
    values = occupation.model_dump() | {
        "status": stored(occupation.status),
        "active_status": stored("activa"),
    }
    inserted = conn.execute(
        text(
            "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total,"
            " status, reason, canceled_at)"
            " SELECT u.id, e.id, x.starts_at,"
            "        x.starts_at + make_interval(hours => :hours),"
            "        e.price_per_hour, e.price_per_hour * :hours, :status, :reason,"
            "        CASE WHEN CAST(:status AS text) <> :active_status THEN now() END"
            " FROM space e,"
            "      LATERAL (SELECT (CAST(:day AS date) + make_interval(hours => :hour))"
            f"               AT TIME ZONE '{CLUB_TIMEZONE_NAME}' AS starts_at) x,"
            "      (SELECT id FROM app_user WHERE CAST(:email AS text) IS NULL"
            "         AND id = (SELECT id FROM app_user ORDER BY id LIMIT 1)"
            "       UNION ALL"
            "       SELECT id FROM app_user WHERE active"
            "         AND lower(email) = lower(CAST(:email AS text))) u"
            " WHERE e.name = :space"
        ),
        values,
    ).rowcount
    conn.commit()
    if inserted != 1:
        raise NotFound()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/reservas/vaciar", status_code=status.HTTP_204_NO_CONTENT)
def clear_bookings(conn: DbConnection) -> Response:
    """The system is left with no bookings, nor the notices that mention them: the run
    database is a single one and the global-history scenarios start from zero."""
    conn.execute(text("TRUNCATE notification_booking, notification, booking"))
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class SpaceName(_Wire):
    space: str = Field(alias="espacio")


@router.post("/reservas/empezar", status_code=status.HTTP_204_NO_CONTENT)
def start(request: SpaceName, conn: DbConnection) -> Response:
    """The next active booking of [space] starts at the club's current hour, as if time
    had run while the app was open."""
    conn.execute(
        text(
            "UPDATE booking b SET ends_at = x.current_hour + (b.ends_at - b.starts_at),"
            " starts_at = x.current_hour"
            f" FROM (SELECT date_trunc('hour', now(), '{CLUB_TIMEZONE_NAME}')"
            "                  AS current_hour) x"
            " WHERE b.id = (SELECT b2.id FROM booking b2 JOIN space e ON e.id = b2.space_id"
            "               WHERE e.name = :space AND b2.status = :active_status"
            "               ORDER BY b2.starts_at LIMIT 1)"
        ),
        request.model_dump() | {"active_status": stored("activa")},
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/reservas/anular", status_code=status.HTTP_204_NO_CONTENT)
def cancel(request: SpaceName, conn: DbConnection) -> Response:
    """The club cancels the active bookings of [space], as an administrator would."""
    conn.execute(
        text(
            "UPDATE booking b SET status = :voided, reason = 'mantenimiento de la cancha',"
            " canceled_at = now(), canceled_by = (SELECT id FROM app_user ORDER BY id LIMIT 1)"
            " FROM space e WHERE e.id = b.space_id AND e.name = :space"
            " AND b.status = :active_status"
        ),
        request.model_dump() | {"voided": stored("anulada"), "active_status": stored("activa")},
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class BranchName(_Wire):
    name: str = Field(alias="nombre")


@router.post("/sedes/baja", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_branch(request: BranchName, conn: DbConnection) -> Response:
    """The branch [name] stops being active, as if another administrator deactivated it."""
    conn.execute(
        text(
            "UPDATE venue SET active = false, deactivated_at = now(),"
            " deactivated_by = (SELECT id FROM app_user ORDER BY id LIMIT 1)"
            " WHERE name = :name AND active"
        ),
        request.model_dump(),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/espacios/baja", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_space(request: SpaceName, conn: DbConnection) -> Response:
    """The space [space] stops being active, as if another administrator deactivated it."""
    conn.execute(
        text(
            "UPDATE space SET active = false, deactivated_at = now(),"
            " deactivated_by = (SELECT id FROM app_user ORDER BY id LIMIT 1)"
            " WHERE name = :space AND active"
        ),
        request.model_dump(),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/recuperacion/{code}/vencer", status_code=status.HTTP_204_NO_CONTENT)
def expire(code: str, conn: DbConnection) -> Response:
    conn.execute(
        text(
            "UPDATE recovery_link SET created_at = clock_timestamp() - interval '1 hour',"
            " expires_at = clock_timestamp() - interval '30 minutes' WHERE code_hash = :h"
        ),
        {"h": hash_of(code)},
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class Sweep(_Wire):
    # Only the bookings of this account; without an email, those of all.
    email: str | None = Field(None, alias="correo")
    # The time the sweep is run at; without it, now.
    now: datetime | None = Field(None, alias="ahora")


class Registered(_Wire):
    registered: int = Field(alias="registrados")


@router.post("/recordatorios", response_model_by_alias=True)
def sweep(
    request: Sweep,
    conn: DbConnection,
    notifications: Annotated[NotificationsSql, Depends(notifications_repository)],
) -> Registered:
    """The reminder sweep running at the time [now], as if the server clock were that."""
    user = None
    if request.email is not None:
        user = conn.execute(
            text("SELECT id FROM app_user WHERE active AND lower(email) = lower(:c)"),
            {"c": request.email},
        ).scalar_one_or_none()
        conn.rollback()
        if user is None:
            return Registered(registered=0)
    now = request.now or datetime.now().astimezone()
    return Registered(registered=send_reminders(notifications, push_channel(), now, user))


class Device(_Wire):
    permission: bool = Field(alias="permiso")


class Devices(_Wire):
    devices: list[Device] = Field(alias="dispositivos")


@router.get("/dispositivos", response_model_by_alias=True)
def devices(conn: DbConnection, email: Annotated[str, Query(alias="correo")]) -> Devices:
    """The phones the account [email] has registered today, with their permission."""
    rows = conn.execute(
        text(
            "SELECT d.permission_granted FROM device d JOIN app_user u ON u.id = d.user_id"
            " WHERE d.active AND u.active AND lower(u.email) = lower(:c) ORDER BY d.id"
        ),
        {"c": email.strip()},
    ).all()
    conn.rollback()
    return Devices(devices=[Device(permission=r.permission_granted) for r in rows])
