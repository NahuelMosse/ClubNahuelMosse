"""The edges of the rules whose error keys and delivery values travel in the contract."""

# ruff: noqa: E501  (a test title carries its tag and is not split)

from collections.abc import Sequence
from datetime import date, datetime, time, timedelta
from typing import Any, cast
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest

from app.modules.availability.rules import OpeningHours, validate_range
from app.modules.notifications import use_cases
from app.modules.notifications.rules import DeliveryResult, Notice
from app.modules.notifications.use_cases import deliver
from app.shared.message import Message
from tests.unit.test_aviso_por_correo import AVISO, USUARIO, _Repositorio

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")
EVERY_DAY = (1, 2, 3, 4, 5, 6, 7)
THURSDAY = date(2026, 11, 12)
HOURS = OpeningHours(time(8), time(23), EVERY_DAY)


def _at(day: date, hour: int) -> datetime:
    return datetime.combine(day, time(hour), tzinfo=ZONE)


def test_a_start_hour_not_on_the_hour_is_its_only_error_even_before_opening() -> None:
    """a start hour that is not on the hour is the only error of start_hour, even before opening @ENG-18-S2"""
    errors = validate_range(HOURS, THURSDAY, time(6, 30), time(9), _at(THURSDAY - timedelta(1), 9))

    assert errors == {"start_hour": "Elegí una hora en punto"}


def test_a_range_that_starts_right_now_is_not_future() -> None:
    """a range that starts right now is not future and the error goes under start_hour @ENG-18-S2"""
    errors = validate_range(HOURS, THURSDAY, time(18), time(19), _at(THURSDAY, 18))

    assert errors == {"start_hour": "El horario tiene que ser futuro"}


class _NoDeviceAccepted:
    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        return DeliveryResult(sent=0)


def test_a_push_no_device_accepted_is_recorded_as_failed(monkeypatch: pytest.MonkeyPatch) -> None:
    """a push that no device accepted is recorded with the English value failed @ENG-18-S3"""
    sent_emails: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent_emails.append)
    repo = _Repositorio(tokens=["t1"])

    deliver(cast(Any, repo), _NoDeviceAccepted(), UUID(int=1), USUARIO, AVISO)

    assert repo.envios == ["failed"]
