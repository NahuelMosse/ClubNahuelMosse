from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Literal

from app.dominio.espacios import CATALOGO

TipoDeAviso = Literal["recordatorio", "cancelacion_forzosa", "cancelacion_usuario"]
Envio = Literal["pendiente", "enviada", "sin_permiso", "sin_canal", "fallida"]

# El club está en UTC−3, sin horario de verano.
HORA_DEL_CLUB = timezone(timedelta(hours=-3))
ANTICIPACION = timedelta(hours=1)


@dataclass(frozen=True)
class Aviso:
    """Lo que se le dice a la persona y los datos con que la app sabe adónde llevarla."""

    titulo: str
    cuerpo: str
    datos: dict[str, str]


@dataclass(frozen=True)
class Notificacion:
    """Una entrada del centro de notificaciones."""

    id: int
    tipo: TipoDeAviso
    titulo: str
    cuerpo: str
    reserva_id: int | None
    creada_en: datetime
    leida: bool


@dataclass(frozen=True)
class Recordatorio:
    """Una reserva activa a la que le toca el aviso de una hora antes."""

    reserva_id: int
    usuario_id: int
    inicio: datetime
    fin: datetime
    deporte: str
    tipo: str
    sede: str


def tipo_corto(deporte: str, tipo: str) -> str:
    """«Fútbol 5»; sólo «Tenis» si el tipo no nombra al deporte («Polvo de ladrillo»)."""
    d = next((d for d in CATALOGO if d.clave == deporte), None)
    t = None if d is None else next((t for t in d.tipos if t.clave == tipo), None)
    if d is None or t is None:
        return deporte
    return t.nombre if t.nombre.startswith(d.nombre) else d.nombre


def _hora(momento: datetime) -> str:
    return momento.astimezone(HORA_DEL_CLUB).strftime("%H:%M")


def mensaje_recordatorio(r: Recordatorio) -> Aviso:
    """«Tu reserva es en 1 hora» con «Fútbol 5 · Sede Morón · 21:00 – 22:00»."""
    return Aviso(
        titulo="Tu reserva es en 1 hora",
        cuerpo=f"{tipo_corto(r.deporte, r.tipo)} · {r.sede} · {_hora(r.inicio)} – {_hora(r.fin)}",
        datos={"tipo": "recordatorio", "reserva_id": str(r.reserva_id)},
    )
