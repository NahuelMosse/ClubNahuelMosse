"""The configuration and the admin seeding read English names only (ENG-23)."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
from pathlib import Path
from typing import Any

import pytest

from app.shared.config import Settings, config
from app.shared.message import Message

ROOT = Path(__file__).resolve().parents[4]
SPANISH_VARIABLES = [
    "FIREBASE_CREDENCIALES_JSON", "URL_PUBLICA", "CORREO_MODO", "SMTP_PUERTO", "SMTP_USUARIO",
    "SMTP_CONTRASENA", "CORREO_REMITENTE", "PRUEBAS", "RECORDATORIOS_CADA", "ADMIN_CONTRASENA",
]  # fmt: skip
ENGLISH_VARIABLES = [
    "FIREBASE_CREDENTIALS_JSON", "PUBLIC_URL", "EMAIL_MODE", "SMTP_PORT", "SMTP_USER",
    "SMTP_PASSWORD", "EMAIL_SENDER", "E2E_TESTING", "REMINDERS_EVERY", "ADMIN_PASSWORD",
    "SMTP_HOST", "BREVO_API_KEY", "FIREBASE_API_KEY",
]  # fmt: skip
# (field, English variable, value, default)
FIELDS: list[tuple[str, str, Any, Any]] = [
    ("firebase_credentials_json", "FIREBASE_CREDENTIALS_JSON", "{}", ""),
    ("public_url", "PUBLIC_URL", "https://api.en", "http://localhost:8000"),
    ("smtp_port", "SMTP_PORT", 2525, 587),
    ("smtp_user", "SMTP_USER", "en", ""),
    ("smtp_password", "SMTP_PASSWORD", "secret-en", ""),
    ("email_sender", "EMAIL_SENDER", "en@club.test", ""),
    ("reminders_every", "REMINDERS_EVERY", 7, 30),
]  # fmt: skip
SPANISH_VALUES = {
    "FIREBASE_CREDENCIALES_JSON": "{}", "URL_PUBLICA": "https://api.es", "SMTP_PUERTO": "465",
    "SMTP_USUARIO": "es", "SMTP_CONTRASENA": "clave-es", "CORREO_REMITENTE": "es@club.test",
    "RECORDATORIOS_CADA": "9", "CORREO_MODO": "brevo", "PRUEBAS": "1",
}  # fmt: skip


@pytest.fixture(autouse=True)
def clean_env(monkeypatch: pytest.MonkeyPatch) -> None:
    for variable in SPANISH_VARIABLES + ENGLISH_VARIABLES:
        monkeypatch.delenv(variable, raising=False)


def test_the_configuration_reads_each_variable_by_its_english_name_only(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the configuration reads each variable by its English name only @ENG-01-S4 @ENG-23-S4 @assumption:ENG-23-ASM-02"""
    spanish_of = {
        "FIREBASE_CREDENTIALS_JSON": "FIREBASE_CREDENCIALES_JSON", "PUBLIC_URL": "URL_PUBLICA",
        "SMTP_PORT": "SMTP_PUERTO", "SMTP_USER": "SMTP_USUARIO", "SMTP_PASSWORD": "SMTP_CONTRASENA",
        "EMAIL_SENDER": "CORREO_REMITENTE", "REMINDERS_EVERY": "RECORDATORIOS_CADA",
    }  # fmt: skip
    for field, english, value, default in FIELDS:
        monkeypatch.setenv(english, str(value))
        assert getattr(Settings(_env_file=None), field) == value, english
        monkeypatch.delenv(english)

        monkeypatch.setenv(spanish_of[english], SPANISH_VALUES[spanish_of[english]])
        assert getattr(Settings(_env_file=None), field) == default, spanish_of[english]
        monkeypatch.delenv(spanish_of[english])


