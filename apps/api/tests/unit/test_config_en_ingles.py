"""La configuración lee cada variable con su nombre en inglés y con el de hoy."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
from pathlib import Path
from typing import Any

import pytest

from app.shared.config import Settings, config
from app.shared.message import Message

RAIZ = Path(__file__).resolve().parents[4]
VARIABLES_DE_ENTORNO = [
    "FIREBASE_CREDENTIALS_JSON", "FIREBASE_CREDENCIALES_JSON", "PUBLIC_URL", "URL_PUBLICA",
    "EMAIL_MODE", "CORREO_MODO", "SMTP_PORT", "SMTP_PUERTO", "SMTP_USER", "SMTP_USUARIO",
    "SMTP_PASSWORD", "SMTP_CONTRASENA", "EMAIL_SENDER", "CORREO_REMITENTE", "E2E_TESTING",
    "PRUEBAS", "REMINDERS_EVERY", "RECORDATORIOS_CADA",
]  # fmt: skip
# (campo, variable en inglés, valor, variable de hoy, otro valor)
CAMPOS: list[tuple[str, str, Any, str, Any]] = [
    ("firebase_credentials_json", "FIREBASE_CREDENTIALS_JSON", "{}", "FIREBASE_CREDENCIALES_JSON", "[]"),
    ("public_url", "PUBLIC_URL", "https://api.en", "URL_PUBLICA", "https://api.es"),
    ("smtp_port", "SMTP_PORT", 2525, "SMTP_PUERTO", 465),
    ("smtp_user", "SMTP_USER", "en", "SMTP_USUARIO", "es"),
    ("smtp_password", "SMTP_PASSWORD", "clave-en", "SMTP_CONTRASENA", "clave-es"),
    ("email_sender", "EMAIL_SENDER", "en@club.test", "CORREO_REMITENTE", "es@club.test"),
    ("reminders_every", "REMINDERS_EVERY", 7, "RECORDATORIOS_CADA", 9),
]  # fmt: skip


@pytest.fixture(autouse=True)
def entorno_limpio(monkeypatch: pytest.MonkeyPatch) -> None:
    for variable in VARIABLES_DE_ENTORNO:
        monkeypatch.delenv(variable, raising=False)


def test_la_configuracion_lee_cada_variable_con_su_nombre_en_ingles_y_con_el_de_hoy_y_gana_la_inglesa(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """la configuración lee cada variable con su nombre en inglés y con el de hoy, y gana la inglesa @ENG-01-S4"""
    for campo, ingles, valor, castellano, otro in CAMPOS:
        monkeypatch.setenv(ingles, str(valor))
        assert getattr(Settings(_env_file=None), campo) == valor, ingles
        monkeypatch.delenv(ingles)

        monkeypatch.setenv(castellano, str(otro))
        assert getattr(Settings(_env_file=None), campo) == otro, castellano

        monkeypatch.setenv(ingles, str(valor))
        assert getattr(Settings(_env_file=None), campo) == valor, f"{ingles} gana a {castellano}"
        monkeypatch.delenv(ingles)
        monkeypatch.delenv(castellano)


def test_con_e2e_testing_0_y_pruebas_1_las_rutas_de_prueba_no_se_montan(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """con E2E_TESTING=0 y PRUEBAS=1 las rutas de prueba no se montan @ENG-01-S4"""
    monkeypatch.setenv("E2E_TESTING", "0")
    monkeypatch.setenv("PRUEBAS", "1")
    ajustes = Settings(_env_file=None)
    assert ajustes.e2e_testing is False

    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr(config, "e2e_testing", ajustes.e2e_testing)
    from app.main import create_app

    rutas = {getattr(r, "path", "") for r in create_app().routes}
    assert not any(r.startswith("/_pruebas") for r in rutas)

    monkeypatch.delenv("E2E_TESTING")
    assert Settings(_env_file=None).e2e_testing is True


@pytest.mark.parametrize(
    ("variable", "valor"), [("EMAIL_MODE", "outbox"), ("CORREO_MODO", "buzon")]
)
def test_con_email_mode_outbox_o_correo_modo_buzon_el_correo_de_recuperacion_va_al_buzon_y_no_a_smtp(
    monkeypatch: pytest.MonkeyPatch, variable: str, valor: str
) -> None:
    """con EMAIL_MODE=outbox o CORREO_MODO=buzon el correo de recuperación va al buzón y no a SMTP @assumption:ENG-01-ASM-01"""
    from app.shared import email as correo

    monkeypatch.setenv(variable, valor)
    modo = Settings(_env_file=None).email_mode
    llamadas: list[str] = []
    monkeypatch.setattr(config, "email_mode", modo)
    monkeypatch.setitem(correo._SENDERS, "outbox", lambda _m: llamadas.append("buzon"))
    monkeypatch.setitem(correo._SENDERS, "smtp", lambda _m: llamadas.append("smtp"))

    correo.send(Message(recipient="a@b.test", subject="x", body="y"))

    assert modo == "outbox"
    assert llamadas == ["buzon"]


def test_render_yaml_y_scripts_e2e_sh_siguen_con_los_nombres_de_hoy_y_la_configuracion_los_lee(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """render.yaml y scripts/e2e.sh siguen con los nombres de hoy y la configuración los lee @assumption:ENG-01-ASM-02"""
    render = (RAIZ / "render.yaml").read_text(encoding="utf-8")
    e2e = (RAIZ / "scripts" / "e2e.sh").read_text(encoding="utf-8")
    for nombre in ("URL_PUBLICA", "CORREO_MODO", "CORREO_REMITENTE"):
        assert f"key: {nombre}" in render
    assert "PRUEBAS=1 CORREO_MODO=buzon" in e2e

    monkeypatch.setenv("PRUEBAS", "1")
    monkeypatch.setenv("CORREO_MODO", "buzon")
    ajustes = Settings(_env_file=None)
    assert ajustes.e2e_testing is True
    assert ajustes.email_mode == "outbox"
