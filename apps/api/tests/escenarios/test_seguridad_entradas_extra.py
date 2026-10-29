"""Seguridad de la API: entradas, proxy, registro de rechazos, correo y contrato (T1 a T4)."""

import logging
import ssl
from collections.abc import Callable
from pathlib import Path
from types import TracebackType

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.password_recovery.rules import Message as Mensaje
from app.shared.config import config
from app.shared import email as correo

RAIZ_REPO = Path(__file__).resolve().parents[4]
CONTRASENA = "ClubNahuel1"


def _socio(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> dict[str, str]:
    s = unico()
    correo_socio = f"socio.{s}@correo.com"
    alta = api.post(
        "/registro",
        json={
            "nombre": "Martín",
            "apellido": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1994-07-21",
            "correo": correo_socio,
            "contrasena": CONTRASENA,
        },
    )
    assert alta.status_code == 201
    token = iniciar_sesion(correo_socio, CONTRASENA)
    assert token is not None
    return {"Authorization": f"Bearer {token}"}


def _registro(**cambios: str) -> dict[str, str]:
    base = {
        "nombre": "Martín",
        "apellido": "Ferreyra",
        "dni": "31000001",
        "fecha_nacimiento": "1994-07-21",
        "correo": "nadie@correo.com",
        "contrasena": CONTRASENA,
    }
    return {**base, **cambios}


def test_la_baja_de_un_token_ajeno_no_hace_nada_y_responde_204(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """dar de baja un token ajeno no hace nada y responde 204
    @REV-01-S19 @assumption:REV-01-ASM-04
    """
    duenia = _socio(api, iniciar_sesion, unico)
    intruso = _socio(api, iniciar_sesion, unico)
    token = f"fcm-{unico()}"
    pedido = {"token": token, "plataforma": "android", "permiso": True}
    assert api.put("/dispositivos", headers=duenia, json=pedido).status_code == 204

    baja = api.post("/dispositivos/baja", headers=intruso, json={"token": token})

    with motor.connect() as conn:
        activo = conn.execute(
            text("SELECT active FROM device WHERE token = :t"), {"t": token}
        ).scalar_one()
    assert baja.status_code == 204
    assert activo is True


class _SmtpSinConfianza:
    def __init__(self, host: str, puerto: int, timeout: float) -> None:
        pass

    def __enter__(self) -> "_SmtpSinConfianza":
        return self

    def __exit__(
        self, tipo: type[BaseException] | None, e: BaseException | None, tb: TracebackType | None
    ) -> None:
        return None

    def starttls(self, context: ssl.SSLContext | None = None) -> None:
        raise ssl.SSLCertVerificationError("certificate verify failed: ana.rios@ejemplo.com")


def test_un_fallo_de_tls_del_correo_no_deja_la_direccion_en_el_log(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """un fallo de TLS del correo no deja la dirección en el log
    @REV-01-S11 @assumption:REV-01-ASM-06
    """
    monkeypatch.setattr(correo.smtplib, "SMTP", _SmtpSinConfianza)
    monkeypatch.setattr(config, "email_mode", "smtp")
    monkeypatch.setattr(config, "smtp_host", "smtp.ejemplo.com")
    monkeypatch.setattr(config, "email_sender", "club@ejemplo.com")

    with caplog.at_level(logging.DEBUG):
        correo.send(Mensaje(recipient="ana.rios@ejemplo.com", subject="Tu enlace", body="Hola"))

    assert caplog.records
    assert "ana.rios@ejemplo.com" not in caplog.text
