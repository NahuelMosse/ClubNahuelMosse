from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Literal, Protocol

from app.dominio.espacios import CATALOGO
from app.dominio.reservas import Reserva
from app.dominio.zona import ZONA_CLUB

TipoDeAviso = Literal["recordatorio", "cancelacion_forzosa", "cancelacion_usuario"]
Envio = Literal["pendiente", "enviando", "enviada", "sin_permiso", "sin_canal", "fallida"]

ANTICIPACION = timedelta(hours=1)
DIAS = ("Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom")


@dataclass(frozen=True)
class Aviso:
    """Lo que se le dice a la persona y los datos con que la app sabe adónde llevarla."""

    titulo: str
    cuerpo: str
    datos: dict[str, str]


@dataclass(frozen=True)
class Pendiente:
    """Un aviso ya registrado en el centro que todavía no salió hacia el teléfono."""

    notificacion_id: int
    usuario_id: int
    aviso: Aviso


@dataclass(frozen=True)
class ResultadoDeEnvio:
    """Cuántos dispositivos aceptó el servicio y qué tokens rechazó por inválidos."""

    enviados: int
    invalidos: tuple[str, ...] = ()


class CanalNoConfigurado(Exception):
    """No hay un servicio de notificaciones configurado: nada salió hacia el teléfono."""


class CanalPush(Protocol):
    """El servicio que entrega el aviso al teléfono."""

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        """Lanza `CanalNoConfigurado` si no hay servicio al que enviarle el aviso."""
        ...


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


@dataclass(frozen=True)
class ReservaAnulada:
    """Una reserva que el club canceló, con lo que hace falta para avisárselo a quien la hizo."""

    reserva_id: int
    inicio: datetime
    deporte: str
    tipo: str
    sede: str
    motivo: str


# Cuánto del motivo entra en el aviso: el resto se lee en el historial.
LIMITE_DEL_MOTIVO = 200

# Un aviso `enviando` hace más que esto se da por varado: el proceso que lo tomó se cayó.
TOMA_VENCIDA = timedelta(minutes=5)
# Cuántas veces se toma un aviso antes de darlo por fallido.
INTENTOS_MAXIMOS = 3
# Un recordatorio recién registrado lo está enviando quien lo registró: el despacho lo toma
# sólo si pasó más que esto sin salir.
ESPERA_DEL_RECORDATORIO = timedelta(minutes=1)

DestinoDelVarado = Literal["reintentar", "dar_por_fallido"]


@dataclass(frozen=True)
class AvisoPerdido:
    """Un aviso que se dio por fallido sin haber salido: lo que hace falta para el log."""

    notificacion_id: int
    tipo: TipoDeAviso


def que_hacer_con_varado(tipo: TipoDeAviso, intentos: int) -> DestinoDelVarado:
    """Qué se hace con un aviso que quedó `enviando` sin que se sepa si salió.

    Un recordatorio no se repite (el CU lo fija: «se envía una sola vez»). Uno de cancelación sí,
    porque la persona no puede perdérselo, hasta [INTENTOS_MAXIMOS] veces.
    """
    if tipo == "recordatorio" or intentos >= INTENTOS_MAXIMOS:
        return "dar_por_fallido"
    return "reintentar"


def tipo_corto(deporte: str, tipo: str) -> str:
    """«Fútbol 5»; sólo «Tenis» si el tipo no nombra al deporte («Polvo de ladrillo»)."""
    d = next((d for d in CATALOGO if d.clave == deporte), None)
    t = None if d is None else next((t for t in d.tipos if t.clave == tipo), None)
    if d is None or t is None:
        return deporte
    return t.nombre if t.nombre.startswith(d.nombre) else d.nombre


def _hora(momento: datetime) -> str:
    return momento.astimezone(ZONA_CLUB).strftime("%H:%M")


def mensaje_recordatorio(r: Recordatorio) -> Aviso:
    """«Tu reserva es en 1 hora» con «Fútbol 5 · Sede Morón · 21:00 – 22:00»."""
    return Aviso(
        titulo="Tu reserva es en 1 hora",
        cuerpo=f"{tipo_corto(r.deporte, r.tipo)} · {r.sede} · {_hora(r.inicio)} – {_hora(r.fin)}",
        datos=datos_del_aviso("recordatorio", r.reserva_id),
    )


def datos_del_aviso(tipo: TipoDeAviso, reserva_id: int | None) -> dict[str, str]:
    """Con qué datos la app sabe adónde llevar a la persona al tocar el aviso."""
    return {"tipo": tipo} | ({} if reserva_id is None else {"reserva_id": str(reserva_id)})


def _cuando(momento: datetime) -> str:
    """«Mié 11, 20:00», en la hora del club."""
    local = momento.astimezone(ZONA_CLUB)
    return f"{DIAS[local.weekday()]} {local.day}, {_hora(local)}"


def mensaje_cancelacion(r: Reserva) -> Aviso:
    """«Reserva cancelada» con «Fútbol 5 · Sede Morón · Mié 11, 20:00. El horario quedó
    liberado.», en la hora del club."""
    return Aviso(
        titulo="Reserva cancelada",
        cuerpo=(
            f"{tipo_corto(r.deporte, r.tipo)} · {r.sede} · {_cuando(r.inicio)}. "
            "El horario quedó liberado."
        ),
        datos=datos_del_aviso("cancelacion_usuario", r.id),
    )


def mensaje_cancelacion_forzosa(anuladas: Sequence[ReservaAnulada]) -> Aviso:
    """«El club anuló tu reserva» con la reserva y el motivo; con varias, sólo cuántas son y
    sin apuntar a una en particular."""
    if len(anuladas) == 1:
        r = anuladas[0]
        motivo = r.motivo.strip()
        if len(motivo) > LIMITE_DEL_MOTIVO:
            motivo = motivo[: LIMITE_DEL_MOTIVO - 1].rstrip() + "…"
        return Aviso(
            titulo="El club anuló tu reserva",
            cuerpo=(
                f"{tipo_corto(r.deporte, r.tipo)} · {r.sede} · {_cuando(r.inicio)}. "
                f"Motivo: {motivo}."
            ),
            datos=datos_del_aviso("cancelacion_forzosa", r.reserva_id),
        )
    return mensaje_cancelaciones_forzosas(len(anuladas))


def mensaje_cancelaciones_forzosas(cantidad: int) -> Aviso:
    """El aviso de [cantidad] reservas anuladas por el club, que lleva al historial."""
    return Aviso(
        titulo=f"El club anuló {cantidad} de tus reservas",
        cuerpo=f"Tenés {cantidad} reservas anuladas por el club. Mirá el detalle en tu historial.",
        datos=datos_del_aviso("cancelacion_forzosa", None),
    )
