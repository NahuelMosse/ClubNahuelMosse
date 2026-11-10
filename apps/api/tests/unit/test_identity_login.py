"""The password check against the provider tells a rejection from a failure."""

import io
import json
import urllib.error
import urllib.request
from typing import Any, cast

import pytest

from app.shared.identity import FirebaseProvider, RateLimited


def _answers_400(monkeypatch: pytest.MonkeyPatch, message: str) -> None:
    def request(*_: Any, **__: Any) -> Any:
        body = io.BytesIO(json.dumps({"error": {"message": message}}).encode())
        raise urllib.error.HTTPError("http://x", 400, "Bad Request", cast(Any, {}), body)

    monkeypatch.setattr(urllib.request, "urlopen", request)
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:1")


def test_a_rejected_password_is_false_and_nothing_else(monkeypatch: pytest.MonkeyPatch) -> None:
    _answers_400(monkeypatch, "INVALID_LOGIN_CREDENTIALS")
    assert FirebaseProvider().password_matches("a@b.com", "mala") is False


def test_too_many_attempts_is_reported_as_a_delay(monkeypatch: pytest.MonkeyPatch) -> None:
    _answers_400(monkeypatch, "TOO_MANY_ATTEMPTS_TRY_LATER : x")
    with pytest.raises(RateLimited):
        FirebaseProvider().password_matches("a@b.com", "mala")
