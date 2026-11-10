from datetime import date
from uuid import UUID

import pytest

from app.modules.session.profile import Profile
from app.modules.users.profile import update_profile
from app.modules.users.rules import EditedProfile, PersonalData
from app.shared.errors import InvalidData

TODAY = date(2026, 9, 27)
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


class Profiles:
    def __init__(self) -> None:
        self.saved: list[tuple[UUID, EditedProfile]] = []

    def update(self, user_id: UUID, edited: EditedProfile) -> None:
        self.saved.append((user_id, edited))


def test_saves_the_normalized_data() -> None:
    profiles = Profiles()
    update_profile(
        PROFILE, PersonalData(" Ana ", " Díaz ", "30.111.223", "1985-06-01"), TODAY, profiles
    )
    assert profiles.saved == [
        (UUID(int=7), EditedProfile("Ana", "Díaz", "30111223", date(1985, 6, 1)))
    ]


@pytest.mark.parametrize(
    ("data", "fields"),
    [
        (PersonalData("", "Díaz", "30111223", "1985-06-01"), {"first_name"}),
        (PersonalData("Ana", "Díaz", "42118", "1985-06-01"), {"dni"}),
        (PersonalData("Ana", "Díaz", "30111223", "2000-13-32"), {"birth_date"}),
        (PersonalData("Ana", "Díaz", "30111223", "2026-09-27"), {"birth_date"}),
        (PersonalData("A" * 61, "Díaz", "30111223", "1985-06-01"), {"first_name"}),
    ],
)
def test_an_invalid_field_saves_nothing(data: PersonalData, fields: set[str]) -> None:
    """Verifies CU-06-SUP-01 and CU-06-SUP-04."""
    profiles = Profiles()
    with pytest.raises(InvalidData) as error:
        update_profile(PROFILE, data, TODAY, profiles)
    assert set(error.value.errors) == fields
    assert profiles.saved == []
