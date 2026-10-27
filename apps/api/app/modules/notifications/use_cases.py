import logging
from datetime import datetime
from uuid import UUID

from app.modules.notifications.rules import ChannelNotConfigured as ChannelNotConfigured
from app.modules.notifications.rules import DeliveryResult as DeliveryResult
from app.modules.notifications.rules import (
    Notice,
    Notification,
    Reminder,
    reminder_email,
    reminder_message,
)
from app.modules.notifications.rules import PendingNotice as PendingNotice
from app.modules.notifications.rules import PushChannel as PushChannel
from app.modules.notifications.store import Notifications
from app.modules.session import Profile
from app.shared.email import send
from app.shared.errors import Forbidden, InvalidData, NotFound, Unavailable

PLATFORMS = ("android", "ios")

_log = logging.getLogger(__name__)


def deliver(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    notifications: Notifications,
    channel: PushChannel,
    notification_id: UUID,
    user_id: UUID,
    notice: Notice,
) -> None:
    """Sends an already registered notice to the phones with permission and records how it went.

    With no device that has permission it stays only in the center: `sin_permiso` if there are
    devices that did not grant it and `sin_canal` if there is none to send it to, same as
    when there is no sending service. A delivery that fails is not retried from here: it is
    marked as failed.
    """
    tokens = notifications.tokens_with_permission(user_id)
    if not tokens:
        has_devices = notifications.has_devices(user_id)
        notifications.mark_delivery(notification_id, "sin_permiso" if has_devices else "sin_canal")
        return
    try:
        result = channel.send(tokens, notice)
    except ChannelNotConfigured:
        notifications.mark_delivery(notification_id, "sin_canal")
        return
    except Exception as e:
        # The outside service can fail in any way; the notice is already in the center and
        # one delivery must not cut off another person's. The error type is logged and not
        # its text, which may carry the phone token.
        _log.error("aviso_sin_enviar notificacion=%s error=%s", notification_id, type(e).__name__)
        notifications.mark_delivery(notification_id, "fallida")
        return
    notifications.deactivate_tokens(result.invalid)
    notifications.mark_delivery(notification_id, "enviada" if result.sent > 0 else "fallida")


def dispatch_pending(
    notifications: Notifications, channel: PushChannel, user_id: UUID | None = None
) -> int:
    """Sends the notices registered together with the fact they report, such as the
    confirmation of a cancellation, and returns how many went out to dispatch.

    Takes one at a time: what was not attempted stays `pendiente`, and a notice that fails
    for any reason becomes `fallida` without cutting the ones that follow. Before taking, the
    ones that will not go out (a reminder that no longer applies, or a notice more than 10
    minutes in `enviando` because the API crashed mid-send) become `fallida`, are not resent
    and are reported in the log as `aviso_sin_enviar`.
    """
    for lost in notifications.fail_stranded(user_id):
        # Only the id and the kind: nothing about the person or the notice text.
        _log.error("aviso_sin_enviar notificacion_id=%s tipo=%s", lost.notification_id, lost.kind)
    dispatched = 0
    while (p := notifications.take_next(user_id)) is not None:
        dispatched += 1
        try:
            deliver(notifications, channel, p.notification_id, p.user_id, p.notice)
        except Exception as e:
            _log.error(
                "aviso_sin_enviar notificacion=%s error=%s", p.notification_id, type(e).__name__
            )
            notifications.mark_delivery(p.notification_id, "fallida")
    return dispatched


def _notify_by_email(reminder: Reminder) -> None:
    """The email stops nothing: the push already went out and the log does not carry the address."""
    if not reminder.email:
        return
    try:
        send(reminder_email(reminder))
    except Exception as e:
        _log.warning("el correo del recordatorio falló: %s", type(e).__name__)


def send_reminders(
    notifications: Notifications,
    channel: PushChannel,
    now: datetime,
    user_id: UUID | None = None,
) -> int:
    """Registers and sends the one-hour-ahead notice of every booking whose time has come, and
    returns how many it registered.

    The notice is registered before sending: the unique index of the database makes two
    simultaneous sweeps not send it twice.
    """
    registered = 0
    for reminder in notifications.due(now, user_id):
        try:
            notice = reminder_message(reminder)
            new_id = notifications.register(reminder, notice)
            if new_id is None:
                continue
            registered += 1
            deliver(notifications, channel, new_id, reminder.user_id, notice)
            _notify_by_email(reminder)
        except Exception as e:
            # One person's reminder does not cut the others.
            _log.warning("el recordatorio falló: %s", type(e).__name__)
    return registered


def register_device(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    notifications: Notifications,
    profile: Profile,
    token: str,
    platform: str,
    permission: bool,  # noqa: FBT001
) -> None:
    """Registers the phone of the requester, with the permission it gave the operating system.

    Raises `Forbidden` for an administrator, `InvalidData` if the token is missing or the
    platform does not exist and `Unavailable` if the account is no longer active.
    """
    if profile.role != "usuario":
        raise Forbidden("sólo un usuario recibe avisos")
    errors: dict[str, str] = {}
    if not token.strip():
        errors["token"] = "Este campo es obligatorio"
    if platform not in PLATFORMS:
        errors["plataforma"] = "Tiene que ser android o ios"
    if errors:
        raise InvalidData(errors)
    if not notifications.register_device(profile.id, token.strip(), platform, permission):
        raise Unavailable("la cuenta ya no está activa")


def deactivate_device(notifications: Notifications, profile: Profile, token: str) -> None:
    """On logout, the phone stops receiving this account's notices."""
    notifications.unregister_device(profile.id, token.strip())


def my_notifications(
    notifications: Notifications, profile: Profile
) -> tuple[list[Notification], int]:
    return notifications.of_user(profile.id)


def mark_read(notifications: Notifications, profile: Profile, notification_id: UUID) -> None:
    """Raises `NotFound` if the notification is not the requester's."""
    if not notifications.read(profile.id, notification_id):
        raise NotFound("no hay una notificación suya con ese número")


def mark_all_read(notifications: Notifications, profile: Profile) -> None:
    notifications.read_all(profile.id)
