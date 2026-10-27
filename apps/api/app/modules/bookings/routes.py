# kit-shape: the booking routes and the models of their requests and responses are read together
from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, Depends, Path, Query, Response, status
from pydantic import AwareDatetime, BaseModel

from app.modules.bookings.repository import BookingsSql, bookings_repository
from app.modules.bookings.rules import (
    Booking,
    BookingHistoryEntry,
    HistoryFilters,
    Status,
    StatusFilter,
)
from app.modules.bookings.use_cases import (
    When,
    admin_detail,
    book,
    cancel_booking,
    global_history,
    modify_booking,
    my_bookings,
    void_booking,
)
from app.modules.notificaciones import CanalPush, canal_push, despachar_de
from app.modules.sesion import Perfil, SinSesion, usuario_actual
from app.shared.club_timezone import CLUB_TIMEZONE
from app.shared.errors import ConcurrentChange, InvalidData, SlotTaken, Unavailable
from app.shared.input_validation import Identifier, parse_time
from app.shared.responses import conflict

router = APIRouter(tags=["reservas"])

# With 20 per page, ten thousand pages are two hundred thousand bookings.
MAX_PAGE = 10_000

SLOT_TAKEN_MESSAGE = "Ese horario se ocupó"
UNAVAILABLE_MESSAGE = "Esta cancha ya no está disponible"


class _BookingFields(BaseModel):
    id: UUID
    espacio_id: UUID
    sede_id: UUID
    espacio: str
    deporte: str
    tipo: str
    sede: str
    direccion: str
    inicio: datetime
    fin: datetime
    precio_por_hora: int
    total: int
    estado: Status
    motivo: str | None


class BookingView(_BookingFields):
    cancelable: bool


class Errors(BaseModel):
    errores: dict[str, str]


class BookingList(BaseModel):
    reservas: list[BookingView]


def _view(b: Booking) -> BookingView:
    return BookingView(
        id=b.id,
        espacio_id=b.space_id,
        sede_id=b.venue_id,
        espacio=b.space,
        deporte=b.sport,
        tipo=b.kind,
        sede=b.venue,
        direccion=b.address,
        inicio=b.starts_at,
        fin=b.ends_at,
        precio_por_hora=b.price_per_hour,
        total=b.total,
        estado=b.status,
        motivo=b.reason,
        cancelable=b.cancelable,
    )


@router.get(
    "/reservas",
    operation_id="listar_reservas_reservas_get",
    response_model=BookingList,
    responses={401: {"model": SinSesion}, 422: {"model": Errors}},
    summary="Las reservas de quien consulta",
    description=(
        "`proximas`: las activas que no terminaron, de la más cercana a la más lejana. "
        "`historial`: las completadas, canceladas y anuladas, de la más reciente a la más "
        "vieja. El total es el que se guardó al reservar."
    ),
)
def list_bookings(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    bookings: Annotated[BookingsSql, Depends(bookings_repository)],
    cuando: Annotated[When, Query()] = "proximas",
) -> BookingList:
    return BookingList(reservas=[_view(b) for b in my_bookings(bookings, perfil, cuando)])


class BookingRequest(BaseModel):
    espacio_id: Identifier
    fecha: date
    desde: str
    # No bound here: the use case rejects an out-of-range duration before computing anything.
    horas: int


@router.post(
    "/reservas",
    operation_id="hacer_reserva_reservas_post",
    status_code=status.HTTP_201_CREATED,
    response_model=BookingView,
    responses={
        401: {"model": SinSesion},
        403: {"description": "El administrador no reserva"},
        409: {"model": Errors, "description": "Otra reserva activa pisa ese horario"},
        422: {"model": Errors},
    },
    summary="Reservar un espacio",
    description=(
        "`horas` horas desde `desde` (`HH:MM`, en la hora del club) el día `fecha`. Horas "
        "completas, de 1 a 4, futuras, de los próximos 7 días y dentro del horario de la sede; "
        "si la misma persona repite el mismo pedido dentro de los cinco minutos, devuelve la "
        "reserva que ya hizo."
    ),
)
def create_booking(
    payload: BookingRequest,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    bookings: Annotated[BookingsSql, Depends(bookings_repository)],
) -> BookingView | Response:
    try:
        booking = book(
            bookings,
            perfil,
            payload.espacio_id,
            payload.fecha,
            parse_time(payload.desde),
            payload.horas,
            datetime.now(CLUB_TIMEZONE),
        )
    except Unavailable:
        raise InvalidData({"espacio_id": UNAVAILABLE_MESSAGE}) from None
    except SlotTaken:
        return conflict({"horario": SLOT_TAKEN_MESSAGE})
    return _view(booking)


