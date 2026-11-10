"""API security: inputs, rate limits, log, headers and configuration."""

import json
import logging
import os
import smtplib
import socket
import ssl
import subprocess
import sys
import time
import tomllib
from collections.abc import Callable, Iterator
from datetime import date, datetime, timedelta
from pathlib import Path
from types import TracebackType
from zoneinfo import ZoneInfo

import httpx2
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.password_recovery.rules import Message
from app.shared.config import config
from app.shared import email as email_module
from app.modules.users.seed_admin import main as seed_admin
from app.main import create_app

API_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = API_ROOT.parents[1]
PASSWORD = "ClubNahuel1"
ZONE = ZoneInfo("America/Argentina/Buenos_Aires")


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _tomorrow() -> date:
    return datetime.now(ZONE).date() + timedelta(days=1)


def _sign_up_member(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> tuple[dict[str, str], str]:
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
    return _bearer(token), member_email


@pytest.fixture
def user_token(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> str:
    return _sign_up_member(api, sign_in, unique)[0]["Authorization"].removeprefix("Bearer ")


@pytest.fixture
def admin_token(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> str:
    s = unique()
    monkeypatch.setenv("ADMIN_CONTRASENA", PASSWORD)
    arguments = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert seed_admin(arguments) == 0
    token = sign_in(f"admin.{s}@club.com", PASSWORD)
    assert token is not None
    return token


@pytest.fixture
def court(api: TestClient, engine: Engine, unique: Callable[[], str]) -> str:
    """A five-a-side football court in a venue open from 08:00 to 23:00 every day."""
    s = unique()
    with engine.begin() as conn:
        space = conn.execute(
            text(
                "WITH s AS (INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id)"
                " INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id"
            ),
            {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1"},
        ).scalar_one()
    return str(space)


class _FakeSmtp:
    """An SMTP server that records the TLS context the client asks for and whether it logged in.

    With `invalid_certificate`, TLS fails as it does against a certificate that is not the server's.
    """

    contexts: list[ssl.SSLContext | None] = []
    logins: list[str] = []
    reject: bool = False
    invalid_certificate: bool = False

    def __init__(self, host: str, port: int, timeout: float) -> None:
        self.host = host

    def __enter__(self) -> "_FakeSmtp":
        return self

    def __exit__(
        self, kind: type[BaseException] | None, e: BaseException | None, tb: TracebackType | None
    ) -> None:
        return None

    def starttls(self, context: ssl.SSLContext | None = None) -> None:
        _FakeSmtp.contexts.append(context)
        if _FakeSmtp.invalid_certificate:
            raise ssl.SSLCertVerificationError("certificate verify failed: atacante.invalid")

    def login(self, user: str, password: str) -> None:
        _FakeSmtp.logins.append(user)

    def send_message(self, message: object) -> None:
        if _FakeSmtp.reject:
            raise smtplib.SMTPRecipientsRefused({"ana.rios@ejemplo.com": (550, b"no existe")})


@pytest.fixture
def fake_smtp(monkeypatch: pytest.MonkeyPatch) -> type[_FakeSmtp]:
    _FakeSmtp.contexts = []
    _FakeSmtp.logins = []
    _FakeSmtp.reject = False
    _FakeSmtp.invalid_certificate = False
    monkeypatch.setattr(email_module.smtplib, "SMTP", _FakeSmtp)
    monkeypatch.setattr(config, "email_mode", "smtp")
    monkeypatch.setattr(config, "smtp_host", "smtp.ejemplo.com")
    monkeypatch.setattr(config, "smtp_user", "club-smtp")
    monkeypatch.setattr(config, "smtp_password", "SmtpClave9")
    monkeypatch.setattr(config, "email_sender", "club@ejemplo.com")
    return _FakeSmtp


def _message() -> Message:
    return Message(recipient="ana.rios@ejemplo.com", subject="Tu enlace", body="Entrá al enlace")


def test_the_email_requires_a_valid_certificate_for_the_server_name(
    fake_smtp: type[_FakeSmtp],
) -> None:
    """sending email asks for a TLS that verifies certificate and name @REV-01-S1"""
    email_module.send(_message())

    context = fake_smtp.contexts[0]
    assert isinstance(context, ssl.SSLContext)
    assert context.verify_mode == ssl.CERT_REQUIRED
    assert context.check_hostname is True


def test_with_an_invalid_certificate_the_credentials_are_not_sent(
    fake_smtp: type[_FakeSmtp], caplog: pytest.LogCaptureFixture
) -> None:
    """with an invalid certificate neither the SMTP user nor password is handed over
    @REV-01-S1 @assumption:REV-01-ASM-06
    """
    fake_smtp.invalid_certificate = True

    with caplog.at_level(logging.DEBUG):
        email_module.send(_message())

    assert fake_smtp.logins == []
    assert caplog.records
    assert "ana.rios@ejemplo.com" not in caplog.text


def test_recovery_answers_the_same_even_if_the_email_does_not_go_out(
    api: TestClient, fake_smtp: type[_FakeSmtp]
) -> None:
    """whoever asks to recover sees the same even if the email TLS fails
    @REV-01-S1 @assumption:REV-01-ASM-06
    """
    fake_smtp.invalid_certificate = True

    r = api.post("/password-recovery", json={"email": "nadie.tls@correo.com"})

    assert r.status_code == 202


@pytest.mark.parametrize("hours", [10**12, 5, 0, -1, None, "x"])
def test_a_booking_with_hours_out_of_range_is_invalid_data(
    api: TestClient, user_token: str, court: str, hours: object
) -> None:
    """a booking with outsized hours is rejected as invalid data @REV-01-S2"""
    r = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={
            "space_id": court,
            "date": _tomorrow().isoformat(),
            "start_hour": "10:00",
            "hours": hours,
        },
    )

    assert r.status_code == 422
    assert "hours" in r.json()["errors"]


def test_a_four_hour_booking_is_accepted(api: TestClient, user_token: str, court: str) -> None:
    """the four-hour edge is still accepted @REV-01-S2"""
    r = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={
            "space_id": court,
            "date": _tomorrow().isoformat(),
            "start_hour": "10:00",
            "hours": 4,
        },
    )

    assert r.status_code == 201


@pytest.mark.parametrize(("start", "hours"), [("23:00", 4), ("23:00", 1), ("10:00", 1)])
def test_a_booking_at_the_end_of_the_calendar_is_invalid_data(
    api: TestClient, user_token: str, court: str, start: str, hours: int
) -> None:
    """a booking that ends after the last representable day is invalid @REV-01-S3"""
    r = api.post(
        "/bookings",
        headers=_bearer(user_token),
        json={"space_id": court, "date": "9999-12-31", "start_hour": start, "hours": hours},
    )

    assert r.status_code == 422
    assert "date" in r.json()["errors"]


@pytest.mark.parametrize("page", [2**70, 10_001, 0, "x"])
def test_an_out_of_range_page_of_the_global_history_is_invalid_data(
    api: TestClient, admin_token: str, page: object
) -> None:
    """asking for a huge page of the global history is rejected as invalid data @REV-01-S4"""
    r = api.get("/bookings/all", headers=_bearer(admin_token), params={"page": page})

    assert r.status_code == 422
    assert "page" in r.json()["errors"]


def test_the_last_allowed_page_of_the_global_history_answers(
    api: TestClient, admin_token: str
) -> None:
    """the edge of page 10000 still answers @REV-01-S4 @assumption:REV-01-ASM-02"""
    r = api.get("/bookings/all", headers=_bearer(admin_token), params={"page": 10_000})

    assert r.status_code == 200
    assert r.json()["bookings"] == []


NULL_BYTE = "Ana\x00Rios"
VENUE = {"address": "Av. Vergara 1850", "opens_at": "08:00", "closes_at": "23:00", "open_days": [1]}
SPACE = {
    "venue_id": "00000000-0000-7000-8000-000000000001",
    "kind": "F5",
    "covered": False,
    "lit": True,
    "price_per_hour": 1,
}


def test_the_api_does_not_use_a_certifi_with_a_known_vulnerability() -> None:
    """the API does not depend on a certifi version with a known vulnerability @REV-01-S10"""
    lock = tomllib.loads((API_ROOT / "uv.lock").read_text(encoding="utf-8"))
    version = next(p["version"] for p in lock["package"] if p["name"] == "certifi")

    assert tuple(int(n) for n in version.split(".")) >= (2026, 10, 18)


def test_a_rejection_from_the_mail_server_does_not_leave_the_address_in_the_log(
    fake_smtp: type[_FakeSmtp], caplog: pytest.LogCaptureFixture
) -> None:
    """a rejection from the mail server does not leave the person's address in the log
    @REV-01-S11
    """
    fake_smtp.reject = True

    with caplog.at_level(logging.DEBUG):
        email_module.send(_message())

    assert caplog.records
    assert "ana.rios@ejemplo.com" not in caplog.text
    assert "SmtpClave9" not in caplog.text


def _free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])


