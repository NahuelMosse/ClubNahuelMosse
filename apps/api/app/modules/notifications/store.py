from collections.abc import Sequence
from datetime import datetime
from typing import Protocol
from uuid import UUID

from app.modules.notifications.rules import (
    Delivery,
    LostNotice,
    Notice,
    Notification,
    PendingNotice,
    Reminder,
)


class Notifications(Protocol):
    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        """Active bookings that start within the next hour after [now], made or modified at
        least one hour ahead and without a notice for their current time slot."""
        ...

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        """Saves the notice in the center. `None` if it was already there: another sweep
        registered it."""
        ...

    def tokens_with_permission(self, user_id: UUID) -> list[str]: ...

    def has_devices(self, user_id: UUID) -> bool:
        """Whether [user_id] has any registered device, with or without permission."""
        ...

    def fail_stranded(self, user_id: UUID | None) -> list[LostNotice]:
        """Moves to `fallida`, and returns, the registered reminders of [user_id] or of
        everyone whose slot already started or was cancelled: they will not go out."""
        ...

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
        """Claims for the caller the oldest unsent notice of [user_id] or of everyone (a
        reminder only if it is still current): it moves to `enviando`, so two simultaneous
        dispatches do not send it twice. `None` if none is left."""
        ...

    def mark_delivery(self, notification_id: UUID, delivery: Delivery) -> None: ...

    def deactivate_tokens(self, tokens: Sequence[str]) -> None: ...

    def register_device(
        self,
        user_id: UUID,
        token: str,
        platform: str,
        permission: bool,  # noqa: FBT001
    ) -> bool:
        """Leaves the device under [user_id]. `False` if the account is no longer active."""
        ...

    def unregister_device(self, user_id: UUID, token: str) -> None: ...

    def of_user(self, user_id: UUID) -> tuple[list[Notification], int]:
        """The latest notifications, newest first, and how many unread there are in total."""
        ...

    def read(self, user_id: UUID, notification_id: UUID) -> bool:
        """Marks one of the user's own notifications as read. `False` if it is not theirs."""
        ...

    def read_all(self, user_id: UUID) -> None: ...
