import logging
import os
from collections.abc import Sequence
from functools import cache

import firebase_admin
from firebase_admin import credentials, exceptions, messaging

from app.modules.notifications.rules import (
    ChannelNotConfigured,
    DeliveryResult,
    Notice,
    PushChannel,
)
from app.shared.config import config
from app.shared.firebase_credential import service_credential

_log = logging.getLogger(__name__)


class NullChannel:
    """The channel when the environment has no Firebase credentials: it reaches no network, and
    the notice is registered as `sin_canal` instead of as sent."""

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        _log.info("aviso sin canal push: %s a %d dispositivos", notice.title, len(tokens))
        raise ChannelNotConfigured("no hay credenciales de Firebase en el entorno")


# What FCM answers when the token is no longer valid: uninstalled, from another project or malformed.
_INVALID_TOKEN = (
    messaging.UnregisteredError,
    messaging.SenderIdMismatchError,
    exceptions.InvalidArgumentError,
)


def _replacement_key(notice: Notice) -> str | None:
    """The key the system uses to replace the previous notice in the tray. A grouped voiding
    notice goes out with a new id and has to take the place of the one already there, so the
    key is stable per person (the tokens belong to one) and per kind."""
    return "cancelacion_forzosa" if notice.data.get("tipo") == "cancelacion_forzosa" else None


def build_message(tokens: Sequence[str], notice: Notice) -> messaging.MulticastMessage:
    key = _replacement_key(notice)
    return messaging.MulticastMessage(
        tokens=list(tokens),
        notification=messaging.Notification(title=notice.title, body=notice.body),
        data=notice.data,
        android=None
        if key is None
        else messaging.AndroidConfig(
            collapse_key=key, notification=messaging.AndroidNotification(tag=key)
        ),
        apns=None if key is None else messaging.APNSConfig(headers={"apns-collapse-id": key}),
    )


class FcmChannel:
    """Firebase Cloud Messaging with the default credentials of the environment."""

    def __init__(self) -> None:
        self._app = firebase_admin.initialize_app(
            service_credential() or credentials.ApplicationDefault(),
            options={"httpTimeout": 10},
            name="push",
        )

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        response = messaging.send_each_for_multicast(build_message(tokens, notice), app=self._app)
        invalid: list[str] = []
        for token, r in zip(tokens, response.responses, strict=True):
            if r.success:
                continue
            # Only the error type: its text may carry the token.
            _log.warning("FCM rechazó un envío: %s", type(r.exception).__name__)
            if isinstance(r.exception, _INVALID_TOKEN):
                invalid.append(token)
        return DeliveryResult(sent=response.success_count, invalid=tuple(invalid))


@cache
def push_channel() -> PushChannel:
    """Firebase only if the environment has credentials; otherwise, the one that does not send."""
    if config.firebase_credentials_json or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        return FcmChannel()
    return NullChannel()
