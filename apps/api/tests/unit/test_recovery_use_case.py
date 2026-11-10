from uuid import UUID

import pytest

from app.modules.password_recovery.rules import ClaimedLink, Recipient
from app.modules.password_recovery.use_cases import (
    MAX_PER_HOUR,
    VALIDITY_MINUTES,
    InvalidLink,
    hash_of,
    request_link,
    use_link,
)
from app.shared.errors import InvalidData

LUCIA = Recipient(UUID(int=7), "Lucía", "lucia@correo.com")
URL = "https://api.club.com/"


class Links:
    def __init__(self, issued: int = 0, active: set[str] | None = None) -> None:
        self.issued = issued
        self.issuances: list[tuple[UUID, str, int]] = []
        self.active = active or set()
        self.released: list[UUID] = []

    def recipient(self, email: str) -> Recipient | None:
        return LUCIA if email == LUCIA.email else None

    def issue(
        self, user_id: UUID, code_hash: str, validity_minutes: int, max_per_hour: int
    ) -> bool:
        if self.issued >= max_per_hour:
            return False
        self.issuances.append((user_id, code_hash, validity_minutes))
        return True

    def valid(self, code_hash: str) -> bool:
        return code_hash in self.active

    def claim(self, code_hash: str) -> ClaimedLink | None:
        if code_hash not in self.active:
            return None
        self.active.discard(code_hash)
        return ClaimedLink(id=UUID(int=3), user_id=UUID(int=7), uid="u7")

    def release(self, link_id: UUID) -> None:
        self.released.append(link_id)


class Identity:
    def __init__(self, fails: bool = False) -> None:
        self.changes: list[tuple[str, str]] = []
        self.fails = fails

    def change_password(self, uid: str, new_password: str) -> None:
        if self.fails:
            raise RuntimeError("Firebase does not answer")
        self.changes.append((uid, new_password))


class Trail:
    def __init__(self) -> None:
        self.marked: list[UUID] = []

    def mark_password_changed(self, user_id: UUID) -> None:
        self.marked.append(user_id)


def test_an_active_account_gets_an_https_link_that_expires_in_half_an_hour() -> None:
    links = Links()
    message = request_link("  Lucia@Correo.com ", URL, links)
    assert message is not None
    ((user, code_hash, validity),) = links.issuances
    assert (user, validity) == (UUID(int=7), VALIDITY_MINUTES)
    assert message.recipient == "lucia@correo.com"
    assert "https://api.club.com/link/recover#code=" in message.body
    code = message.body.split("#code=")[1].split()[0]
    # The email carries the code and the database keeps only its hash.
    assert hash_of(code) == code_hash and code != code_hash


def test_an_email_without_an_account_receives_nothing_and_gives_no_error() -> None:
    links = Links()
    assert request_link("nadie@correo.com", URL, links) is None
    assert links.issuances == []


def test_after_the_hourly_cap_no_more_are_sent() -> None:
    """Verifies CU-04b-SUP-02."""
    links = Links(issued=MAX_PER_HOUR)
    assert request_link(LUCIA.email, URL, links) is None
    assert links.issuances == []


def test_a_misspelled_email_is_rejected() -> None:
    with pytest.raises(InvalidData) as error:
        request_link("lucia@correo", URL, Links())
    assert error.value.errors == {"email": "Check the email format"}


def test_with_an_active_link_it_changes_the_password_and_leaves_a_trail() -> None:
    links, identity, trail = Links(active={hash_of("abc")}), Identity(), Trail()
    use_link("abc", "ClubNahuel2", links, identity, trail)
    assert identity.changes == [("u7", "ClubNahuel2")]
    assert trail.marked == [UUID(int=7)]
    # The link no longer works a second time.
    with pytest.raises(InvalidLink):
        use_link("abc", "ClubNahuel3", links, identity, trail)


def test_if_firebase_fails_the_link_is_released() -> None:
    links = Links(active={hash_of("abc")})
    with pytest.raises(RuntimeError):
        use_link("abc", "ClubNahuel2", links, Identity(fails=True), Trail())
    assert links.released == [UUID(int=3)]


def test_a_weak_password_does_not_spend_the_link() -> None:
    links = Links(active={hash_of("abc")})
    with pytest.raises(InvalidData) as error:
        use_link("abc", "corta", links, Identity(), Trail())
    assert error.value.errors == {"new_password": "At least 8 characters"}
    assert hash_of("abc") in links.active
