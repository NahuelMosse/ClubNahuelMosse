import pytest

from app.shared import email
from app.shared.config import config
from app.shared.message import Message

MESSAGE = Message(recipient="lucia@correo.com", subject="Asunto", body="Cuerpo")


def test_without_a_configured_server_the_email_is_not_sent_and_stays_in_the_log(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    monkeypatch.setattr(config, "email_mode", "smtp")
    monkeypatch.setattr(config, "smtp_host", "")
    email.send(MESSAGE)
    assert "could not send the email" in caplog.text
    assert "RuntimeError" in caplog.text


def test_the_default_is_smtp_and_not_the_outbox(monkeypatch: pytest.MonkeyPatch) -> None:
    from app.shared.config import Settings

    monkeypatch.delenv("CORREO_MODO", raising=False)
    assert Settings(_env_file=None).email_mode == "smtp"
