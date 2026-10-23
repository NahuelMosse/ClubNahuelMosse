import logging
import os
from collections.abc import Sequence
from functools import cache

import firebase_admin
from firebase_admin import credentials, exceptions, messaging

from app.config import config
from app.dominio.notificaciones import Aviso, CanalNoConfigurado, CanalPush, ResultadoDeEnvio
from app.infraestructura.credencial_firebase import credencial_de_servicio

_registro = logging.getLogger(__name__)


class CanalNulo:
    """El canal cuando el entorno no trae credenciales de Firebase: no sale a ninguna red, y el
    aviso queda registrado como «sin canal» en vez de como enviado."""

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        _registro.info("aviso sin canal push: %s a %d dispositivos", aviso.titulo, len(tokens))
        raise CanalNoConfigurado("no hay credenciales de Firebase en el entorno")


# Lo que FCM contesta cuando el token ya no sirve: desinstalado, de otro proyecto o mal formado.
_TOKEN_INVALIDO = (
    messaging.UnregisteredError,
    messaging.SenderIdMismatchError,
    exceptions.InvalidArgumentError,
)


def _clave_de_reemplazo(aviso: Aviso) -> str | None:
    """Con qué clave el sistema reemplaza en la bandeja el aviso anterior. Un aviso de anulación
    agrupado sale con un id nuevo y tiene que tomar el lugar del que ya estaba, así que la
    clave es estable por persona (los tokens son de una sola) y por tipo."""
    return "cancelacion_forzosa" if aviso.datos.get("tipo") == "cancelacion_forzosa" else None


def armar_mensaje(tokens: Sequence[str], aviso: Aviso) -> messaging.MulticastMessage:
    clave = _clave_de_reemplazo(aviso)
    return messaging.MulticastMessage(
        tokens=list(tokens),
        notification=messaging.Notification(title=aviso.titulo, body=aviso.cuerpo),
        data=aviso.datos,
        android=None
        if clave is None
        else messaging.AndroidConfig(
            collapse_key=clave, notification=messaging.AndroidNotification(tag=clave)
        ),
        apns=None if clave is None else messaging.APNSConfig(headers={"apns-collapse-id": clave}),
    )


class CanalFcm:
    """Firebase Cloud Messaging con las credenciales por defecto del entorno."""

    def __init__(self) -> None:
        self._app = firebase_admin.initialize_app(
            credencial_de_servicio() or credentials.ApplicationDefault(),
            options={"httpTimeout": 10},
            name="push",
        )

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        respuesta = messaging.send_each_for_multicast(armar_mensaje(tokens, aviso), app=self._app)
        invalidos: list[str] = []
        for token, r in zip(tokens, respuesta.responses, strict=True):
            if r.success:
                continue
            # Sólo el tipo del error: su texto puede traer el token.
            _registro.warning("FCM rechazó un envío: %s", type(r.exception).__name__)
            if isinstance(r.exception, _TOKEN_INVALIDO):
                invalidos.append(token)
        return ResultadoDeEnvio(enviados=respuesta.success_count, invalidos=tuple(invalidos))


@cache
def canal_push() -> CanalPush:
    """El de Firebase sólo si el entorno trae credenciales; si no, el que no envía."""
    if config.firebase_credenciales_json or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        return CanalFcm()
    return CanalNulo()
