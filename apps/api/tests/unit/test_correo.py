import pytest

from app.aplicacion.recuperacion import Mensaje
from app.config import config
from app.infraestructura import correo

MENSAJE = Mensaje(para="lucia@correo.com", asunto="Asunto", cuerpo="Cuerpo")


def test_sin_servidor_configurado_el_correo_no_sale_y_queda_en_el_log(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    monkeypatch.setattr(config, "correo_modo", "smtp")
    monkeypatch.setattr(config, "smtp_host", "")
    correo.enviar(MENSAJE)
    assert "no se pudo enviar el correo" in caplog.text
    assert "RuntimeError" in caplog.text


def test_el_default_es_smtp_y_no_el_buzon(monkeypatch: pytest.MonkeyPatch) -> None:
    from app.config import Config

    monkeypatch.delenv("CORREO_MODO", raising=False)
    assert Config(_env_file=None).correo_modo == "smtp"
