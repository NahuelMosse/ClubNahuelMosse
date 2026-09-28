from datetime import date, datetime
from typing import Annotated
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Path, Query, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.errores import DatosInvalidos, NoDisponible
from app.aplicacion.horarios import horarios_disponibles
from app.dominio.horarios import MAX_HORAS, MIN_HORAS
from app.dominio.usuarios import Perfil
from app.infraestructura.db import conexion
from app.infraestructura.horarios import HorariosSql
from app.interfaz.sesion import SinSesion, usuario_actual

router = APIRouter(tags=["horarios"])

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
NO_DISPONIBLE = "Esta cancha ya no está disponible"


class FranjaVista(BaseModel):
    inicio: str
    fin: str
    disponible: bool


class GrillaVista(BaseModel):
    fecha: date
    hoy: date
    abre: bool
    franjas: list[FranjaVista]
    no_disponibles: int


class Errores(BaseModel):
    errores: dict[str, str]


def _hora(momento: datetime) -> str:
    return momento.astimezone(ZONA).strftime("%H:%M")


@router.get(
    "/espacios/{espacio_id}/horarios",
    response_model=GrillaVista,
    responses={
        401: {"model": SinSesion},
        404: {"model": Errores, "description": "El espacio o su sede ya no están activos"},
        422: {"model": Errores},
    },
    summary="Las franjas de un espacio para un día y una duración",
    description=(
        "Todas las horas de inicio en punto que entran en el horario de la sede con esa "
        "duración y todavía no empezaron, en la hora del club; `disponible` dice si no pisan "
        "una reserva activa. Sin `fecha`, la de hoy. `abre` es falso si la sede no abre ese día."
    ),
)
def ver_horarios(
    _: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    espacio_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
    fecha: Annotated[date | None, Query()] = None,
    horas: Annotated[int, Query(ge=MIN_HORAS, le=MAX_HORAS)] = MIN_HORAS,
) -> GrillaVista | JSONResponse:
    try:
        g = horarios_disponibles(HorariosSql(conn), espacio_id, fecha, horas, datetime.now(ZONA))
    except DatosInvalidos as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
        )
    except NoDisponible:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"errores": {"espacio_id": NO_DISPONIBLE}},
        )
    return GrillaVista(
        fecha=g.fecha,
        hoy=g.hoy,
        abre=g.abre,
        franjas=[
            FranjaVista(inicio=_hora(f.inicio), fin=_hora(f.fin), disponible=f.disponible)
            for f in g.franjas
        ],
        no_disponibles=g.no_disponibles,
    )
