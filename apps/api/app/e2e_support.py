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
from app.modules.recuperacion import hash_de
from app.shared.club_timezone import CLUB_TIMEZONE_NAME
from app.shared.db import DbConnection
from app.shared.errors import NotFound

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
        text("SELECT asunto, cuerpo FROM correo_saliente WHERE para = :p ORDER BY id"),
        {"p": recipient.strip().lower()},
    ).all()
    return Outbox(emails=[Email(subject=r.asunto, body=r.cuerpo) for r in rows])


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
    inserted = conn.execute(
        text(
            "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total,"
            " estado, motivo, cancelada_en)"
            " SELECT u.id, e.id, x.inicio,"
            "        x.inicio + make_interval(hours => :horas),"
            "        e.precio_por_hora, e.precio_por_hora * :horas, :estado, :motivo,"
            "        CASE WHEN CAST(:estado AS text) <> 'activa' THEN now() END"
            " FROM espacio e,"
            "      LATERAL (SELECT (CAST(:fecha AS date) + make_interval(hours => :hora))"
            f"               AT TIME ZONE '{CLUB_TIMEZONE_NAME}' AS inicio) x,"
            "      (SELECT id FROM usuario WHERE CAST(:correo AS text) IS NULL"
            "         AND id = (SELECT id FROM usuario ORDER BY id LIMIT 1)"
            "       UNION ALL"
            "       SELECT id FROM usuario WHERE activo"
            "         AND lower(correo) = lower(CAST(:correo AS text))) u"
            " WHERE e.nombre = :espacio"
        ),
        occupation.model_dump(by_alias=True),
    ).rowcount
    conn.commit()
    if inserted != 1:
        raise NotFound()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/reservas/vaciar", status_code=status.HTTP_204_NO_CONTENT)
def clear_bookings(conn: DbConnection) -> Response:
    """The system is left with no bookings, nor the notices that mention them: the run
    database is a single one and the global-history scenarios start from zero."""
    conn.execute(text("TRUNCATE notificacion_reserva, notificacion, reserva"))
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
            "UPDATE reserva r SET fin = x.ahora + (r.fin - r.inicio), inicio = x.ahora"
            f" FROM (SELECT date_trunc('hour', now(), '{CLUB_TIMEZONE_NAME}')"
            "                  AS ahora) x"
            " WHERE r.id = (SELECT r2.id FROM reserva r2 JOIN espacio e ON e.id = r2.espacio_id"
            "               WHERE e.nombre = :espacio AND r2.estado = 'activa'"
            "               ORDER BY r2.inicio LIMIT 1)"
        ),
        request.model_dump(by_alias=True),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/reservas/anular", status_code=status.HTTP_204_NO_CONTENT)
def cancel(request: SpaceName, conn: DbConnection) -> Response:
    """The club cancels the active bookings of [space], as an administrator would."""
    conn.execute(
        text(
            "UPDATE reserva r SET estado = 'anulada', motivo = 'mantenimiento de la cancha',"
            " cancelada_en = now(), cancelada_por = (SELECT id FROM usuario ORDER BY id LIMIT 1)"
            " FROM espacio e WHERE e.id = r.espacio_id AND e.nombre = :espacio"
            " AND r.estado = 'activa'"
        ),
        request.model_dump(by_alias=True),
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
            "UPDATE sede SET activa = false, dado_de_baja_en = now(),"
            " dado_de_baja_por = (SELECT id FROM usuario ORDER BY id LIMIT 1)"
            " WHERE nombre = :nombre AND activa"
        ),
        request.model_dump(by_alias=True),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/espacios/baja", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_space(request: SpaceName, conn: DbConnection) -> Response:
    """The space [space] stops being active, as if another administrator deactivated it."""
    conn.execute(
        text(
            "UPDATE espacio SET activo = false, dado_de_baja_en = now(),"
            " dado_de_baja_por = (SELECT id FROM usuario ORDER BY id LIMIT 1)"
            " WHERE nombre = :espacio AND activo"
        ),
        request.model_dump(by_alias=True),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/recuperacion/{code}/vencer", status_code=status.HTTP_204_NO_CONTENT)
def expire(code: str, conn: DbConnection) -> Response:
    conn.execute(
        text(
            "UPDATE enlace_recuperacion SET creado_en = clock_timestamp() - interval '1 hour',"
            " vence_en = clock_timestamp() - interval '30 minutes' WHERE codigo_hash = :h"
        ),
        {"h": hash_de(code)},
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
            text("SELECT id FROM usuario WHERE activo AND lower(correo) = lower(:c)"),
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
            "SELECT d.permiso FROM dispositivo d JOIN usuario u ON u.id = d.usuario_id"
            " WHERE d.activo AND u.activo AND lower(u.correo) = lower(:c) ORDER BY d.id"
        ),
        {"c": email.strip()},
    ).all()
    conn.rollback()
    return Devices(devices=[Device(permission=r.permiso) for r in rows])
