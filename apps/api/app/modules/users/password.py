# kit-shape: the password change contracts and the use case that uses them are read together
import logging
from typing import Protocol
from uuid import UUID

from app.modules.session import Profile
from app.modules.users.rules import password_problems
from app.shared.errors import InvalidData

DOES_NOT_MATCH = "La contraseña actual no coincide"
password_log = logging.getLogger("clubnahuelmosse.contrasena")


class IdentityPasswords(Protocol):
    def password_matches(self, email: str, password: str) -> bool:
        """Raises `RateLimited` if the provider throttles for too many attempts."""
        ...

    def change_password(self, uid: str, new_password: str) -> None:
        """Changes the password and invalidates all the open sessions of the account."""
        ...


class PasswordTrace(Protocol):
    def mark_password_changed(self, user_id: UUID) -> None: ...


def change_password(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    profile: Profile,
    current: str,
    new: str,
    identity: IdentityPasswords,
    users: PasswordTrace,
) -> None:
    """Replaces the password of whoever holds the session, if they confirm the current one."""
    if missing := password_problems(new):
        raise InvalidData({"nueva": missing[0]})
    if not current or not identity.password_matches(profile.email, current):
        raise InvalidData({"actual": DOES_NOT_MATCH})
    identity.change_password(profile.uid, new)
    # The password already changed: if the trace fails, the response must still say it
    # changed, or the person would try to log in with the old one.
    try:
        users.mark_password_changed(profile.id)
    except Exception:
        password_log.exception("no se pudo registrar el cambio de contraseña de %s", profile.id)
