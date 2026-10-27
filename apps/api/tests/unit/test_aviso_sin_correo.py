"""Un aviso a una persona sin correo cargado sale sólo por push."""

# ruff: noqa: E501  (el título de la prueba lleva su etiqueta y no se parte)

from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notifications import use_cases
from app.modules.notifications.rules import Recipient
from app.modules.notifications.use_cases import deliver
from app.shared.message import Message
from tests.unit.test_aviso_por_correo import AVISO, USUARIO, _Canal, _Repositorio


class _SinCorreo(_Repositorio):
    def recipient(self, user_id: UUID) -> Recipient | None:
        return Recipient(email="", name="Ana")


def test_un_aviso_a_una_persona_sin_correo_no_manda_correo_y_sale_por_push(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """un aviso a una persona sin correo cargado no manda correo y sale igual por push @MAIL-03-S2"""
    enviados: list[Message] = []
    monkeypatch.setattr(use_cases, "send", enviados.append)
    repo = _SinCorreo(tokens=["t1"])
    canal = _Canal()

    deliver(cast(Any, repo), canal, UUID(int=1), USUARIO, AVISO)

    assert enviados == []
    assert canal.avisos == [AVISO]
    assert repo.envios == ["enviada"]
