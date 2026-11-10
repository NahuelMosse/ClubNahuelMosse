"""The Brevo email mode and the configuration that selects it, by their English names (ENG-23)."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import json
from pathlib import Path
from typing import Any

import pytest

from app.shared import email
from app.shared.config import Settings, config
from app.shared.message import Message

MESSAGE = Message(recipient="lucia+club@correo.com", subject="Create a new password", body="Hola")
ROOT = Path(__file__).resolve().parents[4]


class _Response:
    def __enter__(self) -> "_Response":
        return self

    def __exit__(self, *_: object) -> None:
        return None


def test_in_brevo_mode_the_email_goes_out_through_the_api_with_key_sender_and_text(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """with «EMAIL_MODE=brevo» the email goes out through the Brevo API with its key, sender, recipient, subject and body @MAIL-01-S1 @assumption:MAIL-01-ASM-02"""
    monkeypatch.setattr(config, "email_mode", "brevo")
    monkeypatch.setattr(config, "brevo_api_key", "clave-secreta")
    monkeypatch.setattr(config, "email_sender", "club@correo.com")
    requests: list[Any] = []

    def fake_urlopen(request: Any, timeout: float | None = None) -> _Response:
        requests.append((request, timeout))
        return _Response()

    monkeypatch.setattr("urllib.request.urlopen", fake_urlopen)
    monkeypatch.setattr(
        "smtplib.SMTP", lambda *a, **k: pytest.fail("must not open an SMTP connection")
    )
    email.send(MESSAGE)

    ((request, timeout),) = requests
    assert request.full_url == "https://api.brevo.com/v3/smtp/email"
    assert request.get_method() == "POST"
    assert request.get_header("Api-key") == "clave-secreta"
    assert request.get_header("Content-type") == "application/json"
    assert timeout == 10
    assert json.loads(request.data) == {
        "sender": {"email": "club@correo.com", "name": "Club Nahuel Mosse"},
        "to": [{"email": "lucia+club@correo.com"}],
        "subject": "Create a new password",
        "textContent": "Hola",
    }


def test_smtp_outbox_and_brevo_are_the_modes_and_render_yaml_uses_brevo_with_the_secret_key(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """smtp and outbox stay the same and render.yaml uses brevo with the key as a secret @assumption:MAIL-01-ASM-01"""
    for mode in ("smtp", "outbox", "brevo"):
        monkeypatch.setenv("EMAIL_MODE", mode)
        assert Settings(_env_file=None).email_mode == mode

    render = (ROOT / "render.yaml").read_text(encoding="utf-8")
    assert "- key: EMAIL_MODE\n        value: brevo" in render
    assert "- key: BREVO_API_KEY\n        sync: false" in render
    assert "- key: SMTP_HOST\n        sync: false" in render
