import re
from datetime import date, datetime, time
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.aplicacion.disponibilidad import canchas_disponibles
from app.aplicacion.errores import DatosInvalidos, NoDisponible
from app.aplicacion.horarios import horarios_disponibles
from app.dependencias import HorariosSql, repositorio_horarios
from app.dominio.horarios import MAX_HORAS, MIN_HORAS
from app.dominio.usuarios import Perfil
from app.dominio.zona import ZONA_CLUB as ZONA
from app.interfaz.espacios import ListaDeEspacios, vista_de_espacio
from app.interfaz.respuestas import datos_invalidos
from app.interfaz.sesion import SinSesion, usuario_actual

router = APIRouter(tags=["horarios"])

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
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    horarios: Annotated[HorariosSql, Depends(repositorio_horarios)],
    espacio_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
    fecha: Annotated[date | None, Query()] = None,
    horas: Annotated[int, Query(ge=MIN_HORAS, le=MAX_HORAS)] = MIN_HORAS,
    reserva_id: Annotated[int | None, Query(ge=1, le=2**63 - 1)] = None,
) -> GrillaVista | JSONResponse:
    try:
        g = horarios_disponibles(
            horarios,
            espacio_id,
            fecha,
            horas,
            datetime.now(ZONA),
            None if reserva_id is None else (reserva_id, perfil.id),
        )
    except DatosInvalidos as e:
        return datos_invalidos(e.errores)
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


SEDE_NO_DISPONIBLE = "La sede ya no está disponible"
_HORA = re.compile(r"\d{2}:\d{2}")


def _leer_hora(valor: str) -> time | None:
    """`HH:MM` y nada más."""
    if not _HORA.fullmatch(valor):
        return None
    try:
        return time.fromisoformat(valor)
    except ValueError:
        return None


@router.get(
    "/espacios/disponibles",
    response_model=ListaDeEspacios,
    responses={401: {"model": SinSesion}, 422: {"model": Errores}},
    summary="Las canchas de una sede libres en todo un rango",
    description=(
        "Los espacios activos de la sede, del deporte y del tipo si viene, sin reservas activas "
        "que pisen [desde, hasta) el día `fecha`, en la hora del club. `hasta` a las 00:00 es la "
        "medianoche. El rango tiene que ser futuro, de horas completas, de 1 a 4 horas, de los "
        "próximos 7 días y dentro del horario de la sede: si no, 422 con el error de cada campo."
    ),
)
def ver_disponibles(
    _: Annotated[Perfil, Depends(usuario_actual)],
    horarios: Annotated[HorariosSql, Depends(repositorio_horarios)],
    sede_id: Annotated[int, Query(ge=1, le=2**63 - 1)],
    deporte: Annotated[str, Query(min_length=1, max_length=40)],
    fecha: Annotated[date, Query()],
    desde: Annotated[str, Query(max_length=5)],
    hasta: Annotated[str, Query(max_length=5)],
    tipo: Annotated[str | None, Query(min_length=1, max_length=40)] = None,
) -> ListaDeEspacios | JSONResponse:
    inicio, fin = _leer_hora(desde), _leer_hora(hasta)
    errores = {
        campo: "Elegí una hora en punto"
        for campo, hora in (("desde", inicio), ("hasta", fin))
        if hora is None
    }
    if inicio is None or fin is None:
        return datos_invalidos(errores)
    try:
        libres = canchas_disponibles(
            horarios, sede_id, deporte, tipo, fecha, inicio, fin, datetime.now(ZONA)
        )
    except DatosInvalidos as e:
        return datos_invalidos(e.errores)
    except NoDisponible:
        return datos_invalidos({"sede_id": SEDE_NO_DISPONIBLE})
    return ListaDeEspacios(espacios=[vista_de_espacio(e) for e in libres])
