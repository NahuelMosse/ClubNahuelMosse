import json
import urllib.error
from collections.abc import Callable
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.modules.recuperacion import correo
from app.modules.recuperacion.reglas import Mensaje
from app.shared.config import Config, config

MENSAJE = Mensaje(para="lucia+club@correo.com", asunto="Creá una contraseña nueva", cuerpo="Hola")
RAIZ = Path(__file__).resolve().parents[4]


class _Respuesta:
    def __init__(self, estado: int) -> None:
        self.status = estado

    def __enter__(self) -> "_Respuesta":
        return self

    def __exit__(self, *_: object) -> None:
        return None

    def getcode(self) -> int:
        return self.status


def _en_modo_brevo(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(config, "correo_modo", "brevo")
    monkeypatch.setattr(config, "brevo_api_key", "clave-secreta")
    monkeypatch.setattr(config, "correo_remitente", "club@correo.com")


def test_con_correo_modo_brevo_el_correo_sale_por_la_api_de_brevo_con_su_clave_remitente_destinatario_asunto_y_cuerpo(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """@MAIL-01-S1 @assumption:MAIL-01-ASM-02"""
    _en_modo_brevo(monkeypatch)
    pedidos: list[Any] = []

    def falso_urlopen(pedido: Any, timeout: float | None = None) -> _Respuesta:
        pedidos.append((pedido, timeout))
        return _Respuesta(201)

    monkeypatch.setattr("urllib.request.urlopen", falso_urlopen)
    monkeypatch.setattr(
        "smtplib.SMTP", lambda *a, **k: pytest.fail("no debe abrir una conexión SMTP")
    )
    correo.enviar(MENSAJE)

    ((pedido, timeout),) = pedidos
    assert pedido.full_url == "https://api.brevo.com/v3/smtp/email"
    assert pedido.get_method() == "POST"
    assert pedido.get_header("Api-key") == "clave-secreta"
    assert pedido.get_header("Content-type") == "application/json"
    assert timeout == 10
    assert json.loads(pedido.data) == {
        "sender": {"email": "club@correo.com", "name": "Club Nahuel Mosse"},
        "to": [{"email": "lucia+club@correo.com"}],
        "subject": "Creá una contraseña nueva",
        "textContent": "Hola",
    }


@pytest.mark.parametrize(
    "falla",
    [urllib.error.HTTPError("https://x", 401, "no", None, None), TimeoutError("agotado")],  # type: ignore[arg-type]
)
def test_si_brevo_falla_o_no_responde_el_error_queda_en_el_log_sin_la_direccion_y_el_pedido_sigue_en_202(
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
    api: TestClient,
    unico: Callable[[], str],
    falla: Exception,
) -> None:
    """@MAIL-01-S2"""
    _en_modo_brevo(monkeypatch)

    def roto(*_: Any, **__: Any) -> None:
        raise falla

    monkeypatch.setattr("urllib.request.urlopen", roto)
    correo.enviar(MENSAJE)
    assert f"no se pudo enviar el correo «{MENSAJE.asunto}»: {type(falla).__name__}" in caplog.text
    assert "lucia" not in caplog.text
    assert "clave-secreta" not in caplog.text

    s = unico()
    pedido = {
        "nombre": "Lucía",
        "apellido": "Gómez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1998-11-02",
        "correo": f"socia.{s}@correo.com",
        "contrasena": "ClubNahuel1",
    }
    assert api.post("/registro", json=pedido).status_code == 201
    assert api.post("/recuperacion", json={"correo": pedido["correo"]}).status_code == 202


def test_smtp_y_buzon_siguen_igual_y_render_yaml_usa_brevo_con_la_clave_como_secreto(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """@assumption:MAIL-01-ASM-01"""
    monkeypatch.setenv("CORREO_MODO", "smtp")
    assert Config(_env_file=None).correo_modo == "smtp"
    monkeypatch.setenv("CORREO_MODO", "buzon")
    assert Config(_env_file=None).correo_modo == "buzon"
    monkeypatch.setenv("CORREO_MODO", "brevo")
    assert Config(_env_file=None).correo_modo == "brevo"

    render = (RAIZ / "render.yaml").read_text(encoding="utf-8")
    assert "- key: CORREO_MODO\n        value: brevo" in render
    assert "- key: BREVO_API_KEY\n        sync: false" in render
    assert "- key: SMTP_HOST\n        sync: false" in render
