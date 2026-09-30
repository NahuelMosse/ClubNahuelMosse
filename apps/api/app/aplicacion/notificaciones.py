from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime
from typing import Protocol

from app.aplicacion.errores import DatosInvalidos, NoDisponible, NoEncontrada, Prohibido
from app.dominio.notificaciones import (
    Aviso,
    Envio,
    Notificacion,
    Recordatorio,
    mensaje_recordatorio,
)
from app.dominio.usuarios import Perfil

PLATAFORMAS = ("android", "ios")


@dataclass(frozen=True)
class ResultadoDeEnvio:
    """Cuántos dispositivos aceptó el servicio y qué tokens rechazó por inválidos."""

    enviados: int
    invalidos: tuple[str, ...] = ()


class CanalPush(Protocol):
    """El servicio que entrega el aviso al teléfono."""

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio: ...


class Notificaciones(Protocol):
    def vencidos(self, ahora: datetime, usuario_id: int | None) -> list[Recordatorio]:
        """Las reservas activas que empiezan dentro de la hora siguiente a [ahora], hechas o
        modificadas con una hora o más de anticipación y sin aviso para su horario actual."""
        ...

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> int | None:
        """Guarda el aviso en el centro. `None` si ya estaba: otro barrido lo registró."""
        ...

    def tokens_con_permiso(self, usuario_id: int) -> list[str]: ...

    def marcar_envio(self, notificacion_id: int, envio: Envio) -> None: ...

    def dar_de_baja_tokens(self, tokens: Sequence[str]) -> None: ...

    def registrar_dispositivo(
        self, usuario_id: int, token: str, plataforma: str, permiso: bool
    ) -> bool:
        """Deja el dispositivo a nombre de [usuario_id]. `False` si la cuenta ya no está
        activa."""
        ...

    def baja_dispositivo(self, usuario_id: int, token: str) -> None: ...

    def de_usuario(self, usuario_id: int) -> tuple[list[Notificacion], int]:
        """Las últimas notificaciones, de la más nueva a la más vieja, y cuántas hay sin
        leer en total."""
        ...

    def leer(self, usuario_id: int, notificacion_id: int) -> bool:
        """Marca como leída una notificación propia. `False` si no es de [usuario_id]."""
        ...

    def leer_todas(self, usuario_id: int) -> None: ...


def enviar_recordatorios(
    notificaciones: Notificaciones,
    canal: CanalPush,
    ahora: datetime,
    usuario_id: int | None = None,
) -> int:
    """Registra y envía el aviso de una hora antes de cada reserva a la que ya le toca, y
    devuelve cuántos registró.

    El aviso se registra antes de enviarlo: el índice único de la base hace que dos barridos
    al mismo tiempo no lo manden dos veces. Sin ningún dispositivo con permiso queda sólo en
    el centro. Un envío que falla no se reintenta desde acá: queda marcado como fallido.
    """
    registrados = 0
    for recordatorio in notificaciones.vencidos(ahora, usuario_id):
        aviso = mensaje_recordatorio(recordatorio)
        nuevo = notificaciones.registrar(recordatorio, aviso)
        if nuevo is None:
            continue
        registrados += 1
        tokens = notificaciones.tokens_con_permiso(recordatorio.usuario_id)
        if not tokens:
            notificaciones.marcar_envio(nuevo, "sin_permiso")
            continue
        try:
            resultado = canal.enviar(tokens, aviso)
        except Exception:
            # El servicio de afuera puede fallar de cualquier forma; el aviso ya está en el
            # centro y un barrido no puede cortarse por el de una persona.
            notificaciones.marcar_envio(nuevo, "fallida")
            continue
        notificaciones.dar_de_baja_tokens(resultado.invalidos)
        notificaciones.marcar_envio(nuevo, "enviada" if resultado.enviados > 0 else "fallida")
    return registrados


def registrar_dispositivo(
    notificaciones: Notificaciones, perfil: Perfil, token: str, plataforma: str, permiso: bool
) -> None:
    """Registra el teléfono de quien pide, con el permiso que le dio al sistema operativo.

    Lanza `Prohibido` si es administrador, `DatosInvalidos` si falta el token o la plataforma
    no existe y `NoDisponible` si la cuenta ya no está activa.
    """
    if perfil.rol != "usuario":
        raise Prohibido("sólo un usuario recibe avisos")
    errores: dict[str, str] = {}
    if not token.strip():
        errores["token"] = "Este campo es obligatorio"
    if plataforma not in PLATAFORMAS:
        errores["plataforma"] = "Tiene que ser android o ios"
    if errores:
        raise DatosInvalidos(errores)
    if not notificaciones.registrar_dispositivo(perfil.id, token.strip(), plataforma, permiso):
        raise NoDisponible("la cuenta ya no está activa")


def dar_de_baja_dispositivo(notificaciones: Notificaciones, perfil: Perfil, token: str) -> None:
    """Al cerrar la sesión, el teléfono deja de recibir los avisos de esta cuenta."""
    notificaciones.baja_dispositivo(perfil.id, token.strip())


def mis_notificaciones(
    notificaciones: Notificaciones, perfil: Perfil
) -> tuple[list[Notificacion], int]:
    return notificaciones.de_usuario(perfil.id)


def marcar_leida(notificaciones: Notificaciones, perfil: Perfil, notificacion_id: int) -> None:
    """Lanza `NoEncontrada` si la notificación no es de quien pide."""
    if not notificaciones.leer(perfil.id, notificacion_id):
        raise NoEncontrada("no hay una notificación suya con ese número")


def marcar_todas(notificaciones: Notificaciones, perfil: Perfil) -> None:
    notificaciones.leer_todas(perfil.id)
