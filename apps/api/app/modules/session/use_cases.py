from typing import Protocol

from app.modules.session.profile import Profile
from app.shared.errors import NotAuthenticated


class TokenVerifier(Protocol):
    def uid_from_token(self, token: str) -> str | None:
        """The account's uid if the token is valid and has not expired; otherwise None."""
        ...


class ActiveProfiles(Protocol):
    def active_profile(self, uid: str) -> Profile | None: ...


def authenticated_profile(
    token: str | None, identity: TokenVerifier, users: ActiveProfiles
) -> Profile:
    """The profile of the requester; an account without an active profile is not authenticated."""
    uid = identity.uid_from_token(token) if token else None
    profile = users.active_profile(uid) if uid else None
    if profile is None:
        raise NotAuthenticated
    return profile
