# kit-shape: the admin repository contract and the function that uses it are read together
from datetime import date
from typing import Protocol
from uuid import UUID

from app.modules.users.registration import IdentityProvider, UserRepository, register
from app.modules.users.rules import RegistrationData, normalize_email
from app.shared.errors import AccountExists


class AdminRepository(UserRepository, Protocol):
    def active_id_by_email(self, email: str) -> UUID | None: ...

    def make_admin(self, user_id: UUID) -> None: ...


def seed_admin(  # noqa: PLR0913 -- public signature fixed by its callers
    data: RegistrationData,
    today: date,
    identity: IdentityProvider,
    users: AdminRepository,
    *,
    promote: bool = False,
) -> UUID:
    """Creates an admin account with that data, or promotes the one that already exists.

    The role is not chosen at login: it comes from the account, and the first one is seeded
    this way. Promoting an existing account keeps its password, so it is only done on request:
    registration is public and anyone could have created one with that email.
    """
    existing = users.active_id_by_email(normalize_email(data.email))
    if existing is not None and not promote:
        raise AccountExists
    user_id = existing if existing is not None else register(data, today, identity, users)
    users.make_admin(user_id)
    return user_id
