import re
from datetime import date, datetime, time
from typing import Annotated
from zoneinfo import ZoneInfo

from fastapi import APIRouter, BackgroundTasks, Depends, Path, Query, Response, status
from pydantic import AwareDatetime, BaseModel
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
    anular_reserva,
    cancelar_reserva,
    detalle_admin,
    historial_global,
    mis_reservas,
    modificar_reserva,
    reservar,
)
from app.dominio.reservas import Estado, FiltroEstado, FiltrosHistorial, Reserva, ReservaHistorial
from app.dominio.usuarios import Perfil
from app.infraestructura.db import conexion
from app.infraestructura.push import canal_push
from app.infraestructura.reservas import ReservasSql
from app.interfaz.barrido import despachar_de
from app.interfaz.entradas import Busqueda, Identificador, Parrafo, Texto40
from app.interfaz.marcador import leer, siguiente
from app.interfaz.respuestas import conflicto, datos_invalidos, no_encontrado, sin_permiso
from app.interfaz.sesion import SinSesion, usuario_actual

router = APIRouter(tags=["reservas"])

# Con 20 por página, diez mil páginas son doscientas mil reservas.
PAGINA_MAXIMA = 10_000

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
OCUPADO = "Ese horario se ocupó"
NO_DISPONIBLE = "Esta cancha ya no está disponible"
_HORA = re.compile(r"\d{2}:\d{2}")


class _CamposDeReserva(BaseModel):
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


class ReservaVista(_CamposDeReserva):
    cancelable: bool


class Errores(BaseModel):
    errores: dict[str, str]


class ListaDeReservas(BaseModel):
    reservas: list[ReservaVista]
    # El `despues` de la tanda que sigue; `null` si esta es la última.
    siguiente: str | None


def _vista(r: Reserva) -> ReservaVista:
    return ReservaVista.model_validate(r, from_attributes=True)


@router.get(
    "/reservas",
    response_model=ListaDeReservas,
    responses={401: {"model": SinSesion}, 422: {"model": Errores}},
    summary="Las reservas de quien consulta",
    description=(
        "`proximas`: las activas que no terminaron, de la más cercana a la más lejana. "
        "`historial`: las completadas, canceladas y anuladas, de la más reciente a la más "
        "vieja. El total es el que se guardó al reservar. Trae 20 por tanda: si hay más, "
        "`siguiente` es el valor de `despues` que pide la tanda que sigue; sin `despues` "
        "trae las primeras 20. Un `despues` que no sale de un `siguiente` es un 422."
    ),
)
def listar_reservas(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    cuando: Annotated[Cuando, Query()] = "proximas",
    despues: Annotated[str | None, Query()] = None,
) -> ListaDeReservas | Response:
    try:
        marcador = None if despues is None else leer(despues)
    except DatosInvalidos as e:
        return datos_invalidos(e.errores)
    tanda = mis_reservas(ReservasSql(conn), perfil, cuando, marcador)
    return ListaDeReservas(
        reservas=[_vista(r) for r in tanda.reservas],
        siguiente=siguiente(tanda.reservas, tanda.hay_mas),
    )


class PedidoDeReserva(BaseModel):
    espacio_id: Identificador
    fecha: date
    desde: Texto40
    # Sin cota acá: el caso de uso rechaza una duración fuera de rango antes de calcular nada.
    horas: int


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
        return sin_permiso()
    except DatosInvalidos as e:
        return datos_invalidos(e.errores)
    except NoDisponible:
        return datos_invalidos({"espacio_id": NO_DISPONIBLE})
    except HorarioOcupado:
        return conflicto({"horario": OCUPADO})
    return _vista(reserva)


CAMBIO = "Esto cambió mientras tanto"


def _rechazo(e: Prohibido | NoEncontrada | DatosInvalidos) -> Response:
    if isinstance(e, Prohibido):
        return sin_permiso()
    if isinstance(e, NoEncontrada):
        return no_encontrado()
    return datos_invalidos(e.errores)


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
        return no_encontrado()
    except Cambiado:
        return conflicto({"reserva": CAMBIO})
    despues.add_task(despachar_de, perfil.id, canal)
    return _vista(reserva)


class PedidoDeCambio(BaseModel):
    espacio_id: Identificador
    fecha: date
    desde: Texto40


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
    except (Prohibido, NoEncontrada, DatosInvalidos) as e:
        return _rechazo(e)
    except NoDisponible:
        return datos_invalidos({"espacio_id": NO_DISPONIBLE})
    except Cambiado:
        return conflicto({"reserva": CAMBIO})
    except HorarioOcupado:
        return conflicto({"horario": OCUPADO})
    return _vista(reserva)


class ReservaHistorialVista(_CamposDeReserva):
    usuario_id: int
    usuario: str
    creado_en: datetime
    cancelada_en: datetime | None
    cancelada_por_nombre: str | None
    espacio_de_baja: bool
    anulable: bool
    aviso_envio: str | None
    aviso_en: datetime | None


class ContadoresVista(BaseModel):
    todas: int
    activas: int
    completadas: int
    anuladas: int


