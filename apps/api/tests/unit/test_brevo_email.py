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

MESSAGE = Message(
    recipient="lucia+club@correo.com", subject="Creá una contraseña nueva", body="Hola"
)
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


def test_con_modo_brevo_el_correo_sale_por_la_api_con_clave_remitente_y_texto(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """con CORREO_MODO=brevo el correo sale por la API de Brevo con su clave, remitente,
    destinatario, asunto y cuerpo @MAIL-01-S1 @assumption:MAIL-01-ASM-02"""
    _in_brevo_mode(monkeypatch)
    requests: list[Any] = []

    def fake_urlopen(request: Any, timeout: float | None = None) -> _Response:
        requests.append((request, timeout))
        return _Response()

    monkeypatch.setattr("urllib.request.urlopen", fake_urlopen)
    monkeypatch.setattr(
        "smtplib.SMTP", lambda *a, **k: pytest.fail("no debe abrir una conexión SMTP")
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
        "subject": "Creá una contraseña nueva",
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
def test_si_brevo_falla_el_log_no_trae_la_direccion_y_el_pedido_sigue_en_202(
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
    api: TestClient,
    unico: Callable[[], str],
    failure: Exception,
) -> None:
    """si Brevo falla o no responde el error queda en el log sin la dirección y el pedido
    sigue en 202 @MAIL-01-S2"""
    _in_brevo_mode(monkeypatch)

    def broken(*_: Any, **__: Any) -> None:
        raise failure

    monkeypatch.setattr("urllib.request.urlopen", broken)
    email.send(MESSAGE)
    assert (
        f"no se pudo enviar el correo «{MESSAGE.subject}»: {type(failure).__name__}" in caplog.text
    )
    assert "lucia" not in caplog.text
    assert "clave-secreta" not in caplog.text

    s = unico()
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


def test_smtp_y_buzon_siguen_igual_y_render_yaml_usa_brevo_con_la_clave_secreta(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """smtp y buzon siguen igual y render.yaml usa brevo con la clave como secreto
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
