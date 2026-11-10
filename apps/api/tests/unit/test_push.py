import pytest

from app.modules.notifications.push import build_message
from app.modules.notifications.rules import Notice

# firebase_admin warns that `tokens` is deprecated in favor of `fids`; the real channel uses it.
pytestmark = pytest.mark.filterwarnings("ignore:MulticastMessage.tokens:DeprecationWarning")


def test_the_voiding_notice_carries_a_stable_key_to_replace_the_previous_one() -> None:
    """the grouped one replaces the previous notice in the tray @assumption:CU-24.2-SUP-09"""
    single = build_message(
        ["t"], Notice("a", "b", {"kind": "forced_cancellation", "booking_id": "1"})
    )
    several = build_message(["t"], Notice("a", "b", {"kind": "forced_cancellation"}))

    for m in (single, several):
        assert m.android is not None
        assert m.android.collapse_key == "forced_cancellation"
        assert m.android.notification is not None
        assert m.android.notification.tag == "forced_cancellation"
        assert m.apns is not None
        assert m.apns.headers == {"apns-collapse-id": "forced_cancellation"}


def test_the_other_notices_do_not_replace_each_other() -> None:
    m = build_message(["t"], Notice("a", "b", {"kind": "reminder", "booking_id": "1"}))

    assert m.android is None
    assert m.apns is None