@pytest.fixture
def server(api: TestClient, tmp_path: Path) -> Iterator[tuple[str, Path]]:
    """The API served by uvicorn as in Render, with its output in a file."""
    port = _free_port()
    output = tmp_path / "uvicorn.log"
    with output.open("w", encoding="utf-8") as file:
        process = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1"]
            + ["--port", str(port)],
            cwd=API_ROOT,
            stdout=file,
            stderr=subprocess.STDOUT,
            env={**os.environ, "PYTHONUTF8": "1"},
        )
        base = f"http://127.0.0.1:{port}"
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline and process.poll() is None:
            try:
                httpx2.get(f"{base}/yo", timeout=2)
                break
            except httpx2.HTTPError:
                time.sleep(0.5)
        yield base, output
        process.terminate()
        process.wait(timeout=30)


@pytest.mark.parametrize("line_break", ["%0a", "%0d"])
def test_a_path_with_line_breaks_does_not_forge_the_log(
    api: TestClient, caplog: pytest.LogCaptureFixture, line_break: str
) -> None:
    """a path with line breaks cannot forge a log line @REV-01-S13"""
    forged = (
        f"/bookings/1{line_break}2026-10-20 00:00:00,000 ERROR clubnahuelmosse.errores FALSO/cancel"
    )

    with caplog.at_level(logging.INFO):
        api.post(forged)

    messages = [r.getMessage() for r in caplog.records]
    assert any("/bookings/1" in m for m in messages)
    assert not any("\n" in m or "\r" in m for m in messages)


