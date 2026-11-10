"""API security: inputs, proxy, rejection log, email and contract (T1 to T4)."""

import logging
import ssl
from collections.abc import Callable
from pathlib import Path
from types import TracebackType

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.password_recovery.rules import Message
from app.shared.config import config
from app.shared import email as email_module

REPO_ROOT = Path(__file__).resolve().parents[4]
PASSWORD = "ClubNahuel1"


def _member(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> dict[str, str]:
    s = unique()
    member_email = f"socio.{s}@correo.com"
    signup = api.post(
        "/register",
        json={
            "first_name": "Martín",
            "last_name": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1994-07-21",
            "email": member_email,
            "password": PASSWORD,
        },
    )
    assert signup.status_code == 201
    token = sign_in(member_email, PASSWORD)
    assert token is not None
    return {"Authorization": f"Bearer {token}"}


def _registration(**changes: str) -> dict[str, str]:
    base = {
        "first_name": "Martín",
        "last_name": "Ferreyra",
        "dni": "31000001",
        "birth_date": "1994-07-21",
        "email": "nadie@correo.com",
        "password": PASSWORD,
    }
    return {**base, **changes}


def test_deactivating_a_token_of_someone_else_does_nothing_and_answers_204(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """deactivating a token of someone else does nothing and answers 204
    @REV-01-S19 @assumption:REV-01-ASM-04
    """
    owner = _member(api, sign_in, unique)
    intruder = _member(api, sign_in, unique)
    token = f"fcm-{unique()}"
    payload = {"token": token, "platform": "android", "permission_granted": True}
    assert api.put("/devices", headers=owner, json=payload).status_code == 204

    unregistered = api.post("/devices/unregister", headers=intruder, json={"token": token})

    with engine.connect() as conn:
        active = conn.execute(
            text("SELECT active FROM device WHERE token = :t"), {"t": token}
        ).scalar_one()
    assert unregistered.status_code == 204
    assert active is True


class _UntrustedSmtp:
    def __init__(self, host: str, port: int, timeout: float) -> None:
        pass

    def __enter__(self) -> "_UntrustedSmtp":
        return self

    def __exit__(
        self, kind: type[BaseException] | None, e: BaseException | None, tb: TracebackType | None
    ) -> None:
        return None

    def starttls(self, context: ssl.SSLContext | None = None) -> None:
        raise ssl.SSLCertVerificationError("certificate verify failed: ana.rios@ejemplo.com")


def test_a_tls_failure_of_the_email_does_not_leave_the_address_in_the_log(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """a TLS failure of the email does not leave the address in the log
    @REV-01-S11 @assumption:REV-01-ASM-06
    """
    monkeypatch.setattr(email_module.smtplib, "SMTP", _UntrustedSmtp)
    monkeypatch.setattr(config, "email_mode", "smtp")
    monkeypatch.setattr(config, "smtp_host", "smtp.ejemplo.com")
    monkeypatch.setattr(config, "email_sender", "club@ejemplo.com")

    with caplog.at_level(logging.DEBUG):
        email_module.send(
            Message(recipient="ana.rios@ejemplo.com", subject="Tu enlace", body="Hola")
        )

    assert caplog.records
    assert "ana.rios@ejemplo.com" not in caplog.text
