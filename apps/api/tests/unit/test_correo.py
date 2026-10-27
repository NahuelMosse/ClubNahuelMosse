import pytest

from app.modules.password_recovery import email as correo
from app.modules.password_recovery.rules import Message as Mensaje
from app.shared.config import config

MENSAJE = Mensaje(recipient="lucia@correo.com", subject="Asunto", body="Cuerpo")


def test_sin_servidor_configurado_el_correo_no_sale_y_queda_en_el_log(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    monkeypatch.setattr(config, "email_mode", "smtp")
    monkeypatch.setattr(config, "smtp_host", "")
    correo.send(MENSAJE)
    assert "no se pudo enviar el correo" in caplog.text
    assert "RuntimeError" in caplog.text


def test_el_default_es_smtp_y_no_el_buzon(monkeypatch: pytest.MonkeyPatch) -> None:
    from app.shared.config import Settings

    monkeypatch.delenv("CORREO_MODO", raising=False)
    assert Settings(_env_file=None).email_mode == "smtp"
