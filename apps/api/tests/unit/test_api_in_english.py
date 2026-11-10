"""The API is in English on today's main, with the same contract and the same configuration."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import subprocess
from pathlib import Path
from typing import Any

import pytest

from app.shared.config import Settings

ROOT = Path(__file__).resolve().parents[4]
APP = ROOT / "apps" / "api" / "app"
REFERENCE_MAIN = "1ee70de"

MODULES = {
    "venues", "users", "session", "password_recovery",
    "spaces", "availability", "notifications", "bookings",
}  # fmt: skip
BASE_FILES = {"main.py", "health.py", "e2e_support.py"}
# Today's file names, in Spanish, that cannot be left anywhere in app.
SPANISH_STEMS = {
    "casos_de_uso", "reglas", "repositorio", "rutas", "rutas_cuenta", "rutas_registro",
    "almacen", "barrido", "disponibilidad", "administradores", "baja", "contrasena",
    "registro", "sembrar_admin", "usuario_actual", "salud", "pruebas", "cuerpo", "entradas",
    "errores", "errores_http", "identidad", "respuestas", "zona", "credencial_firebase",
    "correo", "perfil",
}  # fmt: skip
SPANISH_MODULES = {
    "sedes", "usuarios", "sesion", "recuperacion", "espacios", "horarios", "notificaciones",
    "reservas",
}  # fmt: skip

VARIABLES = [
    "FIREBASE_CREDENTIALS_JSON", "FIREBASE_CREDENCIALES_JSON", "PUBLIC_URL", "URL_PUBLICA",
    "EMAIL_MODE", "CORREO_MODO", "SMTP_PORT", "SMTP_PUERTO", "SMTP_USER", "SMTP_USUARIO",
    "SMTP_PASSWORD", "SMTP_CONTRASENA", "EMAIL_SENDER", "CORREO_REMITENTE", "E2E_TESTING",
    "PRUEBAS", "REMINDERS_EVERY", "RECORDATORIOS_CADA", "ADMIN_PASSWORD", "ADMIN_CONTRASENA",
    "SMTP_HOST", "BREVO_API_KEY", "FIREBASE_API_KEY",
]  # fmt: skip
# (field, English variable, value, today's variable, other value)
FIELDS: list[tuple[str, str, Any, str, Any]] = [
    ("firebase_credentials_json", "FIREBASE_CREDENTIALS_JSON", "{}", "FIREBASE_CREDENCIALES_JSON", "[]"),
    ("public_url", "PUBLIC_URL", "https://api.en", "URL_PUBLICA", "https://api.es"),
    ("email_mode", "EMAIL_MODE", "smtp", "CORREO_MODO", "brevo"),
    ("smtp_port", "SMTP_PORT", 2525, "SMTP_PUERTO", 465),
    ("smtp_user", "SMTP_USER", "en", "SMTP_USUARIO", "es"),
    ("smtp_password", "SMTP_PASSWORD", "clave-en", "SMTP_CONTRASENA", "clave-es"),
    ("email_sender", "EMAIL_SENDER", "en@club.test", "CORREO_REMITENTE", "es@club.test"),
    ("e2e_testing", "E2E_TESTING", True, "PRUEBAS", False),
    ("reminders_every", "REMINDERS_EVERY", 7, "RECORDATORIOS_CADA", 9),
]  # fmt: skip


@pytest.fixture
def clean_env(monkeypatch: pytest.MonkeyPatch) -> pytest.MonkeyPatch:
    for variable in VARIABLES:
        monkeypatch.delenv(variable, raising=False)
    return monkeypatch


def test_the_api_base_and_modules_are_named_as_the_glossary_says_and_none_is_left_in_spanish() -> (
    None
):
    """the API base and modules are named as the glossary says and none is left in Spanish @ENG-13-S1 @assumption:ENG-13-ASM-02 @assumption:ENG-13-ASM-03"""
    folders = {
        p.name for p in (APP / "modules").iterdir() if p.is_dir() and p.name != "__pycache__"
    }
    assert folders == MODULES
    assert {p.name for p in APP.glob("*.py")} >= BASE_FILES
    in_spanish = sorted(
        str(p.relative_to(APP))
        for p in APP.rglob("*.py")
        if p.stem in SPANISH_STEMS or p.parent.name in SPANISH_MODULES
    )
    assert in_spanish == []


def _resolve(node: Any, components: dict[str, Any], seen: tuple[str, ...] = ()) -> Any:
    """The node with each `$ref` replaced by its structure, without the schema name."""
    if isinstance(node, list):
        return [_resolve(n, components, seen) for n in node]
    if not isinstance(node, dict):
        return node
    ref = node.get("$ref")
    if ref is not None:
        name = ref.rsplit("/", 1)[-1]
        if name in seen:
            return "<recursivo>"
        schema = {k: v for k, v in components[name].items() if k != "title"}
        return _resolve(schema, components, (*seen, name))
    return {k: _resolve(v, components, seen) for k, v in node.items()}


def _shape(contract: dict[str, Any]) -> dict[str, Any]:
    """What the contract promises: routes, methods, codes, fields, parameters, operationId and security."""
    components = contract.get("components", {}).get("schemas", {})
    shape: dict[str, Any] = {}
    for route, methods in contract["paths"].items():
        for method, operation in methods.items():
            shape[f"{method.upper()} {route}"] = _resolve(
                {
                    "operationId": operation.get("operationId"),
                    "security": operation.get("security"),
                    "parameters": operation.get("parameters"),
                    "requestBody": operation.get("requestBody"),
                    "responses": operation.get("responses"),
                },
                components,
            )
    return shape


def test_the_configuration_reads_each_variable_in_english_and_in_spanish_also_the_brevo_mode(
    clean_env: pytest.MonkeyPatch,
) -> None:
    """the configuration reads each variable in English and in Spanish, also the brevo mode @ENG-13-S3"""
    for field, english, value, spanish, other in FIELDS:
        clean_env.setenv(english, str(value))
        assert getattr(Settings(_env_file=None), field) == value, english
        clean_env.delenv(english)

        clean_env.setenv(spanish, str(other))
        assert getattr(Settings(_env_file=None), field) == other, spanish

        clean_env.setenv(english, str(value))
        assert getattr(Settings(_env_file=None), field) == value, f"{english} wins over {spanish}"
        clean_env.delenv(english)
        clean_env.delenv(spanish)

    for variable, field in (
        ("SMTP_HOST", "smtp_host"),
        ("BREVO_API_KEY", "brevo_api_key"),
        ("FIREBASE_API_KEY", "firebase_api_key"),
    ):
        clean_env.setenv(variable, "valor")
        assert getattr(Settings(_env_file=None), field) == "valor", variable
        clean_env.delenv(variable)

    for mode, expected in (
        ("outbox", "outbox"),
        ("buzon", "outbox"),
        ("smtp", "smtp"),
        ("brevo", "brevo"),
    ):
        clean_env.setenv("EMAIL_MODE", mode)
        assert Settings(_env_file=None).email_mode == expected, mode


def test_the_admin_password_is_read_from_admin_password_and_from_its_legacy_spanish_name(
    clean_env: pytest.MonkeyPatch,
) -> None:
    """the admin password is read from ADMIN_PASSWORD and from ADMIN_CONTRASENA, the English one wins @ENG-13-S3"""
    from app.modules.users import seed_admin

    class NoDatabase(Exception):
        pass

    def no_database() -> Any:
        raise NoDatabase

    clean_env.setattr(seed_admin, "engine", no_database)
    argv = [
        "--correo",
        "a@b.c",
        "--nombre",
        "A",
        "--apellido",
        "B",
        "--dni",
        "1",
        "--nacimiento",
        "2000-01-01",
    ]
    assert seed_admin.main(argv) == 2
    for variable in ("ADMIN_PASSWORD", "ADMIN_CONTRASENA"):
        clean_env.setenv(variable, "Clave1234")
        with pytest.raises(NoDatabase):
            seed_admin.main(argv)
        clean_env.delenv(variable)


def test_the_branch_contains_main_at_1ee70de() -> None:
    """the branch contains main at 1ee70de @ENG-13-S4"""
    contains = subprocess.run(
        ["git", "merge-base", "--is-ancestor", REFERENCE_MAIN, "HEAD"], cwd=ROOT
    ).returncode
    assert contains == 0


def test_scripts_e2e_sh_seeds_the_admin_with_the_users_seed_admin_module_and_the_same_options() -> (
    None
):
    """scripts/e2e.sh seeds the admin with the users.seed_admin module and the same options @assumption:ENG-13-ASM-04"""
    script = (ROOT / "scripts" / "e2e.sh").read_text(encoding="utf-8")

    assert "python -m app.modules.users.seed_admin" in script
    assert "sembrar_admin" not in script
    assert '--correo "$ADMIN_CORREO"' in script
