import logging
import os
from collections.abc import Sequence
from functools import cache

import firebase_admin
from firebase_admin import credentials, messaging

from app.aplicacion.notificaciones import CanalPush, ResultadoDeEnvio
from app.dominio.notificaciones import Aviso

_registro = logging.getLogger(__name__)


class CanalNulo:
    """No sale a ninguna red: es el canal cuando el entorno no trae credenciales de Firebase."""

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        _registro.info("aviso sin canal push: %s a %d dispositivos", aviso.titulo, len(tokens))
        return ResultadoDeEnvio(enviados=len(tokens))


class CanalFcm:
    """Firebase Cloud Messaging con las credenciales por defecto del entorno."""

    def __init__(self) -> None:
        self._app = firebase_admin.initialize_app(credentials.ApplicationDefault(), name="push")

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        mensaje = messaging.MulticastMessage(
            tokens=list(tokens),
            notification=messaging.Notification(title=aviso.titulo, body=aviso.cuerpo),
            data=aviso.datos,
        )
        respuesta = messaging.send_each_for_multicast(mensaje, app=self._app)
        invalidos = tuple(
            token
            for token, r in zip(tokens, respuesta.responses, strict=True)
            if not r.success and isinstance(r.exception, messaging.UnregisteredError)
        )
        return ResultadoDeEnvio(enviados=respuesta.success_count, invalidos=invalidos)


@cache
def canal_push() -> CanalPush:
    """El de Firebase sólo si el entorno trae credenciales; si no, el que no envía."""
    if os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        return CanalFcm()
    return CanalNulo()
