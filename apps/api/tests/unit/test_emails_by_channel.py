"""Each mail channel gets the HTML part only when there is one; the outbox stores only the text."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import json
from contextlib import contextmanager
from typing import Any

import pytest

from app.modules.password_recovery.rules import Message
from app.shared import email
from app.shared.config import config

ADDRESS = "ana@correo.com"


def test_brevo_gets_htmlcontent_only_if_there_is_html_smtp_the_alternative_and_the_outbox_only_the_text(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Brevo gets htmlContent only if there is HTML, SMTP the alternative and the outbox only the text
    @assumption:MAIL-02-ASM-01"""
    requests: list[dict[str, Any]] = []

    def fake_urlopen(request: Any, timeout: int) -> Any:
        requests.append(json.loads(request.data))

        @contextmanager
        def response() -> Any:
            yield None

        return response()

    monkeypatch.setattr("urllib.request.urlopen", fake_urlopen)
    monkeypatch.setattr(config, "brevo_api_key", "clave")
    monkeypatch.setattr(config, "email_sender", "club@correo.com")
    email._by_brevo(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    email._by_brevo(Message(ADDRESS, "Asunto", "texto"))
    assert requests[0]["htmlContent"] == "<p>hola</p>"
    assert requests[0]["textContent"] == "texto"
    assert "htmlContent" not in requests[1]

    sent: list[Any] = []

    class FakeSmtp:
        def __init__(self, *a: Any, **k: Any) -> None: ...
        def __enter__(self) -> "FakeSmtp":
            return self

        def __exit__(self, *a: Any) -> None: ...
        def starttls(self, **k: Any) -> None: ...
        def login(self, *a: Any) -> None: ...
        def send_message(self, message: Any) -> None:
            sent.append(message)

    monkeypatch.setattr("smtplib.SMTP", FakeSmtp)
    monkeypatch.setattr(config, "smtp_host", "smtp.example")
    email._by_smtp(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    email._by_smtp(Message(ADDRESS, "Asunto", "texto"))
    assert sent[0].get_body(("html",)).get_content().strip() == "<p>hola</p>"
    assert sent[1].get_body(("html",)) is None

    saved: list[dict[str, Any]] = []

    class FakeConnection:
        def execute(self, sql: Any, params: dict[str, Any]) -> None:
            saved.append(params)

    class FakeEngine:
        @contextmanager
        def begin(self) -> Any:
            yield FakeConnection()

    monkeypatch.setattr(email, "engine", lambda: FakeEngine())
    email._to_outbox(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    assert saved == [{"recipient": ADDRESS, "subject": "Asunto", "body": "texto"}]
