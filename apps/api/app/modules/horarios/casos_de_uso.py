# kit-shape: el contrato del repositorio de horarios y el caso de uso que lo usa se leen juntos
from datetime import date, datetime, timedelta
from typing import Protocol
from uuid import UUID

from app.modules.horarios.reglas import Agenda, Grilla, grilla, validar_consulta
from app.shared.errores import DatosInvalidos, NoDisponible


class Horarios(Protocol):
    def agenda(self, espacio_id: UUID) -> Agenda | None:
        """El horario de la sede del espacio, o `None` si el espacio o su sede no están
        activos."""
        ...

    def ocupadas(
        self,
        espacio_id: UUID,
        desde: datetime,
        hasta: datetime,
        salvo: tuple[UUID, UUID] | None = None,
    ) -> list[tuple[datetime, datetime]]:
        """Inicio y fin de las reservas activas del espacio que pisan [desde, hasta), salvo
        la reserva [salvo] = (número, usuario) si es de ese usuario."""
        ...


def horarios_disponibles(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
    horarios: Horarios,
    espacio_id: UUID,
    fecha: date | None,
    horas: int,
    ahora: datetime,
    salvo: tuple[UUID, UUID] | None = None,
) -> Grilla:
    """La grilla del espacio para [fecha] (hoy si no viene) con franjas de [horas].

    Lanza `DatosInvalidos` si la fecha o la duración no se pueden consultar y
    `NoDisponible` si el espacio ya no se puede reservar.
    """
    hoy = ahora.date()
    dia = fecha or hoy
    errores = validar_consulta(dia, hoy, horas)
    if errores:
        raise DatosInvalidos(errores)
    agenda = horarios.agenda(espacio_id)
    if agenda is None:
        raise NoDisponible("el espacio no está activo")
    desde = datetime.combine(dia, datetime.min.time(), tzinfo=ahora.tzinfo)
    ocupadas = horarios.ocupadas(espacio_id, desde, desde + timedelta(days=2), salvo)
    return grilla(agenda, dia, horas, ahora, ocupadas)
