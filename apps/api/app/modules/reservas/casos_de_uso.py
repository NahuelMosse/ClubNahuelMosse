from collections.abc import Callable
from datetime import date, datetime, time, timedelta
from uuid import UUID

from app.modules.horarios import DIAS_A_LA_VISTA, Agenda, error_de_duracion, rango, validar_reserva
from app.modules.reservas.almacen import Reservas
from app.modules.reservas.reglas import Cuando as Cuando
from app.modules.reservas.reglas import (
    FiltrosHistorial,
    HistorialDeReservas,
    Reserva,
    ReservaHistorial,
)
from app.modules.sesion import Perfil
from app.shared.errors import (
    Forbidden,
    InvalidData,
    NotFound,
    OpeningHoursChanged,
    SlotTaken,
    Unavailable,
)

# Largo máximo del motivo de una anulación.
MOTIVO_MAXIMO = 500
# Cuántas veces se vuelve a validar si la agenda de la sede cambia mientras se guarda.
INTENTOS_CON_AGENDA_NUEVA = 3


def _con_la_agenda_vigente(
    reservas: Reservas,
    espacio_id: UUID,
    validar: Callable[[Agenda], dict[str, str]],
    guardar: Callable[[Agenda], Reserva],
) -> Reserva:
    """Valida el horario con la agenda de la sede y guarda. Si un administrador cambió la
    agenda en el medio, vuelve a validar con la nueva: lo que se guarda respeta el horario que
    rige cuando se guarda (RF 3)."""
    for _ in range(INTENTOS_CON_AGENDA_NUEVA):
        agenda = reservas.agenda(espacio_id)
        if agenda is None:
            raise Unavailable("el espacio no está activo")
        errores = validar(agenda)
        if errores:
            raise InvalidData(errores)
        try:
            return guardar(agenda)
        except OpeningHoursChanged:
            continue
    raise SlotTaken("el horario de la sede cambió varias veces seguidas")


def mis_reservas(reservas: Reservas, perfil: Perfil, cuando: Cuando) -> list[Reserva]:
    """Las reservas de quien consulta y de nadie más (RF 3, RF 6)."""
    return reservas.de_usuario(perfil.id, cuando)


def _exigir_fecha_a_la_vista(fecha: date, ahora: datetime) -> None:
    """Una fecha más allá de la ventana de reserva se rechaza antes de calcular el fin del
    turno: cerca de `date.max` esa cuenta se desborda."""
    if fecha >= ahora.date() + timedelta(days=DIAS_A_LA_VISTA):
        raise InvalidData({"fecha": f"Elegí un día de los próximos {DIAS_A_LA_VISTA}"})


def _exigir_mismo_tipo(reservas: Reservas, actual: Reserva, espacio_id: UUID) -> None:
    nuevo = reservas.tipo_de_espacio(espacio_id)
    if nuevo is None or nuevo != (actual.sede_id, actual.deporte, actual.tipo):
        raise InvalidData({"espacio_id": "Elegí una cancha del mismo tipo en la misma sede"})


def reservar(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
    reservas: Reservas,
    perfil: Perfil,
    espacio_id: UUID,
    fecha: date,
    desde: time | None,
    horas: int,
    ahora: datetime,
) -> Reserva:
    """Reserva [horas] horas del espacio desde [desde] el [fecha], en la hora del club que
    trae [ahora] (RF 3). El backend valida el horario y la superposición antes de guardar.

    Lanza `Forbidden` si quien pide es administrador, `InvalidData` si el horario no se
    puede reservar, `Unavailable` y `SlotTaken` como `Reservas.insertar`.
    """
    if perfil.rol != "usuario":
        raise Forbidden("sólo un usuario reserva")
    if desde is None:
        raise InvalidData({"desde": "Elegí una hora en punto"})
    if error := error_de_duracion(horas):
        # Antes de calcular el fin del turno: con una duración desmesurada esa cuenta se
        # desborda. `hasta` es el campo que ya leen los clientes.
        raise InvalidData({"horas": error, "hasta": error})
    _exigir_fecha_a_la_vista(fecha, ahora)
    inicio, _ = rango(fecha, desde, desde, ahora.tzinfo)
    fin = inicio + timedelta(hours=horas)
    # Un reintento después de un corte puede llegar cuando el turno ya empezó: si la reserva
    # se hizo, se devuelve sin volver a validar el horario.
    if ya := reservas.repetida(perfil.id, espacio_id, inicio, fin):
        return ya
    return _con_la_agenda_vigente(
        reservas,
        espacio_id,
        lambda agenda: validar_reserva(agenda, fecha, desde, horas, ahora),
        lambda agenda: reservas.insertar(perfil.id, espacio_id, inicio, fin, agenda),
    )