class HistorialVista(BaseModel):
    reservas: list[ReservaHistorialVista]
    total: int
    pagina: int
    por_pagina: int
    contadores: ContadoresVista
    # El `despues` de la página que sigue; `null` si esta es la última.
    siguiente: str | None


def _vista_admin(r: ReservaHistorial) -> ReservaHistorialVista:
    return ReservaHistorialVista.model_validate(r, from_attributes=True)


@router.get(
    "/reservas/todas",
    response_model=HistorialVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador consulta el historial global"},
        422: {"model": Errores},
    },
    summary="El historial global de reservas (CU-14)",
    description=(
        "Todos los usuarios, todas las sedes. Filtra por estado (`activa`, `completada` o"
        " `anulada`; sin filtro trae también las canceladas por su usuario), sede, deporte,"
        " rango de fechas y texto (usuario, sede o espacio); pagina de a 20, de la más"
        " reciente a la más antigua: `siguiente` es el valor de `despues` que pide la página"
        " que sigue, y un `despues` que no sale de un `siguiente` es un 422. `pagina` sigue"
        " valiendo para las apps ya instaladas; con `despues`, `pagina` no cuenta. No"
        " modifica nada."
    ),
)
def listar_todas(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    estado: Annotated[FiltroEstado | None, Query()] = None,
    sede_id: Annotated[Identificador | None, Query()] = None,
    deporte: Annotated[Texto40 | None, Query()] = None,
    desde: Annotated[date | None, Query()] = None,
    hasta: Annotated[date | None, Query()] = None,
    q: Annotated[Busqueda | None, Query()] = None,
    pagina: Annotated[int, Query(ge=1, le=PAGINA_MAXIMA)] = 1,
    despues: Annotated[str | None, Query()] = None,
) -> HistorialVista | Response:
    try:
        historial = historial_global(
            ReservasSql(conn),
            perfil,
            FiltrosHistorial(
                estado=estado,
                sede_id=sede_id,
                deporte=deporte,
                desde=desde,
                hasta=hasta,
                q=q,
                pagina=pagina,
                despues=None if despues is None else leer(despues),
            ),
        )
    except Prohibido:
        return sin_permiso()
    except DatosInvalidos as e:
        return datos_invalidos(e.errores)
    return HistorialVista(
        reservas=[_vista_admin(r) for r in historial.reservas],
        total=historial.total,
        pagina=historial.pagina,
        por_pagina=historial.por_pagina,
        contadores=ContadoresVista(
            todas=historial.contadores.todas,
            activas=historial.contadores.activas,
            completadas=historial.contadores.completadas,
            anuladas=historial.contadores.anuladas,
        ),
        siguiente=siguiente(historial.reservas, historial.hay_mas),
    )


@router.get(
    "/reservas/todas/{reserva_id}",
    response_model=ReservaHistorialVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador consulta el detalle de cualquier reserva"},
        404: {"description": "No hay una reserva con ese número"},
    },
    summary="El detalle de cualquier reserva (CU-14)",
)
def detalle(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    reserva_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
) -> ReservaHistorialVista | Response:
    try:
        return _vista_admin(detalle_admin(ReservasSql(conn), perfil, reserva_id))
    except Prohibido:
        return sin_permiso()
    except NoEncontrada:
        return no_encontrado()


class PedidoDeAnulacion(BaseModel):
    motivo: Parrafo
    espacio_id: Identificador
    inicio: AwareDatetime


@router.post(
    "/reservas/{reserva_id}/anular",
    response_model=ReservaHistorialVista,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador anula una reserva"},
        404: {"description": "No hay una reserva con ese número"},
        409: {"model": Errores, "description": "La reserva ya no está activa, ya empezó o cambió"},
        422: {"model": Errores},
    },
    summary="Anular una reserva (CU-15)",
    description=(
        "Hasta el inicio del turno. `espacio_id` e `inicio` son la cancha y el horario que el "
        "administrador vio: si la reserva ya no está ahí, responde 409. El horario vuelve a "
        "quedar libre y la reserva guarda el motivo, quién la anuló y cuándo. Repetir una "
        "anulación ya hecha por el mismo administrador con el mismo motivo responde igual. "
        "Le avisa a quien reservó, con el motivo, sin repetir el aviso."
    ),
)
def anular(
    pedido: PedidoDeAnulacion,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    reserva_id: Annotated[int, Path(ge=1, le=2**63 - 1)],
    despues: BackgroundTasks,
    canal: Annotated[CanalPush, Depends(canal_push)],
) -> ReservaHistorialVista | Response:
    try:
        reserva = anular_reserva(
            ReservasSql(conn),
            perfil,
            reserva_id,
            pedido.motivo,
            pedido.espacio_id,
            pedido.inicio,
        )
    except (Prohibido, NoEncontrada, DatosInvalidos) as e:
        return _rechazo(e)
    except Cambiado:
        return conflicto({"reserva": CAMBIO})
    # El aviso a quien reservó sale recién con la anulación confirmada y la respuesta enviada.
    despues.add_task(despachar_de, reserva.usuario_id, canal)
    return _vista_admin(reserva)
