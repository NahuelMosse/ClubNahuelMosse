# kit-shape: the booking routes and the models of their requests and responses are read together
from datetime import date as date_type
from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, Depends, Path, Query, Response, status
from pydantic import AwareDatetime, BaseModel

from app.modules.bookings.email import booking_email
from app.modules.bookings.repository import BookingsSql, bookings_repository
from app.modules.bookings.rules import HistoryFilters, Status, StatusFilter
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
from app.modules.notifications import PushChannel, dispatch_for, push_channel
from app.modules.session import NoSession, Profile, current_user
from app.shared.club_timezone import CLUB_TIMEZONE
from app.shared.email import send
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
    space_id: UUID
    venue_id: UUID
    space: str
    sport: str
    kind: str
    venue: str
    address: str
    starts_at: datetime
    ends_at: datetime
    price_per_hour: int
    total: int
    status: Status
    reason: str | None


class BookingView(_BookingFields):
    cancelable: bool


class Errors(BaseModel):
    errors: dict[str, str]


class BookingList(BaseModel):
    bookings: list[BookingView]


@router.get(
    "/bookings",
    response_model=BookingList,
    responses={401: {"model": NoSession}, 422: {"model": Errors}},
    summary="Las reservas de quien consulta",
    description=(
        "`upcoming`: las activas que no terminaron, de la más cercana a la más lejana. "
        "`history`: las completadas, canceladas y anuladas, de la más reciente a la más "
        "vieja. El total es el que se guardó al reservar."
    ),
)
def list_bookings(
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    when: Annotated[When, Query()] = "upcoming",
) -> BookingList:
    return BookingList(
        bookings=[
            BookingView.model_validate(b, from_attributes=True)
            for b in my_bookings(repository, profile, when)
        ]
    )


class BookingRequest(BaseModel):
    space_id: Identifier
    date: date_type
    start_hour: str
    # No bound here: the use case rejects an out-of-range duration before computing anything.
    hours: int


@router.post(
    "/bookings",
    status_code=status.HTTP_201_CREATED,
    response_model=BookingView,
    responses={
        401: {"model": NoSession},
        403: {"description": "El administrador no reserva"},
        409: {"model": Errors, "description": "Otra reserva activa pisa ese horario"},
        422: {"model": Errors},
    },
    summary="Reservar un espacio",
    description=(
        "`hours` horas desde `start_hour` (`HH:MM`, en la hora del club) el día `date`. Horas "
        "completas, de 1 a 4, futuras, de los próximos 7 días y dentro del horario de la sede; "
        "si la misma persona repite el mismo pedido dentro de los cinco minutos, devuelve la "
        "reserva que ya hizo."
    ),
)
def create_booking(
    payload: BookingRequest,
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    after: BackgroundTasks,
) -> BookingView | Response:
    try:
        booking = book(
            repository,
            profile,
            payload.space_id,
            payload.date,
            parse_time(payload.start_hour),
            payload.hours,
            datetime.now(CLUB_TIMEZONE),
        )
    except Unavailable:
        raise InvalidData({"space_id": UNAVAILABLE_MESSAGE}) from None
    except SlotTaken:
        return conflict({"slot": SLOT_TAKEN_MESSAGE})
    after.add_task(send, booking_email(profile, booking))
    return BookingView.model_validate(booking, from_attributes=True)


CHANGED_MESSAGE = "Esto cambió mientras tanto"


