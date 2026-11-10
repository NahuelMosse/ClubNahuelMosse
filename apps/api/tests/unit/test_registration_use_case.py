from datetime import date
from uuid import UUID

import pytest

from app.modules.users.registration import register
from app.modules.users.rules import Registration, RegistrationData
from app.shared.errors import Duplicate

DATA = RegistrationData("Ana", "Pérez", "12345678", "2000-03-14", "ana@correo.com", "ClubNahuel1")
TODAY = date(2026, 11, 12)


class Identity:
    def __init__(self, existing: str | None = None, delete_fails: bool = False) -> None:
        self.accounts: dict[str, str] = {} if existing is None else {"ana@correo.com": existing}
        self.deleted: list[str] = []
        self.delete_fails = delete_fails

    def create_account(self, email: str, password: str) -> str:
        if email in self.accounts:
            raise Duplicate(["correo"])
        self.accounts[email] = f"uid-{len(self.accounts) + len(self.deleted)}"
        return self.accounts[email]

    def uid_of(self, email: str) -> str | None:
        return self.accounts.get(email)

    def delete_account(self, uid: str) -> None:
        if self.delete_fails:
            raise RuntimeError("the provider does not answer")
        self.deleted.append(uid)
        self.accounts = {c: u for c, u in self.accounts.items() if u != uid}


class Users:
    def __init__(self, active: set[str] | None = None, fails: BaseException | None = None) -> None:
        self.active = active or set()
        self.fails = fails
        self.inserted: list[str] = []

    def duplicates(self, email: str, dni: str) -> list[str]:
        return []

    def uid_is_active(self, uid: str) -> bool:
        return uid in self.active

    def insert(self, uid: str, registration: Registration) -> UUID:
        if self.fails is not None:
            raise self.fails
        self.inserted.append(uid)
        return UUID(int=1)


def test_if_the_signup_fails_the_created_account_is_deleted() -> None:
    identity = Identity()
    with pytest.raises(ConnectionError):
        register(DATA, TODAY, identity, Users(fails=ConnectionError("the database dropped")))
    assert identity.deleted == ["uid-0"]


def test_an_error_on_delete_does_not_hide_the_original_error() -> None:
    identity = Identity(delete_fails=True)
    with pytest.raises(Duplicate) as e:
        register(DATA, TODAY, identity, Users(fails=Duplicate(["dni"])))
    assert e.value.fields == ["dni"]


def test_a_provider_account_without_an_active_profile_is_replaced() -> None:
    identity = Identity(existing="uid-viejo")
    users = Users()
    assert register(DATA, TODAY, identity, users) == UUID(int=1)
    assert identity.deleted == ["uid-viejo"]
    assert users.inserted == [identity.accounts["ana@correo.com"]]


def test_an_account_with_an_active_profile_is_still_a_duplicate() -> None:
    identity = Identity(existing="uid-activo")
    with pytest.raises(Duplicate):
        register(DATA, TODAY, identity, Users(active={"uid-activo"}))
    assert identity.deleted == []
