from collections.abc import Callable
from dataclasses import replace
from datetime import date
from typing import Any
from uuid import UUID

import pytest

from app.modules.session.profile import Profile, Role
from app.modules.spaces.rules import (
    CATALOG,
    NewSpace,
    Space,
    SpaceChange,
    SpaceData,
    SpaceVenue,
    SuggestedName,
    validate_space,
)
from app.modules.spaces.use_cases import create_space, suggested_name
from app.shared.errors import Forbidden, InvalidData, Unavailable

VALID = SpaceData(
    venue_id=UUID(int=3),
    sport="Futbol",
    kind="F5",
    covered=False,
    lit=True,
    price_per_hour=38000,
)


def _errors(**changes: Any) -> dict[str, str]:
    space, errors = validate_space(replace(VALID, **changes))
    assert space is None
    return errors


def test_a_complete_space_can_be_saved() -> None:
    space, errors = validate_space(VALID)
    assert errors == {}
    assert space == NewSpace(UUID(int=3), VALID.sport, "F5", False, True, 38000)


def test_each_missing_field_is_required() -> None:
    empty = SpaceData(None, "", "", None, None, None)
    _, errors = validate_space(empty)
    assert errors == dict.fromkeys(
        ["venue_id", "sport", "kind", "covered", "lit", "price_per_hour"],
        "This field is required",
    )


def test_sport_and_kind_come_from_the_catalog() -> None:
    assert _errors(sport="Rugby") == {"sport": "Choose a sport from the list"}
    assert _errors(kind="PDL") == {"kind": "Choose a kind from the list"}


@pytest.mark.parametrize("price", [0, -1, 10_000_000])
def test_the_price_is_positive_and_capped(price: int) -> None:
    assert _errors(price_per_hour=price) == {
        "price_per_hour": "Enter a price between $ 1 and $ 9,999,999"
    }


def test_the_catalog_does_not_repeat_keys() -> None:
    keys = [d.key for d in CATALOG]
    assert len(keys) == len(set(keys))
    for d in CATALOG:
        kinds = [t.key for t in d.kinds]
        assert kinds and len(kinds) == len(set(kinds))


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


class _InMemorySpaces:
    def __init__(self, venue: SpaceVenue | None) -> None:
        self.venue = venue
        self.saved: list[tuple[NewSpace, int | None, str, UUID]] = []

    def active(
        self,
        venue_id: UUID | None = None,
        sport: str | None = None,
        kind: str | None = None,
    ) -> list[Space]:
        return []

    def next_number(
        self,
        venue_id: UUID,
        sport: str,
        kind: str,
        name: Callable[[SpaceVenue, int], str],
    ) -> SuggestedName | None:
        return None if self.venue is None else SuggestedName(name(self.venue, 3), 3)

    def insert(
        self,
        new: NewSpace,
        number: int | None,
        name: Callable[[SpaceVenue, int], str],
        author: UUID,
    ) -> Space:
        assert self.venue is not None
        composite = name(self.venue, 3)
        self.saved.append((new, number, composite, author))
        return Space(UUID(int=1), composite, new.venue_id, self.venue.name, new.sport,
                     new.kind, 3, new.covered, new.lit,
                     new.price_per_hour)  # fmt: skip

    def update(self, space_id: UUID, change: SpaceChange, author: UUID) -> Space:
        raise NotImplementedError

    def deactivate(self, space_id: UUID, author: UUID) -> None:
        raise NotImplementedError


MORON = SpaceVenue("Sede Morón", "Av. Rivadavia", 19850)


def test_the_suggested_name_is_the_one_from_the_brief_with_the_next_number() -> None:
    s = suggested_name(_profile("admin"), UUID(int=3), "Futbol", "F5", _InMemorySpaces(MORON))
    assert (s.name, s.number) == ("Moron_Rivadavia_19850_Futbol_F5_3", 3)


def test_without_an_active_venue_there_is_no_name() -> None:
    with pytest.raises(Unavailable):
        suggested_name(_profile("admin"), UUID(int=3), "Futbol", "F5", _InMemorySpaces(None))


def test_the_creation_is_made_in_the_administrators_name_with_the_composite_name() -> None:
    spaces = _InMemorySpaces(MORON)
    space = create_space(_profile("admin"), VALID, 3, spaces)
    assert space.name == "Moron_Rivadavia_19850_Futbol_F5_3"
    assert [(n, a) for _, n, _, a in spaces.saved] == [(3, UUID(int=7))]


def test_a_user_does_not_manage_spaces() -> None:
    spaces = _InMemorySpaces(MORON)
    with pytest.raises(Forbidden):
        create_space(_profile("user"), VALID, None, spaces)
    with pytest.raises(Forbidden):
        suggested_name(_profile("user"), UUID(int=3), "Futbol", "F5", spaces)
    assert spaces.saved == []


def test_with_invalid_data_nothing_is_saved() -> None:
    spaces = _InMemorySpaces(MORON)
    with pytest.raises(InvalidData):
        create_space(_profile("admin"), replace(VALID, kind=""), None, spaces)
    assert spaces.saved == []
