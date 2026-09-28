from typing import Literal, Protocol

from app.dominio.reservas import Reserva
from app.dominio.usuarios import Perfil

Cuando = Literal["proximas", "historial"]


class Reservas(Protocol):
    def de_usuario(self, usuario_id: int, cuando: Cuando) -> list[Reserva]:
        """Las próximas: activas que no terminaron, de la más cercana a la más lejana. El
        historial: completadas, canceladas y anuladas, de la más reciente a la más vieja."""
        ...


def mis_reservas(reservas: Reservas, perfil: Perfil, cuando: Cuando) -> list[Reserva]:
    """Las reservas de quien consulta y de nadie más (RF 3, RF 6)."""
    return reservas.de_usuario(perfil.id, cuando)
