import logging
from collections.abc import Sequence
from datetime import UTC, datetime
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import Notice, Recipient, Reminder
from app.modules.notifications.use_cases import DeliveryResult, deliver, send_reminders
from app.shared.config import config
from app.shared.message import Message

DIRECCION = "ana@correo.com"
USUARIO = UUID(int=7)
AVISO = Notice(
    title="El club canceló tu reserva",
    body="Fútbol 5 · Sede Morón · Mié 11, 20:00",
    data={"kind": "forced_cancellation"},
)


class _Repositorio:
    def __init__(self, tokens: list[str], dispositivos: bool = False, nuevo: bool = True) -> None:
        self.tokens = tokens
        self.dispositivos = dispositivos
        self.nuevo = nuevo
        self.envios: list[str] = []

    def recipient(self, user_id: UUID) -> Recipient | None:
        return Recipient(email=DIRECCION, name="Ana")

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        return self.tokens

    def has_devices(self, user_id: UUID) -> bool:
        return self.dispositivos

    def mark_delivery(self, notification_id: UUID, delivery: str) -> None:
        self.envios.append(delivery)

    def deactivate_tokens(self, tokens: Sequence[str]) -> None: ...

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        inicio = datetime(2026, 10, 1, 21, 0, tzinfo=UTC)
        return [
            Reminder(
                booking_id=UUID(int=3),
                user_id=USUARIO,
                starts_at=inicio,
                ends_at=inicio.replace(hour=22),
                sport="Futbol",
                kind="F5",
                venue="Sede Morón",
                email=DIRECCION,
                name="Ana",
            )
        ]

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        return UUID(int=50) if self.nuevo else None


class _Canal:
    """Un canal que acepta todos los tokens y guarda lo que le mandaron."""

    def __init__(self) -> None:
        self.avisos: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.avisos += [notice]
        return DeliveryResult(sent=len(tokens))


def _entregar(repo: _Repositorio, canal: _Canal) -> None:
    deliver(cast(Any, repo), canal, UUID(int=1), USUARIO, AVISO)


def test_cada_notificacion_registrada_sale_tambien_por_correo_con_titulo_cuerpo_y_plantilla(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """cada notificación registrada sale también por correo con su título, cuerpo y la plantilla
    @MAIL-03-S1 @assumption:MAIL-03-ASM-02"""
    enviados: list[Message] = []
    monkeypatch.setattr(use_cases, "send", enviados.append)
    monkeypatch.setattr(config, "public_url", "https://club.example")
    canal = _Canal()

    _entregar(_Repositorio(["token"]), canal)

    assert len(canal.avisos) == 1
    assert len(enviados) == 1
    assert enviados[0].recipient == DIRECCION
    assert enviados[0].subject == AVISO.title
    assert enviados[0].html is not None
    for texto in (AVISO.title, "Fútbol 5", "Abrir la app", 'href="https://club.example"'):
        assert texto in enviados[0].html
    assert AVISO.body in enviados[0].body

    enviados.clear()
    monkeypatch.setattr(config, "public_url", "")
    _entregar(_Repositorio(["token"]), canal)
    assert enviados[0].html is not None
    assert "Abrir la app" not in enviados[0].html


def test_el_correo_sale_aunque_no_haya_push_y_si_falla_el_aviso_queda_como_estaba(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """el correo sale aunque no haya push y si falla el aviso queda como estaba
    @MAIL-03-S2"""
    enviados: list[Message] = []
    monkeypatch.setattr(use_cases, "send", enviados.append)
    repo = _Repositorio([])
    _entregar(repo, _Canal())
    assert len(enviados) == 1
    assert repo.envios == ["no_channel"]

    def roto(mensaje: Message) -> None:
        raise RuntimeError(f"no se pudo enviar a {mensaje.recipient}")

    monkeypatch.setattr(use_cases, "send", roto)
    repo, canal = _Repositorio(["token"]), _Canal()
    with caplog.at_level(logging.WARNING):
        _entregar(repo, canal)
    assert repo.envios == ["sent"]
    assert len(canal.avisos) == 1
    assert "RuntimeError" in caplog.text
    assert DIRECCION not in caplog.text


def test_el_recordatorio_manda_un_solo_correo(monkeypatch: pytest.MonkeyPatch) -> None:
    """el recordatorio manda un solo correo
    @assumption:MAIL-03-ASM-01"""
    enviados: list[Message] = []
    monkeypatch.setattr(use_cases, "send", enviados.append)

    registrados = send_reminders(
        cast(Any, _Repositorio(["token"])), _Canal(), datetime(2026, 10, 1, 20, 30, tzinfo=UTC)
    )

    assert registrados == 1
    assert len(enviados) == 1
    assert enviados[0].subject == "Tu reserva es en 1 hora"


def test_un_aviso_que_no_se_registra_no_manda_correo(monkeypatch: pytest.MonkeyPatch) -> None:
    """un aviso que no se registra no manda correo
    @assumption:MAIL-03-ASM-03"""
    enviados: list[Message] = []
    monkeypatch.setattr(use_cases, "send", enviados.append)

    registrados = send_reminders(
        cast(Any, _Repositorio(["token"], nuevo=False)),
        _Canal(),
        datetime(2026, 10, 1, 20, 30, tzinfo=UTC),
    )

    assert registrados == 0
    assert enviados == []
