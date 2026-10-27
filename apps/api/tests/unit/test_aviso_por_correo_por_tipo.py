"""Cada tipo de aviso sale por correo por su camino real, una vez."""

from datetime import UTC, datetime
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import Notice, PendingNotice, notice_data
from app.modules.notifications.use_cases import dispatch_pending, send_reminders
from app.shared.message import Message
from tests.unit.test_aviso_por_correo import DIRECCION, USUARIO, _Canal, _Repositorio


class _ConPendientes(_Repositorio):
    def __init__(self, pendientes: list[PendingNotice]) -> None:
        super().__init__([])
        self.pendientes = pendientes

    def fail_stranded(self, user_id: UUID | None) -> list[Any]:
        return []

    def take_next(self, user_id: UUID | None) -> PendingNotice | None:
        return self.pendientes.pop(0) if self.pendientes else None


def _pendiente(numero: int, tipo: Any, titulo: str, reserva: UUID | None) -> PendingNotice:
    aviso = Notice(title=titulo, body="cuerpo " + titulo, data=notice_data(tipo, reserva))
    return PendingNotice(notification_id=UUID(int=numero), user_id=USUARIO, notice=aviso)


def test_el_recordatorio_la_cancelacion_del_club_la_agrupada_y_la_propia_salen_por_correo(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el recordatorio, la cancelación del club, la agrupada y la propia salen cada una por
    correo @MAIL-03-S1"""
    enviados: list[Message] = []
    monkeypatch.setattr(use_cases, "send", enviados.append)

    ahora = datetime(2026, 10, 1, 20, 30, tzinfo=UTC)
    send_reminders(cast(Any, _ConPendientes([])), _Canal(), ahora)
    pendientes = [
        _pendiente(1, "cancelacion_forzosa", "El club anuló tu reserva", UUID(int=3)),
        _pendiente(2, "cancelacion_forzosa", "El club anuló 3 reservas", None),
        _pendiente(3, "cancelacion_usuario", "Cancelaste tu reserva", UUID(int=4)),
    ]
    despachados = dispatch_pending(cast(Any, _ConPendientes(pendientes)), _Canal())

    assert despachados == 3
    assert [m.subject for m in enviados] == [
        "Tu reserva es en 1 hora",
        "El club anuló tu reserva",
        "El club anuló 3 reservas",
        "Cancelaste tu reserva",
    ]
    assert {m.recipient for m in enviados} == {DIRECCION}
