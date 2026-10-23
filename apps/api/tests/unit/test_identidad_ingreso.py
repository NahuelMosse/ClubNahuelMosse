"""La comprobación de contraseña contra el proveedor distingue un rechazo de un fallo."""

import io
import json
import urllib.error
import urllib.request
from typing import Any, cast

import pytest

from app.infraestructura.identidad import Demorado, ProveedorFirebase


def _responde_400(monkeypatch: pytest.MonkeyPatch, mensaje: str) -> None:
    def pedir(*_: Any, **__: Any) -> Any:
        cuerpo = io.BytesIO(json.dumps({"error": {"message": mensaje}}).encode())
        raise urllib.error.HTTPError("http://x", 400, "Bad Request", cast(Any, {}), cuerpo)

    monkeypatch.setattr(urllib.request, "urlopen", pedir)
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:1")


def test_una_contrasena_rechazada_es_falso_y_no_otra_cosa(monkeypatch: pytest.MonkeyPatch) -> None:
    _responde_400(monkeypatch, "INVALID_LOGIN_CREDENTIALS")
    assert ProveedorFirebase().contrasena_correcta("a@b.com", "mala") is False


def test_demasiados_intentos_se_informa_como_demora(monkeypatch: pytest.MonkeyPatch) -> None:
    _responde_400(monkeypatch, "TOO_MANY_ATTEMPTS_TRY_LATER : x")
    with pytest.raises(Demorado):
        ProveedorFirebase().contrasena_correcta("a@b.com", "mala")
