"""Recuperar la contraseña con un enlace de un solo uso que llega por correo.

La respuesta a quien pide el enlace es siempre la misma, tenga cuenta o no el correo: decir
que no existe permitiría averiguar qué direcciones están registradas.
"""

import hashlib
import logging
import secrets
from typing import Protocol

from app.aplicacion.errores import DatosInvalidos
from app.dominio.recuperacion import Destinatario, EnlaceReclamado
from app.dominio.recuperacion import Mensaje as Mensaje
from app.dominio.usuarios import correo_valido, normalizar_correo, problemas_contrasena

VIGENCIA_MINUTOS = 30
MAXIMO_POR_HORA = 3
recuperacion_log = logging.getLogger("clubnahuelmosse.recuperacion")


class EnlaceInvalido(Exception):
    """El enlace no existe, venció, ya se usó o quedó reemplazado."""


class RepositorioEnlaces(Protocol):
    def destinatario(self, correo: str) -> Destinatario | None:
        """La cuenta activa con ese correo."""
        ...

    def emitir(
        self, usuario_id: int, codigo_hash: str, vigencia_minutos: int, maximo_por_hora: int
    ) -> bool:
        """Invalida los enlaces de la cuenta y guarda el nuevo, salvo que ya haya emitido
        `maximo_por_hora` en la última hora. Dos pedidos a la vez de la misma cuenta se
        ordenan: nunca quedan dos enlaces vigentes."""
        ...

    def vigente(self, codigo_hash: str) -> bool: ...

    def reclamar(self, codigo_hash: str) -> EnlaceReclamado | None:
        """Marca el enlace como usado si sigue vigente; de dos pedidos a la vez gana uno."""
        ...

    def liberar(self, enlace_id: int) -> None: ...


class CambioDeContrasena(Protocol):
    def cambiar_contrasena(self, uid: str, nueva: str) -> None: ...


class RastroDeContrasena(Protocol):
    def marcar_cambio_de_contrasena(self, id_usuario: int) -> None: ...


def hash_de(codigo: str) -> str:
    return hashlib.sha256(codigo.encode()).hexdigest()


def pedir_enlace(correo: str, url_publica: str, enlaces: RepositorioEnlaces) -> Mensaje | None:
    """El correo con el enlace, si el correo es de una cuenta activa que no pidió demasiados.

    Quien llama lo envía fuera del pedido: el tiempo de respuesta no cuenta si hay cuenta.
    """
    correo = normalizar_correo(correo)
    if not correo_valido(correo):
        raise DatosInvalidos({"correo": "Revisá el formato del correo"})
    destinatario = enlaces.destinatario(correo)
    if destinatario is None:
        return None
    codigo = secrets.token_urlsafe(32)
    if not enlaces.emitir(destinatario.id, hash_de(codigo), VIGENCIA_MINUTOS, MAXIMO_POR_HORA):
        return None
    # El código va después del «#»: el navegador no lo manda al servidor, así no queda en
    # ningún registro de pedidos.
    enlace = f"{url_publica.rstrip('/')}/enlace/recuperar#codigo={codigo}"
    return Mensaje(
        para=destinatario.correo,
        asunto="Creá una contraseña nueva",
        cuerpo=(
            f"Hola {destinatario.nombre}:\n\n"
            "Para crear una contraseña nueva, abrí este enlace desde tu teléfono:\n"
            f"{enlace}\n\n"
            f"El enlace vence en {VIGENCIA_MINUTOS} minutos y sirve una sola vez. Si no lo "
            "pediste, ignorá este correo: tu contraseña no cambia."
        ),
    )


def enlace_vigente(codigo: str, enlaces: RepositorioEnlaces) -> bool:
    return enlaces.vigente(hash_de(codigo))


def usar_enlace(
    codigo: str,
    nueva: str,
    enlaces: RepositorioEnlaces,
    identidad: CambioDeContrasena,
    usuarios: RastroDeContrasena,
) -> None:
    """Crea la contraseña nueva con el enlace, que deja de servir."""
    if faltan := problemas_contrasena(nueva):
        raise DatosInvalidos({"nueva": faltan[0]})
    reclamado = enlaces.reclamar(hash_de(codigo))
    if reclamado is None:
        raise EnlaceInvalido
    try:
        identidad.cambiar_contrasena(reclamado.uid, nueva)
    except BaseException:
        # La contraseña no cambió: el enlace vuelve a servir para reintentar, salvo que lo
        # haya reemplazado un reenvío mientras tanto.
        enlaces.liberar(reclamado.id)
        raise
    try:
        # Con la fecha del cambio, los demás enlaces emitidos antes dejan de valer.
        usuarios.marcar_cambio_de_contrasena(reclamado.usuario_id)
    except Exception:
        recuperacion_log.exception(
            "no se pudo registrar el cambio de contraseña de %s", reclamado.usuario_id
        )
