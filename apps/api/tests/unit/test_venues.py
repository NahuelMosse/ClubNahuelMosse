from dataclasses import replace
from datetime import date, time
from typing import Any
from uuid import UUID

import pytest

from app.modules.session.profile import Profile, Role
from app.modules.venues.rules import NewVenue, Venue, VenueData, validate_venue
from app.modules.venues.use_cases import create_venue
from app.shared.errors import Forbidden, InvalidData

VALID = VenueData(
    name="Sede Haedo",
    address="Av. Vergara 1850",
    opens_at=time(8),
    closes_at=time(23),
    open_days=(1, 2, 3, 4, 5, 6, 7),
)

_FIELDS = {
    "name": "name",
    "address": "address",
    "opening": "opens_at",
    "closing": "closes_at",
    "days": "open_days",
}


def _errors(**changes: Any) -> dict[str, str]:
    venue, errors = validate_venue(replace(VALID, **{_FIELDS[k]: v for k, v in changes.items()}))
    assert venue is None
    return errors


def test_a_complete_venue_splits_street_and_number() -> None:
    venue, errors = validate_venue(replace(VALID, name="  Sede   Haedo ", open_days=(7, 1, 1)))
    assert errors == {}
    assert venue == NewVenue(
        name="Sede Haedo",
        street="Av. Vergara",
        street_number=1850,
        opens_at=time(8),
        closes_at=time(23),
        open_days=(1, 7),
    )


def test_each_empty_field_has_its_message() -> None:
    assert _errors(name=" ", address="", opening=None, closing=None, days=()) == {
        "name": "The name is required",
        "address": "The address is required",
        "opens_at": "The opening time is required",
        "closes_at": "The closing time is required",
        "open_days": "Choose the days it opens",
    }


@pytest.mark.parametrize("address", ["Av. Vergara", "1850", "Vergara 0", "Vergara 18a"])
def test_the_address_ends_in_the_number(address: str) -> None:
    assert _errors(address=address) == {"address": "Write the street and the number"}


def test_the_lengths_are_capped() -> None:
    assert _errors(name="x" * 61, address="y" * 76 + " 1850") == {
        "name": "Use up to 60 characters",
        "address": "Use up to 80 characters",
    }
    venue, _ = validate_venue(replace(VALID, name="x" * 60, address="y" * 75 + " 1850"))
    assert venue is not None


def test_the_closing_comes_after_the_opening() -> None:
    message = {"closes_at": "The closing must be after the opening"}
    assert _errors(opening=time(10), closing=time(9)) == message
    assert _errors(opening=time(10), closing=time(10)) == message


def test_closing_at_00_is_midnight() -> None:
    venue, errors = validate_venue(replace(VALID, opens_at=time(18), closes_at=time(0)))
    assert errors == {}
    assert venue is not None


def test_the_hours_are_on_the_hour() -> None:
    assert _errors(opening=time(8, 30), closing=time(22, 15)) == {
        "opens_at": "Choose an on-the-hour time",
        "closes_at": "Choose an on-the-hour time",
    }


def test_the_days_are_days_of_the_week() -> None:
    assert _errors(days=(0, 1)) == {"open_days": "Choose the days it opens"}
    assert _errors(days=(8,)) == {"open_days": "Choose the days it opens"}


def _profile(role: Role) -> Profile:
    return Profile(
        id=UUID(int=7),
        uid="uid",
        first_name="Ana",
        last_name="Díaz",
        email="ana@club.com",
        role=role,
        dni="20000001",
        birth_date=date(1985, 6, 1),
    )


class _InMemoryVenues:
    def __init__(self) -> None:
        self.saved: list[tuple[NewVenue, UUID]] = []

    def active(self) -> list[Venue]:
        return []

    def insert(self, new: NewVenue, author: UUID) -> Venue:
        self.saved.append((new, author))
        return Venue(UUID(int=1), new.name, new.street, new.street_number, new.opens_at,
                     new.closes_at, new.open_days, 0)  # fmt: skip

    def update(self, venue_id: UUID, data: NewVenue, author: UUID, *, confirm: bool) -> Venue:
        raise NotImplementedError

    def deactivate(self, venue_id: UUID, author: UUID) -> None:
        raise NotImplementedError


def test_the_creation_is_made_in_the_administrators_name() -> None:
    venues = _InMemoryVenues()
    venue = create_venue(_profile("admin"), VALID, venues)
    assert venue.name == "Sede Haedo"
    assert [author for _, author in venues.saved] == [UUID(int=7)]


def test_a_user_does_not_create_venues() -> None:
    venues = _InMemoryVenues()
    with pytest.raises(Forbidden):
        create_venue(_profile("user"), VALID, venues)
    assert venues.saved == []


def test_with_invalid_data_nothing_is_saved() -> None:
    venues = _InMemoryVenues()
    with pytest.raises(InvalidData) as e:
        create_venue(_profile("admin"), replace(VALID, address=""), venues)
    assert e.value.errors == {"address": "The address is required"}
    assert venues.saved == []


def test_the_number_is_made_of_ordinary_digits() -> None:
    assert _errors(address="Calle ١٢٣") == {"address": "Write the street and the number"}


def test_name_and_street_must_contribute_to_the_space_names() -> None:
    assert _errors(name="Sede") == {"name": "Write the venue name"}
    assert _errors(address="Av. 100") == {"address": "Write the street and the number"}