CHANGED_MESSAGE = "Esto cambió mientras tanto"


@router.post(
    "/reservas/{reserva_id}/cancelar",
    operation_id="cancelar_reservas__reserva_id__cancelar_post",
    response_model=BookingView,
    responses={
        401: {"model": SinSesion},
        404: {"description": "No hay una reserva de quien pide con ese número"},
        409: {"model": Errors, "description": "La reserva ya no está activa o ya empezó"},
    },
    summary="Cancelar una reserva propia",
    description=(
        "Hasta el inicio del turno. El horario vuelve a quedar libre, la reserva pasa al "
        "historial como cancelada y la confirmación queda en el centro de notificaciones y sale "
        "por push. Cancelar una que ya canceló la misma persona responde igual."
    ),
)
def cancel(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    bookings: Annotated[BookingsSql, Depends(bookings_repository)],
    reserva_id: Annotated[Identifier, Path()],
    background: BackgroundTasks,
    channel: Annotated[CanalPush, Depends(canal_push)],
) -> BookingView | Response:
    try:
        booking = cancel_booking(bookings, perfil, reserva_id)
    except ConcurrentChange:
        return conflict({"reserva": CHANGED_MESSAGE})
    background.add_task(despachar_de, perfil.id, channel)
    return _view(booking)


class BookingChangeRequest(BaseModel):
    espacio_id: Identifier
    fecha: date
    desde: str


@router.post(
    "/reservas/{reserva_id}/modificar",
    operation_id="modificar_reservas__reserva_id__modificar_post",
    response_model=BookingView,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Un administrador no reserva"},
        404: {"description": "No hay una reserva de quien pide con ese número"},
        409: {
            "model": Errors,
            "description": "El horario nuevo se ocupó (`horario`) o la reserva ya no se puede "
            "modificar (`reserva`)",
        },
        422: {"model": Errors},
    },
    summary="Modificar una reserva propia",
    description=(
        "Otra cancha del mismo tipo en la misma sede, otro día u otro horario, con la misma "
        "duración. El horario anterior se libera sólo si el nuevo queda tomado; la reserva "
        "conserva su número y el total pasa al precio de ahora del espacio. Repetir un cambio "
        "que ya se hizo responde igual."
    ),
)
def modify(
    payload: BookingChangeRequest,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    bookings: Annotated[BookingsSql, Depends(bookings_repository)],
    reserva_id: Annotated[Identifier, Path()],
) -> BookingView | Response:
    try:
        booking = modify_booking(
            bookings,
            perfil,
            reserva_id,
            payload.espacio_id,
            payload.fecha,
            parse_time(payload.desde),
            datetime.now(CLUB_TIMEZONE),
        )
    except Unavailable:
        raise InvalidData({"espacio_id": UNAVAILABLE_MESSAGE}) from None
    except ConcurrentChange:
        return conflict({"reserva": CHANGED_MESSAGE})
    except SlotTaken:
        return conflict({"horario": SLOT_TAKEN_MESSAGE})
    return _view(booking)


class BookingHistoryView(_BookingFields):
    usuario_id: UUID
    usuario: str
    creado_en: datetime
    cancelada_en: datetime | None
    cancelada_por_nombre: str | None
    espacio_de_baja: bool
    anulable: bool
    aviso_envio: str | None
    aviso_en: datetime | None


class CountersView(BaseModel):
    todas: int
    activas: int
    completadas: int
    anuladas: int


class HistoryView(BaseModel):
    reservas: list[BookingHistoryView]
    total: int
    pagina: int
    por_pagina: int
    contadores: CountersView


