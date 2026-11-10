"""The API is in English on today's main, with the same contract and the same configuration."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import subprocess
from pathlib import Path
from typing import Any

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


def test_the_branch_contains_main_at_1ee70de() -> None:
    """the branch contains main at 1ee70de @ENG-13-S4"""
    contains = subprocess.run(
        ["git", "merge-base", "--is-ancestor", REFERENCE_MAIN, "HEAD"], cwd=ROOT
    ).returncode
    assert contains == 0
