import re
from datetime import date, datetime, time
from typing import Annotated
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Query, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.errores import DatosInvalidos, HorarioOcupado, NoDisponible, Prohibido
from app.aplicacion.reservas import Cuando, mis_reservas, reservar
from app.dominio.reservas import Estado, Reserva
from app.dominio.usuarios import Perfil
from app.infraestructura.db import conexion
from app.infraestructura.reservas import ReservasSql
from app.interfaz.sesion import SinSesion, usuario_actual

router = APIRouter(tags=["reservas"])

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
OCUPADO = "Ese horario se ocupó"
NO_DISPONIBLE = "Esta cancha ya no está disponible"
_HORA = re.compile(r"\d{2}:\d{2}")


class ReservaVista(BaseModel):
    id: int
    espacio_id: int
    espacio: str
    deporte: str
    tipo: str
    sede: str
    direccion: str
    inicio: datetime
    fin: datetime
    precio_por_hora: int
    total: int
    estado: Estado
    motivo: str | None


class ListaDeReservas(BaseModel):
    reservas: list[ReservaVista]


def _vista(r: Reserva) -> ReservaVista:
    return ReservaVista(
        id=r.id,
        espacio_id=r.espacio_id,
        espacio=r.espacio,
        deporte=r.deporte,
        tipo=r.tipo,
        sede=r.sede,
        direccion=r.direccion,
        inicio=r.inicio,
        fin=r.fin,
        precio_por_hora=r.precio_por_hora,
        total=r.total,
        estado=r.estado,
        motivo=r.motivo,
    )


@router.get(
    "/reservas",
    response_model=ListaDeReservas,
    responses={401: {"model": SinSesion}},
    summary="Las reservas de quien consulta",
    description=(
        "`proximas`: las activas que no terminaron, de la más cercana a la más lejana. "
        "`historial`: las completadas, canceladas y anuladas, de la más reciente a la más "
        "vieja. El total es el que se guardó al reservar."
    ),
)
def listar_reservas(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    cuando: Annotated[Cuando, Query()] = "proximas",
) -> ListaDeReservas:
    return ListaDeReservas(
        reservas=[_vista(r) for r in mis_reservas(ReservasSql(conn), perfil, cuando)]
    )


class PedidoDeReserva(BaseModel):
    espacio_id: int
    fecha: date
    desde: str
    horas: int


class Errores(BaseModel):
    errores: dict[str, str]


def _leer_hora(valor: str) -> time | None:
    """`HH:MM` y nada más."""
    if not _HORA.fullmatch(valor):
        return None
    try:
        return time.fromisoformat(valor)
    except ValueError:
        return None


@router.post(
    "/reservas",
    status_code=status.HTTP_201_CREATED,
    response_model=ReservaVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "El administrador no reserva"},
        409: {"model": Errores, "description": "Otra reserva activa pisa ese horario"},
        422: {"model": Errores},
    },
    summary="Reservar un espacio",
    description=(
        "`horas` horas desde `desde` (`HH:MM`, en la hora del club) el día `fecha`. Horas "
        "completas, de 1 a 4, futuras, de los próximos 7 días y dentro del horario de la sede; "
        "si la misma persona repite el mismo pedido dentro de los cinco minutos, devuelve la "
        "reserva que ya hizo."
    ),
)
def hacer_reserva(
    pedido: PedidoDeReserva,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> ReservaVista | Response:
    try:
        reserva = reservar(
            ReservasSql(conn),
            perfil,
            pedido.espacio_id,
            pedido.fecha,
            _leer_hora(pedido.desde),
            pedido.horas,
            datetime.now(ZONA),
        )
    except Prohibido:
        return Response(status_code=status.HTTP_403_FORBIDDEN)
    except DatosInvalidos as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
        )
    except NoDisponible:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            content={"errores": {"espacio_id": NO_DISPONIBLE}},
        )
    except HorarioOcupado:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT, content={"errores": {"horario": OCUPADO}}
        )
    return _vista(reserva)
