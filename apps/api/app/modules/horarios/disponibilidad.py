# kit-shape: el contrato de disponibilidad y la función que lo usa se leen juntos
from datetime import date, datetime, time
from typing import Protocol
from uuid import UUID

from app.modules.espacios import Espacio
from app.modules.horarios.reglas import Agenda, rango, validar_rango
from app.shared.errors import InvalidData, Unavailable


class Disponibilidad(Protocol):
    def agenda_de_sede(self, sede_id: UUID) -> Agenda | None:
        """El horario de la sede, o `None` si no está activa."""
        ...

    def libres(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
        self, sede_id: UUID, deporte: str, tipo: str | None, inicio: datetime, fin: datetime
    ) -> list[Espacio]:
        """Los espacios activos de la sede, del deporte y del tipo si viene, sin reservas
        activas que pisen [inicio, fin), por deporte, tipo y número."""
        ...


def canchas_disponibles(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
    disponibilidad: Disponibilidad,
    sede_id: UUID,
    deporte: str,
    tipo: str | None,
    fecha: date,
    desde: time,
    hasta: time,
    ahora: datetime,
) -> list[Espacio]:
    """Las canchas libres en todo el rango (CU-13).

    Lanza `Unavailable` si la sede ya no está activa y `InvalidData` si el rango no se
    puede reservar.
    """
    agenda = disponibilidad.agenda_de_sede(sede_id)
    if agenda is None:
        raise Unavailable("la sede no está activa")
    errores = validar_rango(agenda, fecha, desde, hasta, ahora)
    if errores:
        raise InvalidData(errores)
    inicio, fin = rango(fecha, desde, hasta, ahora.tzinfo)
    return disponibilidad.libres(sede_id, deporte, tipo, inicio, fin)
