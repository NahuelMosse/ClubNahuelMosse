"""Edges of the notice use cases: filter by person, phone registration and reading."""

from collections.abc import Sequence
from datetime import UTC, date, datetime
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import (
    DeliveryResult,
    LostNotice,
    Notice,
    PendingNotice,
    Reminder,
)
from app.modules.session import Profile
from app.shared.errors import Forbidden, InvalidData, NotFound, Unavailable

NOW = datetime(2026, 10, 1, 20, 0, tzinfo=UTC)


class _Notifications:
    """Keeps which person filter it was asked with and answers what it was configured to."""

    def __init__(self, accepts_device: bool = True, owns_notification: bool = True) -> None:
        self.accepts_device = accepts_device
        self.owns_notification = owns_notification
        self.filters: list[UUID | None] = []

    def fail_stranded(self, user_id: UUID | None) -> list[LostNotice]:
        self.filters.append(user_id)
        return []

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
        self.filters.append(user_id)
        return None

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        self.filters.append(user_id)
        return []

    def register_device(self, user_id: UUID, token: str, platform: str, permission: bool) -> bool:
        return self.accepts_device

    def of_user(self, user_id: UUID) -> tuple[list[Any], int]:
        return ([], 3)

    def read(self, user_id: UUID, notification_id: UUID) -> bool:
        return self.owns_notification


class _Channel:
    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        return DeliveryResult(sent=len(tokens))


def _profile(role: str = "user") -> Profile:
    return Profile(
        id=UUID(int=1),
        uid="uid",
        first_name="Ana",
        last_name="Pérez",
        email="ana@correo.com",
        role=cast(Any, role),
        dni="1",
        birth_date=date(2000, 1, 1),
    )


def test_without_a_person_the_sweep_and_the_dispatch_look_at_everyone() -> None:  # @ENG-14-S1
    repo = _Notifications()
    use_cases.dispatch_pending(cast(Any, repo), _Channel())
    use_cases.send_reminders(cast(Any, repo), _Channel(), NOW)
    assert repo.filters == [None, None, None]


def test_only_a_user_registers_a_phone_with_token_and_active_account() -> None:  # @ENG-14-S1
    repo = cast(Any, _Notifications())
    use_cases.register_device(repo, _profile(), "tok", "ios", True)

    with pytest.raises(Forbidden):
        use_cases.register_device(repo, _profile("admin"), "tok", "ios", True)
    with pytest.raises(InvalidData):
        use_cases.register_device(repo, _profile(), "  ", "ios", True)
    with pytest.raises(Unavailable):
        use_cases.register_device(
            cast(Any, _Notifications(accepts_device=False)), _profile(), "tok", "ios", True
        )


def test_my_notices_are_the_repository_ones_and_anothers_does_not_exist() -> None:  # @ENG-14-S1
    assert use_cases.my_notifications(cast(Any, _Notifications()), _profile()) == ([], 3)
    use_cases.mark_read(cast(Any, _Notifications()), _profile(), UUID(int=9))
    with pytest.raises(NotFound):
        use_cases.mark_read(
            cast(Any, _Notifications(owns_notification=False)), _profile(), UUID(int=9)
        )
