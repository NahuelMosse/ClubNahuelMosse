from datetime import date
from uuid import UUID

import pytest

from app.modules.session.profile import Profile, Role
from app.modules.users.deactivation import deactivate
from app.shared.errors import Forbidden


def _profile(role: Role = "user") -> Profile:
    return Profile(
        id=UUID(int=7),
        uid="u7",
        first_name="Lucía",
        last_name="Gómez",
        email="lucia@correo.com",
        role=role,
        dni="30111222",
        birth_date=date(1998, 11, 2),
    )


class Accounts:
    def __init__(self) -> None:
        self.deactivated: list[UUID] = []
        self.deleted: list[str] = []
        self.provider_fails = False

    def deactivate(self, user_id: UUID) -> bool:
        if user_id in self.deactivated:
            return False
        self.deactivated.append(user_id)
        return True

    def delete_account(self, uid: str) -> None:
        if self.provider_fails:
            raise RuntimeError("Firebase no contesta")
        self.deleted.append(uid)


def test_it_deactivates_and_deletes_the_provider_account() -> None:
    accounts = Accounts()
    deactivate(_profile(), accounts, accounts)
    assert (accounts.deactivated, accounts.deleted) == ([UUID(int=7)], ["u7"])


def test_if_the_provider_fails_the_deactivation_is_still_done(
    caplog: pytest.LogCaptureFixture,
) -> None:
    accounts = Accounts()
    accounts.provider_fails = True
    deactivate(_profile(), accounts, accounts)
    assert accounts.deactivated == [UUID(int=7)]
    assert "could not delete account" in caplog.text


def test_an_account_that_was_already_deactivated_does_not_touch_the_provider() -> None:
    accounts = Accounts()
    deactivate(_profile(), accounts, accounts)
    deactivate(_profile(), accounts, accounts)
    assert (accounts.deactivated, accounts.deleted) == ([UUID(int=7)], ["u7"])


def test_an_administrator_is_not_deactivated() -> None:
    """Verifies CU-07-SUP-03."""
    accounts = Accounts()
    with pytest.raises(Forbidden):
        deactivate(_profile("admin"), accounts, accounts)
    assert accounts.deactivated == []