def test_secrets_do_not_reach_the_log_or_the_responses(
    api: TestClient, user_token: str, caplog: pytest.LogCaptureFixture
) -> None:
    """passwords, tokens and recovery codes do not reach the log @REV-01-S14"""
    with caplog.at_level(logging.DEBUG):
        responses = [
            api.put(
                "/password-recovery",
                json={"code": "cod-secreto-7Q", "new_password": ["Clave9Secreta"]},
            ),
            api.post("/password-recovery/check", json={"code": "cod-secreto-7Q"}),
            api.get("/me", headers={"Authorization": "Bearer token-secreto-9Z"}),
            api.post("/register", json={"email": "ana@correo.com", "password": ["Clave9Secreta"]}),
            api.put(
                "/me/password",
                headers=_bearer(user_token),
                json={"current_password": ["Clave9Secreta"], "new_password": ["Clave9Secreta"]},
            ),
        ]

    texts = caplog.text + "".join(r.text for r in responses)
    assert "Clave9Secreta" not in texts
    assert "cod-secreto-7Q" not in texts
    assert "token-secreto-9Z" not in texts


def test_the_versioned_contract_matches_the_api() -> None:
    """the versioned OpenAPI contract matches what the API publishes @REV-01-S15"""
    versioned = json.loads((API_ROOT / "openapi.json").read_text(encoding="utf-8"))

    assert versioned == create_app().openapi()


def test_the_api_starts_with_the_emulator_and_a_demo_project(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """with the emulator, a demo project and no credentials the API starts
    @REV-01-S18 @assumption:REV-01-ASM-10
    """
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.delenv("GOOGLE_APPLICATION_CREDENTIALS", raising=False)
    monkeypatch.setattr(config, "firebase_project_id", "demo-clubnahuelmosse")
    monkeypatch.setattr(config, "firebase_credentials_json", "")

    assert isinstance(create_app(), FastAPI)


def _owner(engine: Engine, token: str) -> str:
    with engine.connect() as conn:
        return str(
            conn.execute(
                text(
                    "SELECT u.email FROM device d JOIN app_user u ON u.id = d.user_id"
                    " WHERE d.token = :t AND d.active"
                ),
                {"t": token},
            ).scalar_one()
        )


def test_someone_elses_token_does_not_change_owner(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """registering someone else's device token does not take it from them
    @REV-01-S19 @assumption:REV-01-ASM-04
    """
    owner, owner_email = _sign_up_member(api, sign_in, unique)
    intruder, _ = _sign_up_member(api, sign_in, unique)
    token = f"fcm-{unique()}"
    payload = {"token": token, "platform": "android", "permission_granted": True}

    assert api.put("/devices", headers=owner, json=payload).status_code == 204
    attempt = api.put("/devices", headers=intruder, json=payload)
    unregistration = api.post("/devices/unregister", headers=intruder, json={"token": token})

    assert attempt.status_code == 204
    assert unregistration.status_code == 204
    assert _owner(engine, token) == owner_email


def test_an_unregistered_token_goes_to_whoever_registers_it(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """a phone that signed out goes to the next person
    @REV-01-S19 @assumption:REV-01-ASM-04
    """
    first, _ = _sign_up_member(api, sign_in, unique)
    second, second_email = _sign_up_member(api, sign_in, unique)
    token = f"fcm-{unique()}"
    payload = {"token": token, "platform": "android", "permission_granted": True}

    assert api.put("/devices", headers=first, json=payload).status_code == 204
    assert api.post("/devices/unregister", headers=first, json={"token": token}).status_code == 204
    assert api.put("/devices", headers=second, json=payload).status_code == 204

    assert _owner(engine, token) == second_email
