"""Each notice type goes out by email through its real path, once."""

from datetime import UTC, datetime
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import Notice, PendingNotice, notice_data
from app.modules.notifications.use_cases import dispatch_pending, send_reminders
from app.shared.message import Message
from tests.unit.test_notice_by_email import ADDRESS, USER, _Channel, _Repository


class _WithPending(_Repository):
    def __init__(self, pending: list[PendingNotice]) -> None:
        super().__init__([])
        self.pending = pending

    def fail_stranded(self, user_id: UUID | None) -> list[Any]:
        return []

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
        return self.pending.pop(0) if self.pending else None


def _pending(number: int, kind: Any, title: str, booking: UUID | None) -> PendingNotice:
    notice = Notice(title=title, body="cuerpo " + title, data=notice_data(kind, booking))
    return PendingNotice(notification_id=UUID(int=number), user_id=USER, notice=notice)


def test_the_reminder_the_club_cancellation_the_grouped_one_and_the_own_one_go_out_by_email(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the reminder, the club cancellation, the grouped one and the own one each go out by
    email @MAIL-03-S1"""
    sent: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent.append)

    now = datetime(2026, 10, 1, 20, 30, tzinfo=UTC)
    send_reminders(cast(Any, _WithPending([])), _Channel(), now)
    pending = [
        _pending(1, "cancelacion_forzosa", "The club voided your booking", UUID(int=3)),
        _pending(2, "cancelacion_forzosa", "El club anuló 3 reservas", None),
        _pending(3, "cancelacion_usuario", "Cancelaste tu reserva", UUID(int=4)),
    ]
    dispatched = dispatch_pending(cast(Any, _WithPending(pending)), _Channel())

    assert dispatched == 3
    assert [m.subject for m in sent] == [
        "Your booking is in 1 hour",
        "The club voided your booking",
        "El club anuló 3 reservas",
        "Cancelaste tu reserva",
    ]
    assert {m.recipient for m in sent} == {ADDRESS}
