from dataclasses import dataclass
from datetime import date, datetime
from typing import Literal

Estado = Literal["activa", "completada", "cancelada", "anulada"]
# Las cuatro pestañas del historial global (CU-14): «cancelada» no tiene pestaña propia,
# sólo aparece dentro de «Todas».
FiltroEstado = Literal["activa", "completada", "anulada"]


@dataclass(frozen=True)
class Reserva:
    """Una reserva como la ve quien la hizo: el espacio (su nombre no cambia), la sede como
    está hoy, el total que se guardó al reservar y el estado de ahora (una activa que ya
    terminó es completada)."""

    id: int
    espacio_id: int
    sede_id: int
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
    # Activa y sin empezar, según el reloj del servidor: la app no decide con el suyo.
    cancelable: bool = False


@dataclass(frozen=True)
class FiltrosHistorial:
    """Lo que un administrador eligió para acotar el historial global (CU-14). `None` en
    cualquier campo significa que ese filtro no se aplica."""

    estado: FiltroEstado | None = None
    sede_id: int | None = None
    deporte: str | None = None
    desde: date | None = None
    hasta: date | None = None
    q: str | None = None
    pagina: int = 1


@dataclass(frozen=True)
class ReservaHistorial:
    """Una reserva como la ve un administrador: con quién la hizo, cuándo se creó y, si
    corresponde, quién y cuándo la canceló o anuló."""

    id: int
    espacio_id: int
    sede_id: int
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
    usuario_id: int
    usuario: str
    creado_en: datetime
    cancelada_en: datetime | None
    cancelada_por_nombre: str | None
    # El espacio o su sede ya no están activos: la reserva sigue en el historial (FA8), con
    # el nombre técnico que tenía al reservar.
    espacio_de_baja: bool
    # Activa y sin empezar, según el reloj del servidor: la app no decide con el suyo.
    anulable: bool = False


@dataclass(frozen=True)
class Contadores:
    """Cuántas reservas hay en cada pestaña, con los mismos filtros salvo el de estado."""

    todas: int
    activas: int
    completadas: int
    anuladas: int


@dataclass(frozen=True)
class HistorialDeReservas:
    """Una página del historial global, con el total y los contadores de las pestañas."""

    reservas: list[ReservaHistorial]
    total: int
    pagina: int
    por_pagina: int
    contadores: Contadores
