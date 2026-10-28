"""La API está en inglés sobre el main de hoy, con el mismo contrato y la misma configuración."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import subprocess
from pathlib import Path
from typing import Any

import pytest

from app.shared.config import Settings

RAIZ = Path(__file__).resolve().parents[4]
APP = RAIZ / "apps" / "api" / "app"
MAIN_DE_REFERENCIA = "1ee70de"

MODULOS = {
    "venues", "users", "session", "password_recovery",
    "spaces", "availability", "notifications", "bookings",
}  # fmt: skip
ARCHIVOS_DE_LA_BASE = {"main.py", "health.py", "e2e_support.py"}
# Nombres de archivo de hoy, en castellano, que no pueden quedar en ningún lugar de app.
STEMS_EN_CASTELLANO = {
    "casos_de_uso", "reglas", "repositorio", "rutas", "rutas_cuenta", "rutas_registro",
    "almacen", "barrido", "disponibilidad", "administradores", "baja", "contrasena",
    "registro", "sembrar_admin", "usuario_actual", "salud", "pruebas", "cuerpo", "entradas",
    "errores", "errores_http", "identidad", "respuestas", "zona", "credencial_firebase",
    "correo", "perfil",
}  # fmt: skip
MODULOS_EN_CASTELLANO = {
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
# (campo, variable en inglés, valor, variable de hoy, otro valor)
CAMPOS: list[tuple[str, str, Any, str, Any]] = [
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
def entorno_limpio(monkeypatch: pytest.MonkeyPatch) -> pytest.MonkeyPatch:
    for variable in VARIABLES:
        monkeypatch.delenv(variable, raising=False)
    return monkeypatch


def test_la_base_y_los_modulos_de_la_api_se_llaman_como_dice_el_glosario_y_no_queda_ninguno_en_castellano() -> (
    None
):
    """la base y los módulos de la API se llaman como dice el glosario y no queda ninguno en castellano @ENG-13-S1 @assumption:ENG-13-ASM-02 @assumption:ENG-13-ASM-03"""
    carpetas = {
        p.name for p in (APP / "modules").iterdir() if p.is_dir() and p.name != "__pycache__"
    }
    assert carpetas == MODULOS
    assert {p.name for p in APP.glob("*.py")} >= ARCHIVOS_DE_LA_BASE
    en_castellano = sorted(
        str(p.relative_to(APP))
        for p in APP.rglob("*.py")
        if p.stem in STEMS_EN_CASTELLANO or p.parent.name in MODULOS_EN_CASTELLANO
    )
    assert en_castellano == []


def _resolver(nodo: Any, componentes: dict[str, Any], visto: tuple[str, ...] = ()) -> Any:
    """El nodo con cada `$ref` reemplazado por su estructura, sin el nombre del esquema."""
    if isinstance(nodo, list):
        return [_resolver(n, componentes, visto) for n in nodo]
    if not isinstance(nodo, dict):
        return nodo
    ref = nodo.get("$ref")
    if ref is not None:
        nombre = ref.rsplit("/", 1)[-1]
        if nombre in visto:
            return "<recursivo>"
        esquema = {k: v for k, v in componentes[nombre].items() if k != "title"}
        return _resolver(esquema, componentes, (*visto, nombre))
    return {k: _resolver(v, componentes, visto) for k, v in nodo.items()}


def _forma(contrato: dict[str, Any]) -> dict[str, Any]:
    """Lo que el contrato promete: rutas, métodos, códigos, campos, parámetros, operationId y security."""
    componentes = contrato.get("components", {}).get("schemas", {})
    forma: dict[str, Any] = {}
    for ruta, metodos in contrato["paths"].items():
        for metodo, operacion in metodos.items():
            forma[f"{metodo.upper()} {ruta}"] = _resolver(
                {
                    "operationId": operacion.get("operationId"),
                    "security": operacion.get("security"),
                    "parameters": operacion.get("parameters"),
                    "requestBody": operacion.get("requestBody"),
                    "responses": operacion.get("responses"),
                },
                componentes,
            )
    return forma


def test_la_configuracion_lee_cada_variable_en_ingles_y_en_castellano_tambien_el_modo_brevo(
    entorno_limpio: pytest.MonkeyPatch,
) -> None:
    """la configuración lee cada variable en inglés y en castellano, también el modo brevo @ENG-13-S3"""
    for campo, ingles, valor, castellano, otro in CAMPOS:
        entorno_limpio.setenv(ingles, str(valor))
        assert getattr(Settings(_env_file=None), campo) == valor, ingles
        entorno_limpio.delenv(ingles)

        entorno_limpio.setenv(castellano, str(otro))
        assert getattr(Settings(_env_file=None), campo) == otro, castellano

        entorno_limpio.setenv(ingles, str(valor))
        assert getattr(Settings(_env_file=None), campo) == valor, f"{ingles} gana a {castellano}"
        entorno_limpio.delenv(ingles)
        entorno_limpio.delenv(castellano)

    for variable, campo in (
        ("SMTP_HOST", "smtp_host"),
        ("BREVO_API_KEY", "brevo_api_key"),
        ("FIREBASE_API_KEY", "firebase_api_key"),
    ):
        entorno_limpio.setenv(variable, "valor")
        assert getattr(Settings(_env_file=None), campo) == "valor", variable
        entorno_limpio.delenv(variable)

    for modo, esperado in (
        ("outbox", "outbox"),
        ("buzon", "outbox"),
        ("smtp", "smtp"),
        ("brevo", "brevo"),
    ):
        entorno_limpio.setenv("EMAIL_MODE", modo)
        assert Settings(_env_file=None).email_mode == esperado, modo


def test_la_contrasena_del_administrador_se_lee_de_admin_password_y_de_admin_contrasena(
    entorno_limpio: pytest.MonkeyPatch,
) -> None:
    """la contraseña del administrador se lee de ADMIN_PASSWORD y de ADMIN_CONTRASENA, gana la inglesa @ENG-13-S3"""
    from app.modules.users import seed_admin

    class SinBase(Exception):
        pass

    def sin_base() -> Any:
        raise SinBase

    entorno_limpio.setattr(seed_admin, "engine", sin_base)
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
        entorno_limpio.setenv(variable, "Clave1234")
        with pytest.raises(SinBase):
            seed_admin.main(argv)
        entorno_limpio.delenv(variable)


def test_la_rama_contiene_main_en_1ee70de() -> None:
    """la rama contiene main en 1ee70de @ENG-13-S4"""
    contiene = subprocess.run(
        ["git", "merge-base", "--is-ancestor", MAIN_DE_REFERENCIA, "HEAD"], cwd=RAIZ
    ).returncode
    assert contiene == 0


def test_scripts_e2e_sh_siembra_el_admin_con_el_modulo_users_seed_admin_y_las_mismas_opciones() -> (
    None
):
    """scripts/e2e.sh siembra el admin con el módulo users.seed_admin y las mismas opciones @assumption:ENG-13-ASM-04"""
    guion = (RAIZ / "scripts" / "e2e.sh").read_text(encoding="utf-8")

    assert "python -m app.modules.users.seed_admin" in guion
    assert "sembrar_admin" not in guion
    assert '--correo "$ADMIN_CORREO"' in guion
