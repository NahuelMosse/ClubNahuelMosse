import urllib.error
from collections.abc import Callable
from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.shared import email
from app.shared.config import config
from app.shared.message import Message

MESSAGE = Message(recipient="lucia+club@correo.com", subject="Create a new password", body="Hola")


class _Response:
    def __enter__(self) -> "_Response":
        return self

    def __exit__(self, *_: object) -> None:
        return None


def _in_brevo_mode(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(config, "email_mode", "brevo")
    monkeypatch.setattr(config, "brevo_api_key", "clave-secreta")
    monkeypatch.setattr(config, "email_sender", "club@correo.com")


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
