import pytest

from app.modules.recuperacion import correo
from app.modules.recuperacion.casos_de_uso import Mensaje
from app.shared.config import config

MENSAJE = Mensaje(para="lucia@correo.com", asunto="Asunto", cuerpo="Cuerpo")


def test_sin_servidor_configurado_el_correo_no_sale_y_queda_en_el_log(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    monkeypatch.setattr(config, "email_mode", "smtp")
    monkeypatch.setattr(config, "smtp_host", "")
    correo.enviar(MENSAJE)
    assert "no se pudo enviar el correo" in caplog.text
    assert "RuntimeError" in caplog.text


def test_el_default_es_smtp_y_no_el_buzon(monkeypatch: pytest.MonkeyPatch) -> None:
    from app.shared.config import Settings

    monkeypatch.delenv("CORREO_MODO", raising=False)
    assert Settings(_env_file=None).email_mode == "smtp"
