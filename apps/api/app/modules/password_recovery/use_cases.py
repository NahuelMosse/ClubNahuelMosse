# kit-shape: the recovery contracts and the use cases that use them are read together
"""Recover the password with a single-use link that arrives by email.

The response to whoever requests the link is always the same, whether or not the email has an
account: saying it does not exist would reveal which addresses are registered.
"""

import hashlib
import logging
import secrets
from typing import Protocol
from uuid import UUID

from app.modules.password_recovery.rules import ClaimedLink, Recipient
from app.modules.password_recovery.rules import Message as Message
from app.modules.users import normalize_email, password_problems, valid_email
from app.shared.errors import InvalidData

VALIDITY_MINUTES = 30
MAX_PER_HOUR = 3
recovery_log = logging.getLogger("clubnahuelmosse.recuperacion")


class InvalidLink(Exception):
    """The link does not exist, expired, was already used or was replaced."""


class LinkRepository(Protocol):
    def recipient(self, email: str) -> Recipient | None:
        """The active account with that email."""
        ...

    def issue(
        self, user_id: UUID, code_hash: str, validity_minutes: int, max_per_hour: int
    ) -> bool:
        """Invalidates the account's links and stores the new one, unless it already issued
        `max_per_hour` in the last hour. Two simultaneous requests of the same account are
        ordered: there are never two valid links."""
        ...

    def valid(self, code_hash: str) -> bool: ...

    def claim(self, code_hash: str) -> ClaimedLink | None:
        """Marks the link as used if it is still valid; of two simultaneous requests one wins."""
        ...

    def release(self, link_id: UUID) -> None: ...


class PasswordChange(Protocol):
    def change_password(self, uid: str, new_password: str) -> None: ...


class PasswordTrace(Protocol):
    def mark_password_changed(self, user_id: UUID) -> None: ...


def hash_of(code: str) -> str:
    return hashlib.sha256(code.encode()).hexdigest()


def request_link(email: str, public_url: str, links: LinkRepository) -> Message | None:
    """The email with the link, if the email belongs to an active account that did not ask too much.

    The caller sends it outside the request: the response time does not reveal whether there is
    an account.
    """
    email = normalize_email(email)
    if not valid_email(email):
        raise InvalidData({"correo": "Revisá el formato del correo"})
    recipient = links.recipient(email)
    if recipient is None:
        return None
    code = secrets.token_urlsafe(32)
    if not links.issue(recipient.id, hash_of(code), VALIDITY_MINUTES, MAX_PER_HOUR):
        return None
    # The code goes after the "#": the browser does not send it to the server, so it does not
    # end up in any request log.
    link = f"{public_url.rstrip('/')}/enlace/recuperar#codigo={code}"
    return Message(
        recipient=recipient.email,
        subject="Creá una contraseña nueva",
        body=(
            f"Hola {recipient.first_name}:\n\n"
            "Para crear una contraseña nueva, abrí este enlace desde tu teléfono:\n"
            f"{link}\n\n"
            f"El enlace vence en {VALIDITY_MINUTES} minutos y sirve una sola vez. Si no lo "
            "pediste, ignorá este correo: tu contraseña no cambia."
        ),
    )


def link_is_valid(code: str, links: LinkRepository) -> bool:
    return links.valid(hash_of(code))


def use_link(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    code: str,
    new: str,
    links: LinkRepository,
    identity: PasswordChange,
    users: PasswordTrace,
) -> None:
    """Creates the new password with the link, which stops being valid."""
    if missing := password_problems(new):
        raise InvalidData({"nueva": missing[0]})
    claimed = links.claim(hash_of(code))
    if claimed is None:
        raise InvalidLink
    try:
        identity.change_password(claimed.uid, new)
    except BaseException:
        # The password did not change: the link is valid again to retry, unless a resend
        # replaced it in the meantime.
        links.release(claimed.id)
        raise
    try:
        # With the change date, the other links issued before stop being valid.
        users.mark_password_changed(claimed.user_id)
    except Exception:
        recovery_log.exception(
            "no se pudo registrar el cambio de contraseña de %s", claimed.user_id
        )
