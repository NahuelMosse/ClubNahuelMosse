"""Un aviso a una persona sin correo cargado sale sólo por push."""

from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notificaciones import casos_de_uso
from app.modules.notificaciones.casos_de_uso import entregar
from app.modules.notificaciones.reglas import Destinatario
from app.shared.mensaje import Mensaje

from tests.unit.test_aviso_por_correo import AVISO, USUARIO, _Canal, _Repositorio


class _SinCorreo(_Repositorio):
    def destinatario(self, usuario_id: UUID) -> Destinatario | None:
        return Destinatario(correo="", nombre="Ana")


def test_un_aviso_a_una_persona_sin_correo_no_manda_correo_y_sale_por_push(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """un aviso a una persona sin correo cargado no manda correo y sale igual por push @MAIL-03-S2"""
    enviados: list[Mensaje] = []
    monkeypatch.setattr(casos_de_uso, "enviar", enviados.append)
    repo = _SinCorreo(tokens=["t1"])
    canal = _Canal()

    entregar(cast(Any, repo), canal, UUID(int=1), USUARIO, AVISO)

    assert enviados == []
    assert canal.avisos == [AVISO]
    assert repo.envios == ["enviada"]
