from collections.abc import Sequence
from datetime import UTC, datetime, timedelta
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import (
    FIVE_MINUTE_LEAD_TIME,
    Notice,
    Recipient,
    Reminder,
    reminder_message,
)
from app.modules.notifications.use_cases import DeliveryResult, send_reminders
from app.shared.message import Message

AHORA = datetime(2026, 10, 1, 23, 56, tzinfo=UTC)
INICIO = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)


def _cinco() -> Reminder:
    return Reminder(
        UUID(int=7),
        UUID(int=3),
        INICIO,
        INICIO + timedelta(hours=1),
        "Futbol",
        "F5",
        "Sede Morón",
        email="ana@correo.com",
        name="Ana",
        reminder_kind="five_minute_reminder",
    )


class _Repositorio:
    def __init__(self) -> None:
        self.registrados: list[Reminder] = []
        self.envios: list[str] = []

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        return [_cinco(), _cinco()]

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        if self.registrados:
            return None
        self.registrados.append(reminder)
        return UUID(int=50)

    def recipient(self, user_id: UUID) -> Recipient | None:
        return None

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        return ["token"]

    def mark_delivery(self, notification_id: UUID, delivery: str) -> None:
        self.envios.append(delivery)

    def deactivate_tokens(self, tokens: Sequence[str]) -> None: ...


class _Canal:
    def __init__(self) -> None:
        self.avisos: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.avisos.append(notice)
        return DeliveryResult(sent=len(tokens))


def test_a_5_minutos_de_la_reserva_sale_un_aviso_por_push_y_por_correo_una_sola_vez(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """a 5 minutos de la reserva sale un aviso por push y por correo, una sola vez @NOT-05-S1"""
    correos: list[Message] = []
    monkeypatch.setattr(use_cases, "send", correos.append)
    repo, canal = _Repositorio(), _Canal()

    registrados = send_reminders(cast(Any, repo), canal, AHORA)

    assert registrados == 1
    assert [a.title for a in canal.avisos] == ["Tu reserva empieza en 5 minutos"]
    assert canal.avisos[0].body == "Fútbol 5 · Sede Morón · 21:00 – 22:00"
    assert canal.avisos[0].data == {"kind": "five_minute_reminder", "booking_id": str(UUID(int=7))}
    assert [c.subject for c in correos] == ["Tu reserva empieza en 5 minutos"]
    assert repo.envios == ["sent"]
    assert FIVE_MINUTE_LEAD_TIME == timedelta(minutes=5)


def test_el_aviso_de_una_hora_sigue_igual() -> None:
    una_hora = Reminder(UUID(int=7), UUID(int=3), INICIO, INICIO, "Futbol", "F5", "Sede")
    assert reminder_message(una_hora).title == "Tu reserva es en 1 hora"
