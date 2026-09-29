from datetime import date, datetime, time, timedelta
from typing import Literal, Protocol

from app.aplicacion.errores import DatosInvalidos, NoDisponible, Prohibido
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

    def insertar(
        self, usuario_id: int, espacio_id: int, inicio: datetime, fin: datetime
    ) -> Reserva:
        """Guarda la reserva activa con el precio de ahora del espacio.

        Si la misma persona pidió lo mismo hace un momento, es su pedido repetido después de
        un corte y devuelve esa reserva. Lanza `HorarioOcupado` si otra reserva activa del
        espacio se superpone y `NoDisponible` si el espacio, su sede o la cuenta ya no
        están activos.
        """
        ...


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
    agenda = reservas.agenda(espacio_id)
    if agenda is None:
        raise NoDisponible("el espacio no está activo")
    errores = validar_reserva(agenda, fecha, desde, horas, ahora)
    if errores:
        raise DatosInvalidos(errores)
    return reservas.insertar(perfil.id, espacio_id, inicio, fin)
