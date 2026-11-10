import json
import urllib.error
from collections.abc import Callable
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient

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


def _in_brevo_mode(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(config, "email_mode", "brevo")
    monkeypatch.setattr(config, "brevo_api_key", "clave-secreta")
    monkeypatch.setattr(config, "email_sender", "club@correo.com")


def test_in_brevo_mode_the_email_goes_out_through_the_api_with_key_sender_and_text(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """with «CORREO_MODO=brevo» the email goes out through the Brevo API with its key, sender,
    recipient, subject and body @MAIL-01-S1 @assumption:MAIL-01-ASM-02"""
    _in_brevo_mode(monkeypatch)
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


NO_HEADERS: Any = None


@pytest.mark.parametrize(
    "failure",
    [
        urllib.error.HTTPError("https://x", 401, "no", NO_HEADERS, None),
        TimeoutError("agotado"),
    ],
)
def test_if_brevo_fails_the_log_has_no_address_and_the_request_stays_202(
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
    api: TestClient,
    unique: Callable[[], str],
    failure: Exception,
) -> None:
    """if Brevo fails or does not answer the error is logged without the address and the request
    stays 202 @MAIL-01-S2"""
    _in_brevo_mode(monkeypatch)

    def broken(*_: Any, **__: Any) -> None:
        raise failure

    monkeypatch.setattr("urllib.request.urlopen", broken)
    email.send(MESSAGE)
    assert f"could not send the email «{MESSAGE.subject}»: {type(failure).__name__}" in caplog.text
    assert "lucia" not in caplog.text
    assert "clave-secreta" not in caplog.text

    s = unique()
    payload = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1998-11-02",
        "email": f"socia.{s}@correo.com",
        "password": "ClubNahuel1",
    }
    assert api.post("/register", json=payload).status_code == 201
    assert api.post("/password-recovery", json={"email": payload["email"]}).status_code == 202


def test_smtp_and_outbox_stay_the_same_and_render_yaml_uses_brevo_with_the_secret_key(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """smtp and outbox stay the same and render.yaml uses brevo with the key as a secret
    @assumption:MAIL-01-ASM-01"""
    monkeypatch.setenv("CORREO_MODO", "smtp")
    assert Settings(_env_file=None).email_mode == "smtp"
    monkeypatch.setenv("CORREO_MODO", "buzon")
    assert Settings(_env_file=None).email_mode == "outbox"
    monkeypatch.setenv("CORREO_MODO", "brevo")
    assert Settings(_env_file=None).email_mode == "brevo"

    render = (ROOT / "render.yaml").read_text(encoding="utf-8")
    assert "- key: CORREO_MODO\n        value: brevo" in render
    assert "- key: BREVO_API_KEY\n        sync: false" in render
    assert "- key: SMTP_HOST\n        sync: false" in render