@router.post(
    "/bookings/{booking_id}/cancel",
    response_model=BookingView,
    responses={
        401: {"model": NoSession},
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
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    booking_id: Annotated[Identifier, Path()],
    background: BackgroundTasks,
    channel: Annotated[PushChannel, Depends(push_channel)],
) -> BookingView | Response:
    try:
        booking = cancel_booking(repository, profile, booking_id)
    except ConcurrentChange:
        return conflict({"booking": CHANGED_MESSAGE})
    background.add_task(dispatch_for, profile.id, channel)
    return BookingView.model_validate(booking, from_attributes=True)


class BookingChangeRequest(BaseModel):
    space_id: Identifier
    date: date_type
    start_hour: str


@router.post(
    "/bookings/{booking_id}/modify",
    response_model=BookingView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Un administrador no reserva"},
        404: {"description": "No hay una reserva de quien pide con ese número"},
        409: {
            "model": Errors,
            "description": "El horario nuevo se ocupó (`slot`) o la reserva ya no se puede "
            "modificar (`booking`)",
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
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    booking_id: Annotated[Identifier, Path()],
) -> BookingView | Response:
    try:
        booking = modify_booking(
            repository,
            profile,
            booking_id,
            payload.space_id,
            payload.date,
            parse_time(payload.start_hour),
            datetime.now(CLUB_TIMEZONE),
        )
    except Unavailable:
        raise InvalidData({"space_id": UNAVAILABLE_MESSAGE}) from None
    except ConcurrentChange:
        return conflict({"booking": CHANGED_MESSAGE})
    except SlotTaken:
        return conflict({"slot": SLOT_TAKEN_MESSAGE})
    return BookingView.model_validate(booking, from_attributes=True)


class BookingHistoryView(_BookingFields):
    user_id: UUID
    user: str
    created_at: datetime
    canceled_at: datetime | None
    canceled_by_name: str | None
    space_deactivated: bool
    voidable: bool
    notice_delivery: str | None
    notice_at: datetime | None


class CountersView(BaseModel):
    all: int
    active: int
    completed: int
    voided: int


class HistoryView(BaseModel):
    bookings: list[BookingHistoryView]
    total: int
    page: int
    per_page: int
    counters: CountersView


@router.get(
    "/bookings/all",
    response_model=HistoryView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Sólo un administrador consulta el historial global"},
        422: {"model": Errors},
    },
    summary="El historial global de reservas (CU-14)",
    description=(
        "Todos los usuarios, todas las sedes. Filtra por estado (`active`, `completed` o"
        " `voided`; sin filtro trae también las canceladas por su usuario), sede, deporte,"
        " rango de fechas y texto (usuario, sede o espacio); pagina de a 20 con `page`, de la"
        " más reciente a la más antigua. No modifica nada."
    ),
)
def list_all(  # noqa: PLR0913, PLR0917 -- one parameter per query filter of the route
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    status: Annotated[StatusFilter | None, Query()] = None,
    venue_id: Annotated[Identifier | None, Query()] = None,
    sport: Annotated[str | None, Query()] = None,
    since: Annotated[date_type | None, Query()] = None,
    until: Annotated[date_type | None, Query()] = None,
    q: Annotated[str | None, Query()] = None,
    page: Annotated[int, Query(ge=1, le=MAX_PAGE)] = 1,
) -> HistoryView:
    history = global_history(
        repository,
        profile,
        HistoryFilters(
            status=status,
            venue_id=venue_id,
            sport=sport,
            since=since,
            until=until,
            q=q,
            page=page,
        ),
    )
    return HistoryView(
        bookings=[
            BookingHistoryView.model_validate(b, from_attributes=True) for b in history.bookings
        ],
        total=history.total,
        page=history.page,
        per_page=history.per_page,
        counters=CountersView(
            all=history.counters.all,
            active=history.counters.active,
            completed=history.counters.completed,
            voided=history.counters.voided,
        ),
    )


@router.get(
    "/bookings/all/{booking_id}",
    response_model=BookingHistoryView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Sólo un administrador consulta el detalle de cualquier reserva"},
        404: {"description": "No hay una reserva con ese número"},
    },
    summary="El detalle de cualquier reserva (CU-14)",
)
def detail(
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    booking_id: Annotated[Identifier, Path()],
) -> BookingHistoryView:
    return BookingHistoryView.model_validate(
        admin_detail(repository, profile, booking_id), from_attributes=True
    )


class VoidRequest(BaseModel):
    reason: str
    space_id: Identifier
    starts_at: AwareDatetime


@router.post(
    "/bookings/{booking_id}/void",
    response_model=BookingHistoryView,
    responses={
        401: {"model": NoSession},
        403: {"description": "Sólo un administrador anula una reserva"},
        404: {"description": "No hay una reserva con ese número"},
        409: {"model": Errors, "description": "La reserva ya no está activa, ya empezó o cambió"},
        422: {"model": Errors},
    },
    summary="Anular una reserva (CU-15)",
    description=(
        "Hasta el inicio del turno. `space_id` y `starts_at` son la cancha y el horario que el "
        "administrador vio: si la reserva ya no está ahí, responde 409. El horario vuelve a "
        "quedar libre y la reserva guarda el motivo, quién la anuló y cuándo. Repetir una "
        "anulación ya hecha por el mismo administrador con el mismo motivo responde igual. "
        "Le avisa a quien reservó, con el motivo, sin repetir el aviso."
    ),
)
def void(
    payload: VoidRequest,
    profile: Annotated[Profile, Depends(current_user)],
    repository: Annotated[BookingsSql, Depends(bookings_repository)],
    booking_id: Annotated[Identifier, Path()],
    background: BackgroundTasks,
    channel: Annotated[PushChannel, Depends(push_channel)],
) -> BookingHistoryView | Response:
    try:
        booking = void_booking(
            repository,
            profile,
            booking_id,
            payload.reason,
            payload.space_id,
            payload.starts_at,
        )
    except ConcurrentChange:
        return conflict({"booking": CHANGED_MESSAGE})
    # The notice to whoever booked goes out only once the voiding is confirmed and the
    # response sent.
    background.add_task(dispatch_for, booking.user_id, channel)
    return BookingHistoryView.model_validate(booking, from_attributes=True)
