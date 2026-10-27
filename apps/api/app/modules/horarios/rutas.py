# kit-shape: las rutas de horarios y los modelos de sus pedidos y respuestas se leen juntos
from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.espacios import ListaDeEspacios, vista_de_espacio
from app.modules.horarios.casos_de_uso import horarios_disponibles
from app.modules.horarios.disponibilidad import canchas_disponibles
from app.modules.horarios.reglas import MAX_HORAS, MIN_HORAS
from app.modules.horarios.repositorio import HorariosSql, repositorio_horarios
from app.modules.sesion import Perfil, SinSesion, usuario_actual
from app.shared.input_validation import Identifier, parse_time
from app.shared.errors import InvalidData, Unavailable
from app.shared.club_timezone import CLUB_TIMEZONE as ZONA

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
    espacio_id: Annotated[Identifier, Path()],
    fecha: Annotated[date | None, Query()] = None,
    horas: Annotated[int, Query(ge=MIN_HORAS, le=MAX_HORAS)] = MIN_HORAS,
    reserva_id: Annotated[Identifier | None, Query()] = None,
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
    except Unavailable:
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
    sede_id: Annotated[Identifier, Query()],
    deporte: Annotated[str, Query(min_length=1)],
    fecha: Annotated[date, Query()],
    desde: Annotated[str, Query()],
    hasta: Annotated[str, Query()],
    tipo: Annotated[str | None, Query(min_length=1)] = None,
) -> ListaDeEspacios:
    inicio, fin = parse_time(desde), parse_time(hasta)
    errores = {
        campo: "Elegí una hora en punto"
        for campo, hora in (("desde", inicio), ("hasta", fin))
        if hora is None
    }
    if inicio is None or fin is None:
        raise InvalidData(errores)
    try:
        libres = canchas_disponibles(
            horarios, sede_id, deporte, tipo, fecha, inicio, fin, datetime.now(ZONA)
        )
    except Unavailable:
        raise InvalidData({"sede_id": SEDE_NO_DISPONIBLE}) from None
    return ListaDeEspacios(espacios=[vista_de_espacio(e) for e in libres])
