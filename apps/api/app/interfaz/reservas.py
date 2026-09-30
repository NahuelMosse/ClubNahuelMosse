import re
from datetime import date, datetime, time
from typing import Annotated
from zoneinfo import ZoneInfo

from fastapi import APIRouter, BackgroundTasks, Depends, Path, Query, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.errores import (
    Cambiado,
    DatosInvalidos,
    HorarioOcupado,
    NoDisponible,
    NoEncontrada,
    Prohibido,
)
from app.aplicacion.notificaciones import CanalPush
from app.aplicacion.reservas import (
    Cuando,
    cancelar_reserva,
    mis_reservas,
    modificar_reserva,
    reservar,
)
from app.dominio.reservas import Estado, Reserva
from app.dominio.usuarios import Perfil
from app.infraestructura.db import conexion
from app.infraestructura.push import canal_push
from app.infraestructura.reservas import ReservasSql
from app.interfaz.barrido import despachar_de
from app.interfaz.sesion import SinSesion, usuario_actual

router = APIRouter(tags=["reservas"])

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
OCUPADO = "Ese horario se ocupó"
NO_DISPONIBLE = "Esta cancha ya no está disponible"
_HORA = re.compile(r"\d{2}:\d{2}")


class ReservaVista(BaseModel):
    id: int
    espacio_id: int
    sede_id: int
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
    cancelable: bool


class ListaDeReservas(BaseModel):
    reservas: list[ReservaVista]


def _vista(r: Reserva) -> ReservaVista:
    return ReservaVista(
        id=r.id,
        espacio_id=r.espacio_id,
        sede_id=r.sede_id,
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
        cancelable=r.cancelable,
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


CAMBIO = "Esto cambió mientras tanto"


@router.post(
    "/reservas/{reserva_id}/cancelar",
    response_model=ReservaVista,
    responses={
        401: {"model": SinSesion},
        404: {"description": "No hay una reserva de quien pide con ese número"},
        409: {"model": Errores, "description": "La reserva ya no está activa o ya empezó"},
    },
    summary="Cancelar una reserva propia",
    description=(
        "Hasta el inicio del turno. El horario vuelve a quedar libre, la reserva pasa al "
        "historial como cancelada y la confirmación queda en el centro de notificaciones y sale "
        "por push. Cancelar una que ya canceló la misma persona responde igual."
    ),
)
def cancelar(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    reserva_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
    despues: BackgroundTasks,
    canal: Annotated[CanalPush, Depends(canal_push)],
) -> ReservaVista | Response:
    try:
        reserva = cancelar_reserva(ReservasSql(conn), perfil, reserva_id)
    except NoEncontrada:
        return Response(status_code=status.HTTP_404_NOT_FOUND)
    except Cambiado:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT, content={"errores": {"reserva": CAMBIO}}
        )
    despues.add_task(despachar_de, perfil.id, canal)
    return _vista(reserva)


class PedidoDeCambio(BaseModel):
    espacio_id: int
    fecha: date
    desde: str


@router.post(
    "/reservas/{reserva_id}/modificar",
    response_model=ReservaVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Un administrador no reserva"},
        404: {"description": "No hay una reserva de quien pide con ese número"},
        409: {
            "model": Errores,
            "description": "El horario nuevo se ocupó (`horario`) o la reserva ya no se puede "
            "modificar (`reserva`)",
        },
        422: {"model": Errores},
    },
    summary="Modificar una reserva propia",
    description=(
        "Otra cancha del mismo tipo en la misma sede, otro día u otro horario, con la misma "
        "duración. El horario anterior se libera sólo si el nuevo queda tomado; la reserva "
        "conserva su número y el total pasa al precio de ahora del espacio. Repetir un cambio "
        "que ya se hizo responde igual."
    ),
)
def modificar(
    pedido: PedidoDeCambio,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    reserva_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
) -> ReservaVista | Response:
    try:
        reserva = modificar_reserva(
            ReservasSql(conn),
            perfil,
            reserva_id,
            pedido.espacio_id,
            pedido.fecha,
            _leer_hora(pedido.desde),
            datetime.now(ZONA),
        )
    except Prohibido:
        return Response(status_code=status.HTTP_403_FORBIDDEN)
    except NoEncontrada:
        return Response(status_code=status.HTTP_404_NOT_FOUND)
    except DatosInvalidos as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
        )
    except NoDisponible:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            content={"errores": {"espacio_id": NO_DISPONIBLE}},
        )
    except Cambiado:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT, content={"errores": {"reserva": CAMBIO}}
        )
    except HorarioOcupado:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT, content={"errores": {"horario": OCUPADO}}
        )
    return _vista(reserva)
