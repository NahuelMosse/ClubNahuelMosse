# kit-shape: the profile repository contract and the use case that uses it are read together
from datetime import date
from typing import Protocol
from uuid import UUID

from app.modules.session import Profile
from app.modules.users.rules import EditedProfile, PersonalData, validate_edit
from app.shared.errors import InvalidData


class EditableProfiles(Protocol):
    def update(self, user_id: UUID, edited: EditedProfile) -> None:
        """Raises `Duplicate(["dni"])` if another active account already has that DNI."""
        ...


def update_profile(
    profile: Profile, data: PersonalData, today: date, users: EditableProfiles
) -> None:
    """Saves the personal data of whoever holds the session. The email is not touched (RF 2)."""
    edited, errors = validate_edit(data, today)
    if edited is None:
        raise InvalidData(errors)
    users.update(profile.id, edited)
