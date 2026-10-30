# kit-shape: the sign-up contracts and the function that uses them are read together
import logging
from datetime import date
from typing import Protocol
from uuid import UUID

from app.modules.users.rules import Registration, RegistrationData, validate_registration
from app.shared.errors import Duplicate, InvalidData

registration_log = logging.getLogger("clubnahuelmosse.registro")


class IdentityProvider(Protocol):
    def create_account(self, email: str, password: str) -> str:
        """Creates the account and returns its uid. Raises `Duplicate(["email"])` if the email
        exists."""
        ...

    def uid_of(self, email: str) -> str | None: ...

    def delete_account(self, uid: str) -> None: ...


class UserRepository(Protocol):
    def duplicates(self, email: str, dni: str) -> list[str]: ...

    def uid_is_active(self, uid: str) -> bool: ...

    def insert(self, uid: str, registration: Registration) -> UUID:
        """Inserts and commits the profile; raises `Duplicate` if email or DNI are rejected."""
        ...


def _create_account(
    registration: Registration, identity: IdentityProvider, users: UserRepository
) -> str:
    try:
        return identity.create_account(registration.email, registration.password)
    except Duplicate:
        # A provider account without an active profile is left over from a sign-up that did not
        # finish or from a deactivation: the email is free in the database, so it is replaced.
        existing = identity.uid_of(registration.email)
        if existing is None or users.uid_is_active(existing):
            raise
        identity.delete_account(existing)
        return identity.create_account(registration.email, registration.password)


def register(
    data: RegistrationData,
    today: date,
    identity: IdentityProvider,
    users: UserRepository,
) -> UUID:
    registration, errors = validate_registration(data, today)
    if registration is None:
        raise InvalidData(errors)

    if repeated := users.duplicates(registration.email, registration.dni):
        raise Duplicate(repeated)

    uid = _create_account(registration, identity, users)
    try:
        return users.insert(uid, registration)
    except BaseException:
        try:
            identity.delete_account(uid)
        except Exception:
            registration_log.exception("no se pudo borrar la cuenta %s del proveedor", uid)
        raise
