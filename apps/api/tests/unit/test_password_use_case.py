from datetime import date
from uuid import UUID

import pytest

from app.modules.session.profile import Profile
from app.modules.users.password import DOES_NOT_MATCH, change_password
from app.shared.errors import InvalidData

PROFILE = Profile(
    id=UUID(int=7),
    uid="u7",
    first_name="Lucía",
    last_name="Gómez",
    email="lucia@correo.com",
    role="user",
    dni="30111222",
    birth_date=date(1998, 11, 2),
)


class Identity:
    def __init__(self, password: str) -> None:
        self.password = password
        self.changes: list[tuple[str, str]] = []

    def password_matches(self, email: str, password: str) -> bool:
        return email == PROFILE.email and password == self.password

    def change_password(self, uid: str, new_password: str) -> None:
        self.changes.append((uid, new_password))


class Trail:
    def __init__(self) -> None:
        self.marked: list[UUID] = []

    def mark_password_changed(self, user_id: UUID) -> None:
        self.marked.append(user_id)


def test_with_the_correct_current_one_it_changes_and_leaves_a_trail() -> None:
    identity, trail = Identity("ClubNahuel1"), Trail()
    change_password(PROFILE, "ClubNahuel1", "ClubNahuel2", identity, trail)
    assert identity.changes == [("u7", "ClubNahuel2")]
    assert trail.marked == [UUID(int=7)]


def test_with_the_wrong_current_one_nothing_changes() -> None:
    identity, trail = Identity("ClubNahuel1"), Trail()
    with pytest.raises(InvalidData) as error:
        change_password(PROFILE, "OtraClave9", "ClubNahuel2", identity, trail)
    assert error.value.errors == {"current_password": DOES_NOT_MATCH}
    assert identity.changes == [] and trail.marked == []


@pytest.mark.parametrize(
    ("new", "message"),
    [
        ("Corta1", "At least 8 characters"),
        ("clubnahuel1", "An uppercase letter"),
        ("ClubNahuel", "At least one number"),
    ],
)
def test_a_new_one_that_breaks_the_rules_is_rejected_before_looking_at_the_current_one(
    new: str, message: str
) -> None:
    identity = Identity("ClubNahuel1")
    with pytest.raises(InvalidData) as error:
        change_password(PROFILE, "equivocada", new, identity, Trail())
    assert error.value.errors == {"new_password": message}


def test_a_new_one_equal_to_the_current_one_is_accepted() -> None:
    """Verifies CU-04-SUP-01."""
    identity = Identity("ClubNahuel1")
    change_password(PROFILE, "ClubNahuel1", "ClubNahuel1", identity, Trail())
    assert identity.changes == [("u7", "ClubNahuel1")]


class FailingTrail:
    def mark_password_changed(self, user_id: UUID) -> None:
        raise RuntimeError("the database does not answer")


def test_if_the_trail_fails_the_change_is_still_reported_as_done(
    caplog: pytest.LogCaptureFixture,
) -> None:
    identity = Identity("ClubNahuel1")
    change_password(PROFILE, "ClubNahuel1", "ClubNahuel2", identity, FailingTrail())
    assert identity.changes == [("u7", "ClubNahuel2")]
    assert "could not record the password change" in caplog.text


def test_without_the_current_one_the_provider_is_not_asked() -> None:
    class WithoutQueries(Identity):
        def password_matches(self, email: str, password: str) -> bool:
            raise AssertionError("it should not query")

    with pytest.raises(InvalidData) as error:
        change_password(PROFILE, "", "ClubNahuel2", WithoutQueries("x"), Trail())
    assert error.value.errors == {"current_password": DOES_NOT_MATCH}
