"""The configuration reads each variable by its English name and by today's."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
from pathlib import Path
from typing import Any

import pytest

from app.shared.config import Settings, config
from app.shared.message import Message

ROOT = Path(__file__).resolve().parents[4]
ENVIRONMENT_VARIABLES = [
    "FIREBASE_CREDENTIALS_JSON", "FIREBASE_CREDENCIALES_JSON", "PUBLIC_URL", "URL_PUBLICA",
    "EMAIL_MODE", "CORREO_MODO", "SMTP_PORT", "SMTP_PUERTO", "SMTP_USER", "SMTP_USUARIO",
    "SMTP_PASSWORD", "SMTP_CONTRASENA", "EMAIL_SENDER", "CORREO_REMITENTE", "E2E_TESTING",
    "PRUEBAS", "REMINDERS_EVERY", "RECORDATORIOS_CADA",
]  # fmt: skip
# (field, English variable, value, today's variable, other value)
FIELDS: list[tuple[str, str, Any, str, Any]] = [
    ("firebase_credentials_json", "FIREBASE_CREDENTIALS_JSON", "{}", "FIREBASE_CREDENCIALES_JSON", "[]"),
    ("public_url", "PUBLIC_URL", "https://api.en", "URL_PUBLICA", "https://api.es"),
    ("smtp_port", "SMTP_PORT", 2525, "SMTP_PUERTO", 465),
    ("smtp_user", "SMTP_USER", "en", "SMTP_USUARIO", "es"),
    ("smtp_password", "SMTP_PASSWORD", "clave-en", "SMTP_CONTRASENA", "clave-es"),
    ("email_sender", "EMAIL_SENDER", "en@club.test", "CORREO_REMITENTE", "es@club.test"),
    ("reminders_every", "REMINDERS_EVERY", 7, "RECORDATORIOS_CADA", 9),
]  # fmt: skip


@pytest.fixture(autouse=True)
def clean_env(monkeypatch: pytest.MonkeyPatch) -> None:
    for variable in ENVIRONMENT_VARIABLES:
        monkeypatch.delenv(variable, raising=False)


def test_the_configuration_reads_each_variable_by_its_english_name_and_by_today_s_and_the_english_one_wins(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the configuration reads each variable by its English name and by today's, and the English one wins @ENG-01-S4"""
    for field, english, value, spanish, other in FIELDS:
        monkeypatch.setenv(english, str(value))
        assert getattr(Settings(_env_file=None), field) == value, english
        monkeypatch.delenv(english)

        monkeypatch.setenv(spanish, str(other))
        assert getattr(Settings(_env_file=None), field) == other, spanish

        monkeypatch.setenv(english, str(value))
        assert getattr(Settings(_env_file=None), field) == value, f"{english} wins over {spanish}"
        monkeypatch.delenv(english)
        monkeypatch.delenv(spanish)


def test_with_e2e_testing_0_and_pruebas_1_the_test_routes_are_not_mounted(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """with E2E_TESTING=0 and PRUEBAS=1 the test routes are not mounted @ENG-01-S4"""
    monkeypatch.setenv("E2E_TESTING", "0")
    monkeypatch.setenv("PRUEBAS", "1")
    settings = Settings(_env_file=None)
    assert settings.e2e_testing is False

    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr(config, "e2e_testing", settings.e2e_testing)
    from app.main import create_app

    routes = {getattr(r, "path", "") for r in create_app().routes}
    assert not any(r.startswith("/_pruebas") for r in routes)

    monkeypatch.delenv("E2E_TESTING")
    assert Settings(_env_file=None).e2e_testing is True


@pytest.mark.parametrize(
    ("variable", "value"), [("EMAIL_MODE", "outbox"), ("CORREO_MODO", "buzon")]
)
def test_with_email_mode_outbox_or_correo_modo_buzon_the_recovery_email_goes_to_the_outbox_and_not_to_smtp(
    monkeypatch: pytest.MonkeyPatch, variable: str, value: str
) -> None:
    """with EMAIL_MODE=outbox or CORREO_MODO=buzon the recovery email goes to the outbox and not to SMTP @assumption:ENG-01-ASM-01"""
    from app.shared import email as email_module

    monkeypatch.setenv(variable, value)
    mode = Settings(_env_file=None).email_mode
    calls: list[str] = []
    monkeypatch.setattr(config, "email_mode", mode)
    monkeypatch.setitem(email_module._SENDERS, "outbox", lambda _m: calls.append("buzon"))
    monkeypatch.setitem(email_module._SENDERS, "smtp", lambda _m: calls.append("smtp"))

    email_module.send(Message(recipient="a@b.test", subject="x", body="y"))

    assert mode == "outbox"
    assert calls == ["buzon"]


def test_render_yaml_and_scripts_e2e_sh_keep_today_s_names_and_the_configuration_reads_them(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """render.yaml and scripts/e2e.sh keep today's names and the configuration reads them @assumption:ENG-01-ASM-02"""
    render = (ROOT / "render.yaml").read_text(encoding="utf-8")
    e2e = (ROOT / "scripts" / "e2e.sh").read_text(encoding="utf-8")
    for name in ("URL_PUBLICA", "CORREO_MODO", "CORREO_REMITENTE"):
        assert f"key: {name}" in render
    assert "PRUEBAS=1 CORREO_MODO=buzon" in e2e

    monkeypatch.setenv("PRUEBAS", "1")
    monkeypatch.setenv("CORREO_MODO", "buzon")
    settings = Settings(_env_file=None)
    assert settings.e2e_testing is True
    assert settings.email_mode == "outbox"
