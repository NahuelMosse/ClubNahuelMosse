from collections.abc import Callable
from datetime import date, datetime, time, timedelta
from typing import Literal, Protocol

from app.aplicacion.errores import (
    AgendaCambiada,
    DatosInvalidos,
    HorarioOcupado,
    NoDisponible,
    NoEncontrada,
    Prohibido,
)
from app.dominio.horarios import Agenda, rango, validar_reserva
from app.dominio.reservas import Reserva
from app.dominio.usuarios import Perfil

Cuando = Literal["proximas", "historial"]


class Reservas(Protocol):
    def de_usuario(self, usuario_id: int, cuando: Cuando) -> list[Reserva]:
        """Las próximas: activas que no terminaron, de la más cercana a la más lejana. El
        historial: completadas, canceladas y anuladas, de la más reciente a la más vieja."""
        ...

    def agenda(self, espacio_id: int) -> Agenda | None:
        """El horario de la sede del espacio, o `None` si el espacio o su sede no están
        activos."""
        ...

    def repetida(
        self, usuario_id: int, espacio_id: int, inicio: datetime, fin: datetime
    ) -> Reserva | None:
        """La reserva activa que la misma persona hizo hace un momento con esos datos."""
        ...

    def propia(self, usuario_id: int, reserva_id: int) -> Reserva | None:
        """La reserva [reserva_id] si es de [usuario_id]."""
        ...

    def tipo_de_espacio(self, espacio_id: int) -> tuple[int, str, str] | None:
        """Sede, deporte y tipo del espacio."""
        ...

    def mover(
        self,
        usuario_id: int,
        reserva_id: int,
        antes: tuple[int, datetime],
        espacio_id: int,
        inicio: datetime,
        fin: datetime,
        agenda: Agenda,
    ) -> Reserva:
        """Pasa la reserva, que estaba en [antes] (espacio e inicio), a [espacio_id] de
        [inicio] a [fin], con el precio de ahora de ese espacio. El horario anterior se libera
        sólo si el nuevo queda tomado.

        Lanza `NoEncontrada`, `Cambiado` (ya no activa, empezada o ya no en [antes]),
        `NoDisponible` (el espacio nuevo ya no está), `HorarioOcupado` y `AgendaCambiada` si
        la sede ya no tiene la [agenda] con que se validó.
        """
        ...

    def cancelar(self, usuario_id: int, reserva_id: int) -> Reserva:
        """Cancela la reserva de [usuario_id] y estampa cuándo y quién (RF 3: el horario
        vuelve a quedar libre). Si ya la había cancelado esa persona, la devuelve igual.

        Lanza `NoEncontrada` si no es suya y `Cambiado` si ya no está activa o ya empezó.
        """
        ...

    def insertar(
        self, usuario_id: int, espacio_id: int, inicio: datetime, fin: datetime, agenda: Agenda
    ) -> Reserva:
        """Guarda la reserva activa con el precio de ahora del espacio.

        Si la misma persona pidió lo mismo hace un momento, es su pedido repetido después de
        un corte y devuelve esa reserva. Lanza `HorarioOcupado` si otra reserva activa del
        espacio se superpone, `NoDisponible` si el espacio, su sede o la cuenta ya no
        están activos, y `AgendaCambiada` si la sede ya no tiene la [agenda] con que se
        validó.
        """
        ...


def _con_la_agenda_vigente(
    reservas: Reservas,
    espacio_id: int,
    fecha: date,
    desde: time,
    horas: int,
    ahora: datetime,
    guardar: Callable[[Agenda], Reserva],
) -> Reserva:
    """Valida el horario con la agenda de la sede y guarda. Si un administrador cambió la
    agenda en el medio, vuelve a validar con la nueva: lo que se guarda respeta el horario que
    rige cuando se guarda (RF 3)."""
    for _ in range(3):
        agenda = reservas.agenda(espacio_id)
        if agenda is None:
            raise NoDisponible("el espacio no está activo")
        errores = validar_reserva(agenda, fecha, desde, horas, ahora)
        if errores:
            raise DatosInvalidos(errores)
        try:
            return guardar(agenda)
        except AgendaCambiada:
            continue
    raise HorarioOcupado("el horario de la sede cambió varias veces seguidas")


