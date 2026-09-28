from datetime import date, datetime, time
from typing import Protocol

from app.aplicacion.errores import DatosInvalidos, NoDisponible
from app.dominio.espacios import Espacio
from app.dominio.horarios import Agenda, rango, validar_rango


class Disponibilidad(Protocol):
    def agenda_de_sede(self, sede_id: int) -> Agenda | None:
        """El horario de la sede, o `None` si no está activa."""
        ...

    def libres(
        self, sede_id: int, deporte: str, tipo: str | None, inicio: datetime, fin: datetime
    ) -> list[Espacio]:
        """Los espacios activos de la sede, del deporte y del tipo si viene, sin reservas
        activas que pisen [inicio, fin), por deporte, tipo y número."""
        ...


def canchas_disponibles(
    disponibilidad: Disponibilidad,
    sede_id: int,
    deporte: str,
    tipo: str | None,
    fecha: date,
    desde: time,
    hasta: time,
    ahora: datetime,
) -> list[Espacio]:
    """Las canchas libres en todo el rango (CU-13).

    Lanza `NoDisponible` si la sede ya no está activa y `DatosInvalidos` si el rango no se
    puede reservar.
    """
    agenda = disponibilidad.agenda_de_sede(sede_id)
    if agenda is None:
        raise NoDisponible("la sede no está activa")
    errores = validar_rango(agenda, fecha, desde, hasta, ahora)
    if errores:
        raise DatosInvalidos(errores)
    inicio, fin = rango(fecha, desde, hasta, ahora.tzinfo)
    return disponibilidad.libres(sede_id, deporte, tipo, inicio, fin)
