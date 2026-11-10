"""A notice to a person with no email on file goes out by push only."""

# ruff: noqa: E501  (the test title carries its tag and is not split)

from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import Recipient
from app.modules.notifications.use_cases import deliver
from app.shared.message import Message
from tests.unit.test_notice_by_email import NOTICE, USER, _Channel, _Repository


class _WithoutEmail(_Repository):
    def recipient(self, user_id: UUID) -> Recipient | None:
        return Recipient(email="", name="Ana")


def test_a_notice_to_a_person_without_email_sends_no_email_and_goes_out_by_push(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """a notice to a person with no email on file sends no email and still goes out by push @MAIL-03-S2"""
    sent: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent.append)
    repo = _WithoutEmail(tokens=["t1"])
    channel = _Channel()

    deliver(cast(Any, repo), channel, UUID(int=1), USER, NOTICE)

    assert sent == []
    assert channel.notices == [NOTICE]
    assert repo.deliveries == ["sent"]