def mis_reservas(reservas: Reservas, perfil: Perfil, cuando: Cuando) -> list[Reserva]:
    """Las reservas de quien consulta y de nadie más (RF 3, RF 6)."""
    return reservas.de_usuario(perfil.id, cuando)


def reservar(
    reservas: Reservas,
    perfil: Perfil,
    espacio_id: int,
    fecha: date,
    desde: time | None,
    horas: int,
    ahora: datetime,
) -> Reserva:
    """Reserva [horas] horas del espacio desde [desde] el [fecha], en la hora del club que
    trae [ahora] (RF 3). El backend valida el horario y la superposición antes de guardar.

    Lanza `Prohibido` si quien pide es administrador, `DatosInvalidos` si el horario no se
    puede reservar, `NoDisponible` y `HorarioOcupado` como `Reservas.insertar`.
    """
    if perfil.rol != "usuario":
        raise Prohibido("sólo un usuario reserva")
    if desde is None:
        raise DatosInvalidos({"desde": "Elegí una hora en punto"})
    inicio, _ = rango(fecha, desde, desde, ahora.tzinfo)
    fin = inicio + timedelta(hours=horas)
    # Un reintento después de un corte puede llegar cuando el turno ya empezó: si la reserva
    # se hizo, se devuelve sin volver a validar el horario.
    if horas > 0 and (ya := reservas.repetida(perfil.id, espacio_id, inicio, fin)):
        return ya
    return _con_la_agenda_vigente(
        reservas,
        espacio_id,
        fecha,
        desde,
        horas,
        ahora,
        lambda agenda: reservas.insertar(perfil.id, espacio_id, inicio, fin, agenda),
    )


def cancelar_reserva(reservas: Reservas, perfil: Perfil, reserva_id: int) -> Reserva:
    """Cancela una reserva propia que todavía no empezó (CU-10, decisión 13: hasta el
    inicio, sin anticipación mínima)."""
    return reservas.cancelar(perfil.id, reserva_id)


def modificar_reserva(
    reservas: Reservas,
    perfil: Perfil,
    reserva_id: int,
    espacio_id: int,
    fecha: date,
    desde: time | None,
    ahora: datetime,
) -> Reserva:
    """Cambia la cancha, el día o el horario de una reserva propia, con la misma duración
    (CU-11). La reserva conserva su número.

    Lanza `Prohibido` si quien pide es administrador, `NoEncontrada` si la reserva no es
    suya, `DatosInvalidos` si el horario nuevo no vale, y `NoDisponible`, `Cambiado` y
    `HorarioOcupado` como `Reservas.mover`.
    """
    if perfil.rol != "usuario":
        raise Prohibido("sólo un usuario reserva")
    if desde is None:
        raise DatosInvalidos({"desde": "Elegí una hora en punto"})
    actual = reservas.propia(perfil.id, reserva_id)
    if actual is None:
        raise NoEncontrada("no hay una reserva suya con ese número")
    inicio, _ = rango(fecha, desde, desde, ahora.tzinfo)
    # Un reintento después de un corte llega con la reserva ya movida: se devuelve como está.
    if actual.estado == "activa" and (actual.espacio_id, actual.inicio) == (espacio_id, inicio):
        return actual
    nuevo = reservas.tipo_de_espacio(espacio_id)
    if nuevo is None or nuevo != (actual.sede_id, actual.deporte, actual.tipo):
        raise DatosInvalidos({"espacio_id": "Elegí una cancha del mismo tipo en la misma sede"})
    horas = int((actual.fin - actual.inicio).total_seconds()) // 3600
    return _con_la_agenda_vigente(
        reservas,
        espacio_id,
        fecha,
        desde,
        horas,
        ahora,
        lambda agenda: reservas.mover(
            perfil.id,
            reserva_id,
            (actual.espacio_id, actual.inicio),
            espacio_id,
            inicio,
            inicio + timedelta(hours=horas),
            agenda,
        ),
    )
