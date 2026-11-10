"""A notice left `sending` by a downed API becomes failed in the sweep."""

from collections.abc import Sequence
from uuid import UUID

from sqlalchemy import Engine, text

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import DeliveryResult, Notice
from app.modules.notifications.use_cases import dispatch_pending


class _CountingChannel:
    def __init__(self) -> None:
        self.calls = 0

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.calls += 1
        return DeliveryResult(sent=1, invalid=())


def _sending(engine: Engine, minutes: int) -> UUID:
    with engine.begin() as conn:
        id_: UUID = conn.execute(
            text(
                "INSERT INTO notification (user_id, kind, title, body, delivery, sending_since)"
                " SELECT id, 'forced_cancellation', 'Cancelaron', 'Fútbol 5', 'sending',"
                " now() - make_interval(mins => :m) FROM app_user WHERE active LIMIT 1"
                " RETURNING id"
            ),
            {"m": minutes},
        ).scalar_one()
    return id_


def _delivery(engine: Engine, id_: UUID) -> str:
    with engine.connect() as conn:
        delivery: str = conn.execute(
            text("SELECT delivery FROM notification WHERE id = :id"), {"id": id_}
        ).scalar_one()
    return delivery


def test_a_notice_over_10_minutes_in_sending_becomes_failed_and_is_not_resent(
    engine: Engine, user_token: str
) -> None:
    """a notice over 10 minutes in sending becomes failed in the sweep and is not resent @SIM-01-S2 @assumption:SIM-01-ASM-10"""
    old = _sending(engine, 11)
    recent = _sending(engine, 1)
    channel = _CountingChannel()
    with engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), channel)
    assert _delivery(engine, old) == "failed"
    assert _delivery(engine, recent) == "sending"
    assert channel.calls == 0
