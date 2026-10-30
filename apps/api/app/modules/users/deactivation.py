# kit-shape: the deactivation contracts and the use case that uses them are read together
import logging
from typing import Protocol
from uuid import UUID

from app.modules.session import Profile
from app.shared.errors import Forbidden

deactivation_log = logging.getLogger("clubnahuelmosse.baja")


class DeactivatableAccounts(Protocol):
    def deactivate(self, user_id: UUID) -> bool:
        """Soft delete: the account stops being active and its bookings that have not started
        yet become canceled by it. All in one transaction. Returns False if the account was
        already deactivated."""
        ...


class ProviderAccounts(Protocol):
    def delete_account(self, uid: str) -> None: ...


def deactivate(profile: Profile, users: DeactivatableAccounts, identity: ProviderAccounts) -> None:
    """Deactivates the account of whoever holds the session. The history stays in the database."""
    if profile.role != "user":
        raise Forbidden("an administrator cannot be deleted from the app")
    if not users.deactivate(profile.id):
        return
    # The deactivation is done: without an active profile, no token of that account passes the
    # API. Deleting it from the provider frees the email; if that fails, registration replaces it.
    try:
        identity.delete_account(profile.uid)
    except Exception:
        deactivation_log.exception("could not delete account %s from the provider", profile.id)
