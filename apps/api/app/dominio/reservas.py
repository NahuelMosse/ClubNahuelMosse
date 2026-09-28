from dataclasses import dataclass
from datetime import datetime
from typing import Literal

Estado = Literal["activa", "completada", "cancelada", "anulada"]


@dataclass(frozen=True)
class Reserva:
    """Una reserva como la ve quien la hizo: el espacio (su nombre no cambia), la sede como
    está hoy, el total que se guardó al reservar y el estado de ahora (una activa que ya
    terminó es completada)."""

    id: int
    espacio_id: int
    espacio: str
    deporte: str
    tipo: str
    sede: str
    direccion: str
    inicio: datetime
    fin: datetime
    precio_por_hora: int
    total: int
    estado: Estado
    motivo: str | None
