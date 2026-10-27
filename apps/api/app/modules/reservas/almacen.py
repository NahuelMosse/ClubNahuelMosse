from datetime import datetime
from typing import Protocol
from uuid import UUID

from app.modules.horarios import Agenda
from app.modules.reservas.reglas import (
    Cuando,
    FiltrosHistorial,
    HistorialDeReservas,
    Reserva,
    ReservaHistorial,
)


class Reservas(Protocol):
    def de_usuario(self, usuario_id: UUID, cuando: Cuando) -> list[Reserva]:
        """Las próximas: activas que no terminaron, de la más cercana a la más lejana. El
        historial: completadas, canceladas y anuladas, de la más reciente a la más vieja."""
        ...

    def agenda(self, espacio_id: UUID) -> Agenda | None:
        """El horario de la sede del espacio, o `None` si el espacio o su sede no están
        activos."""
        ...

    def repetida(
        self, usuario_id: UUID, espacio_id: UUID, inicio: datetime, fin: datetime
    ) -> Reserva | None:
        """La reserva activa que la misma persona hizo hace un momento con esos datos."""
        ...

    def propia(self, usuario_id: UUID, reserva_id: UUID) -> Reserva | None:
        """La reserva [reserva_id] si es de [usuario_id]."""
        ...

    def tipo_de_espacio(self, espacio_id: UUID) -> tuple[UUID, str, str] | None:
        """Sede, deporte y tipo del espacio."""
        ...

    def mover(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
        self,
        usuario_id: UUID,
        reserva_id: UUID,
        antes: tuple[UUID, datetime],
        espacio_id: UUID,
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

    def cancelar(self, usuario_id: UUID, reserva_id: UUID) -> Reserva:
        """Cancela la reserva de [usuario_id] y estampa cuándo y quién (RF 3: el horario
        vuelve a quedar libre). Si ya la había cancelado esa persona, la devuelve igual.

        Lanza `NoEncontrada` si no es suya y `Cambiado` si ya no está activa o ya empezó.
        """
        ...

    def insertar(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
        self, usuario_id: UUID, espacio_id: UUID, inicio: datetime, fin: datetime, agenda: Agenda
    ) -> Reserva:
        """Guarda la reserva activa con el precio de ahora del espacio.

        Si la misma persona pidió lo mismo hace un momento, es su pedido repetido después de
        un corte y devuelve esa reserva. Lanza `HorarioOcupado` si otra reserva activa del
        espacio se superpone, `NoDisponible` si el espacio, su sede o la cuenta ya no
        están activos, y `AgendaCambiada` si la sede ya no tiene la [agenda] con que se
        validó.
        """
        ...

    def anular(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
        self, admin_id: UUID, reserva_id: UUID, motivo: str, espacio_id: UUID, inicio: datetime
    ) -> ReservaHistorial:
        """Anula la reserva [reserva_id], que el administrador vio en [espacio_id] desde
        [inicio], y estampa quién, cuándo y el [motivo] (CU-15): el horario vuelve a quedar
        libre. Si ya la había anulado ese administrador con ese motivo, la devuelve igual.

        Lanza `NoEncontrada` si no existe y `Cambiado` si ya no está activa, ya empezó o ya no
        está en ese espacio y horario.
        """
        ...

    def historial(self, filtros: FiltrosHistorial) -> HistorialDeReservas:
        """El historial global de todos los usuarios y todas las sedes que cumple
        [filtros] (CU-14), de la más reciente a la más antigua, paginado."""
        ...

    def una_de_cualquiera(self, reserva_id: UUID) -> ReservaHistorial | None:
        """La reserva [reserva_id], sea de quien sea, con su trazabilidad completa."""
        ...