def _admin_view(b: BookingHistoryEntry) -> BookingHistoryView:
    return BookingHistoryView(
        id=b.id,
        espacio_id=b.space_id,
        sede_id=b.venue_id,
        espacio=b.space,
        deporte=b.sport,
        tipo=b.kind,
        sede=b.venue,
        direccion=b.address,
        inicio=b.starts_at,
        fin=b.ends_at,
        precio_por_hora=b.price_per_hour,
        total=b.total,
        estado=b.status,
        motivo=b.reason,
        usuario_id=b.user_id,
        usuario=b.user,
        creado_en=b.created_at,
        cancelada_en=b.canceled_at,
        cancelada_por_nombre=b.canceled_by_name,
        espacio_de_baja=b.space_deactivated,
        anulable=b.voidable,
        aviso_envio=b.notice_delivery,
        aviso_en=b.notice_at,
    )


@router.get(
    "/reservas/todas",
    operation_id="listar_todas_reservas_todas_get",
    response_model=HistoryView,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador consulta el historial global"},
        422: {"model": Errors},
    },
    summary="El historial global de reservas (CU-14)",
    description=(
        "Todos los usuarios, todas las sedes. Filtra por estado (`activa`, `completada` o"
        " `anulada`; sin filtro trae también las canceladas por su usuario), sede, deporte,"
        " rango de fechas y texto (usuario, sede o espacio); pagina de a 20 con `pagina`, de la"
        " más reciente a la más antigua. No modifica nada."
    ),
)
def list_all(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    bookings: Annotated[BookingsSql, Depends(bookings_repository)],
    estado: Annotated[StatusFilter | None, Query()] = None,
    sede_id: Annotated[Identifier | None, Query()] = None,
    deporte: Annotated[str | None, Query()] = None,
    desde: Annotated[date | None, Query()] = None,
    hasta: Annotated[date | None, Query()] = None,
    q: Annotated[str | None, Query()] = None,
    pagina: Annotated[int, Query(ge=1, le=MAX_PAGE)] = 1,
) -> HistoryView:
    history = global_history(
        bookings,
        perfil,
        HistoryFilters(
            status=estado,
            venue_id=sede_id,
            sport=deporte,
            since=desde,
            until=hasta,
            q=q,
            page=pagina,
        ),
    )
    return HistoryView(
        reservas=[_admin_view(b) for b in history.bookings],
        total=history.total,
        pagina=history.page,
        por_pagina=history.per_page,
        contadores=CountersView(
            todas=history.counters.all,
            activas=history.counters.active,
            completadas=history.counters.completed,
            anuladas=history.counters.voided,
        ),
    )


@router.get(
    "/reservas/todas/{reserva_id}",
    operation_id="detalle_reservas_todas__reserva_id__get",
    response_model=BookingHistoryView,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador consulta el detalle de cualquier reserva"},
        404: {"description": "No hay una reserva con ese número"},
    },
    summary="El detalle de cualquier reserva (CU-14)",
)
def detail(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    bookings: Annotated[BookingsSql, Depends(bookings_repository)],
    reserva_id: Annotated[Identifier, Path()],
) -> BookingHistoryView:
    return _admin_view(admin_detail(bookings, perfil, reserva_id))


class VoidRequest(BaseModel):
    motivo: str
    espacio_id: Identifier
    inicio: AwareDatetime


@router.post(
    "/reservas/{reserva_id}/anular",
    operation_id="anular_reservas__reserva_id__anular_post",
    response_model=BookingHistoryView,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Sólo un administrador anula una reserva"},
        404: {"description": "No hay una reserva con ese número"},
        409: {"model": Errors, "description": "La reserva ya no está activa, ya empezó o cambió"},
        422: {"model": Errors},
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
def void(
    payload: VoidRequest,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    bookings: Annotated[BookingsSql, Depends(bookings_repository)],
    reserva_id: Annotated[Identifier, Path()],
    background: BackgroundTasks,
    channel: Annotated[CanalPush, Depends(canal_push)],
) -> BookingHistoryView | Response:
    try:
        booking = void_booking(
            bookings,
            perfil,
            reserva_id,
            payload.motivo,
            payload.espacio_id,
            payload.inicio,
        )
    except ConcurrentChange:
        return conflict({"reserva": CHANGED_MESSAGE})
    # The notice to whoever booked goes out only once the voiding is confirmed and the
    # response sent.
    background.add_task(despachar_de, booking.user_id, channel)
    return _admin_view(booking)