def cancelar_reserva(reservas: Reservas, perfil: Perfil, reserva_id: UUID) -> Reserva:
    """Cancela una reserva propia que todavía no empezó (CU-10, decisión 13: hasta el
    inicio, sin anticipación mínima)."""
    return reservas.cancelar(perfil.id, reserva_id)


def modificar_reserva(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
    reservas: Reservas,
    perfil: Perfil,
    reserva_id: UUID,
    espacio_id: UUID,
    fecha: date,
    desde: time | None,
    ahora: datetime,
) -> Reserva:
    """Cambia la cancha, el día o el horario de una reserva propia, con la misma duración
    (CU-11). La reserva conserva su número.

    Lanza `Forbidden` si quien pide es administrador, `NotFound` si la reserva no es
    suya, `InvalidData` si el horario nuevo no vale, y `Unavailable`, `ConcurrentChange` y
    `SlotTaken` como `Reservas.mover`.
    """
    if perfil.rol != "usuario":
        raise Forbidden("sólo un usuario reserva")
    if desde is None:
        raise InvalidData({"desde": "Elegí una hora en punto"})
    _exigir_fecha_a_la_vista(fecha, ahora)
    actual = reservas.propia(perfil.id, reserva_id)
    if actual is None:
        raise NotFound("no hay una reserva suya con ese número")
    inicio, _ = rango(fecha, desde, desde, ahora.tzinfo)
    # Un reintento después de un corte llega con la reserva ya movida: se devuelve como está.
    if actual.estado == "activa" and (actual.espacio_id, actual.inicio) == (espacio_id, inicio):
        return actual
    _exigir_mismo_tipo(reservas, actual, espacio_id)
    duracion = actual.fin - actual.inicio
    antes = (actual.espacio_id, actual.inicio)
    return _con_la_agenda_vigente(
        reservas,
        espacio_id,
        lambda agenda: validar_reserva(agenda, fecha, desde, duracion // timedelta(hours=1), ahora),
        lambda agenda: reservas.mover(
            perfil.id, reserva_id, antes, espacio_id, inicio, inicio + duracion, agenda
        ),
    )


def historial_global(
    reservas: Reservas, perfil: Perfil, filtros: FiltrosHistorial
) -> HistorialDeReservas:
    """El historial completo de reservas de todos los usuarios y todas las sedes (CU-14, RF
    6): sólo lo consulta un administrador. No modifica nada (la consulta es de sólo lectura).

    Lanza `Forbidden` si quien pide no es administrador y `InvalidData` si el rango de
    fechas tiene `desde` posterior a `hasta`.
    """
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador consulta el historial global")
    if filtros.desde is not None and filtros.hasta is not None and filtros.desde > filtros.hasta:
        raise InvalidData({"fechas": "Desde no puede ser posterior a Hasta"})
    return reservas.historial(filtros)


def detalle_admin(reservas: Reservas, perfil: Perfil, reserva_id: UUID) -> ReservaHistorial:
    """El detalle de cualquier reserva del sistema, para un administrador (CU-14).

    Lanza `Forbidden` si quien pide no es administrador y `NotFound` si no hay ninguna
    reserva con ese número.
    """
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador consulta el detalle de cualquier reserva")
    detalle = reservas.una_de_cualquiera(reserva_id)
    if detalle is None:
        raise NotFound("no hay una reserva con ese número")
    return detalle


def anular_reserva(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
    reservas: Reservas,
    perfil: Perfil,
    reserva_id: UUID,
    motivo: str,
    espacio_id: UUID,
    inicio: datetime,
) -> ReservaHistorial:
    """Anula por una causa operativa una reserva activa que todavía no empezó (CU-15, RF 3):
    el horario vuelve a quedar libre y la reserva guarda quién la anuló, cuándo y por qué.

    Lanza `Forbidden` si quien pide no es administrador, `InvalidData` si el motivo está
    vacío o es demasiado largo, y `NotFound` y `ConcurrentChange` como `Reservas.anular`.
    """
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador anula una reserva")
    limpio = motivo.strip()
    if not limpio:
        raise InvalidData({"motivo": "El motivo es obligatorio para anular"})
    if len(limpio) > MOTIVO_MAXIMO:
        raise InvalidData({"motivo": f"El motivo admite hasta {MOTIVO_MAXIMO} caracteres"})
    return reservas.anular(perfil.id, reserva_id, limpio, espacio_id, inicio)
