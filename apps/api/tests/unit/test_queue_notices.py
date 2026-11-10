from datetime import timedelta

from app.modules.notifications.rules import REMINDER_GRACE


def test_a_newly_registered_reminder_waits_one_minute_before_being_dispatched() -> None:
    assert timedelta(minutes=1) == REMINDER_GRACE
