from datetime import date
from uuid import UUID

import pytest

from app.modules.session.profile import Profile
from app.modules.session.use_cases import authenticated_profile
from app.shared.errors import NotAuthenticated

PROFILE = Profile(
    id=UUID(int=7),
    uid="u",
    first_name="Lucía",
    last_name="Gómez",
    email="lucia@correo.com",
    role="usuario",
    dni="30111222",
    birth_date=date(1998, 11, 2),
)


class Tokens:
    def __init__(self, valid: dict[str, str]) -> None:
        self.valid = valid
        self.queried: list[str] = []

    def uid_from_token(self, token: str) -> str | None:
        self.queried.append(token)
        return self.valid.get(token)


class Profiles:
    def __init__(self, active: dict[str, Profile]) -> None:
        self.active = active

    def active_profile(self, uid: str) -> Profile | None:
        return self.active.get(uid)


def test_a_valid_token_of_an_active_account_gives_its_profile() -> None:
    assert authenticated_profile("t", Tokens({"t": "u"}), Profiles({"u": PROFILE})) == PROFILE


@pytest.mark.parametrize("token", [None, ""])
def test_without_a_token_the_provider_is_not_queried(token: str | None) -> None:
    tokens = Tokens({})
    with pytest.raises(NotAuthenticated):
        authenticated_profile(token, tokens, Profiles({}))
    assert tokens.queried == []


def test_an_invalid_token_does_not_authenticate() -> None:
    with pytest.raises(NotAuthenticated):
        authenticated_profile("vencido", Tokens({}), Profiles({"u": PROFILE}))


def test_an_account_without_an_active_profile_does_not_authenticate() -> None:
    with pytest.raises(NotAuthenticated):
        authenticated_profile("t", Tokens({"t": "u"}), Profiles({}))