def test_with_e2e_testing_0_and_the_old_spanish_variable_at_1_the_test_routes_are_not_mounted(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """with E2E_TESTING=0 and the old Spanish variable at 1 the test routes are not mounted @ENG-01-S4 @ENG-23-S4"""
    monkeypatch.setenv("E2E_TESTING", "0")
    monkeypatch.setenv("PRUEBAS", "1")
    settings = Settings(_env_file=None)
    assert settings.e2e_testing is False

    monkeypatch.delenv("E2E_TESTING")
    assert Settings(_env_file=None).e2e_testing is False

    monkeypatch.setenv("E2E_TESTING", "1")
    assert Settings(_env_file=None).e2e_testing is True


def test_with_email_mode_outbox_the_recovery_email_goes_to_the_outbox_and_the_old_spanish_value_is_refused(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """with EMAIL_MODE=outbox the recovery email goes to the outbox and the old Spanish value is refused @assumption:ENG-01-ASM-01 @assumption:ENG-23-ASM-02"""
    from app.shared import email as email_module

    monkeypatch.setenv("EMAIL_MODE", "outbox")
    mode = Settings(_env_file=None).email_mode
    calls: list[str] = []
    monkeypatch.setattr(config, "email_mode", mode)
    monkeypatch.setitem(email_module._SENDERS, "outbox", lambda _m: calls.append("outbox"))
    monkeypatch.setitem(email_module._SENDERS, "smtp", lambda _m: calls.append("smtp"))

    email_module.send(Message(recipient="a@b.test", subject="x", body="y"))

    assert mode == "outbox"
    assert calls == ["outbox"]

    monkeypatch.setenv("EMAIL_MODE", "buzon")
    with pytest.raises(ValueError):
        Settings(_env_file=None)


def test_render_yaml_and_scripts_e2e_sh_use_the_english_names_and_the_configuration_reads_them(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """render.yaml and scripts/e2e.sh use the English names and the configuration reads them @assumption:ENG-01-ASM-02 @ENG-23-S4"""
    render = (ROOT / "render.yaml").read_text(encoding="utf-8")
    e2e = (ROOT / "scripts" / "e2e.sh").read_text(encoding="utf-8")
    for name in (
        "PUBLIC_URL",
        "EMAIL_MODE",
        "EMAIL_SENDER",
        "SMTP_PORT",
        "SMTP_USER",
        "SMTP_PASSWORD",
    ):
        assert f"key: {name}" in render
    assert "E2E_TESTING=1 EMAIL_MODE=outbox" in e2e

    monkeypatch.setenv("E2E_TESTING", "1")
    monkeypatch.setenv("EMAIL_MODE", "outbox")
    settings = Settings(_env_file=None)
    assert settings.e2e_testing is True
    assert settings.email_mode == "outbox"


def test_the_configuration_reads_each_variable_in_english_only_also_the_brevo_mode(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the configuration reads each variable in English only, also the brevo mode @ENG-13-S3 @ENG-23-S4"""
    for variable, field in (
        ("SMTP_HOST", "smtp_host"),
        ("BREVO_API_KEY", "brevo_api_key"),
        ("FIREBASE_API_KEY", "firebase_api_key"),
    ):
        monkeypatch.setenv(variable, "value")
        assert getattr(Settings(_env_file=None), field) == "value", variable
        monkeypatch.delenv(variable)

    for mode in ("outbox", "smtp", "brevo"):
        monkeypatch.setenv("EMAIL_MODE", mode)
        assert Settings(_env_file=None).email_mode == mode, mode


def test_the_admin_password_is_read_from_admin_password_only(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the admin password is read from ADMIN_PASSWORD only @ENG-13-S3 @assumption:ENG-23-ASM-02"""
    from app.modules.users import seed_admin

    class NoDatabase(Exception):
        pass

    def no_database() -> Any:
        raise NoDatabase

    monkeypatch.setattr(seed_admin, "engine", no_database)
    argv = [
        "--email", "a@b.c", "--first-name", "A", "--last-name", "B", "--dni", "1",
        "--birth-date", "2000-01-01",
    ]  # fmt: skip
    assert seed_admin.main(argv) == 2

    monkeypatch.setenv("ADMIN_CONTRASENA", "Clave1234")
    assert seed_admin.main(argv) == 2

    monkeypatch.setenv("ADMIN_PASSWORD", "Clave1234")
    with pytest.raises(NoDatabase):
        seed_admin.main(argv)


def test_scripts_e2e_sh_seeds_the_admin_with_the_users_seed_admin_module_and_its_english_options() -> (
    None
):
    """scripts/e2e.sh seeds the admin with the users.seed_admin module and its English options @assumption:ENG-13-ASM-04 @ENG-23-S4"""
    script = (ROOT / "scripts" / "e2e.sh").read_text(encoding="utf-8")

    assert "python -m app.modules.users.seed_admin" in script
    assert '--email "$ADMIN_EMAIL"' in script
    for option in ("--first-name", "--last-name", "--birth-date"):
        assert option in script
    for old in ("--correo", "--nombre", "--apellido", "--nacimiento"):
        assert old not in script


def test_with_only_the_old_spanish_variables_set_the_configuration_takes_the_defaults_of_unset_variables(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """with only the old Spanish variables set the configuration takes the defaults of unset variables @assumption:ENG-23-ASM-02"""
    defaults = Settings(_env_file=None)
    for variable, value in SPANISH_VALUES.items():
        monkeypatch.setenv(variable, value)
    monkeypatch.setenv("ADMIN_CONTRASENA", "Clave1234")

    settings = Settings(_env_file=None)

    assert settings.model_dump() == defaults.model_dump()
