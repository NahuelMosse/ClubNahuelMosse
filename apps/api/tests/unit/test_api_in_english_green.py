"""The API in English is green on today's main."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TESTS = ROOT / "apps" / "api" / "tests"
APP = ROOT / "apps" / "api" / "app"
SPANISH_MODULES = (
    "sedes", "usuarios", "sesion", "recuperacion", "espacios", "horarios", "notificaciones",
    "reservas",
)  # fmt: skip
SPANISH_STEMS = (
    "casos_de_uso", "reglas", "repositorio", "rutas", "rutas_cuenta", "rutas_registro",
    "almacen", "barrido", "administradores", "baja", "contrasena", "registro",
    "sembrar_admin", "usuario_actual", "salud", "cuerpo", "entradas", "errores",
    "errores_http", "identidad", "respuestas", "zona", "credencial_firebase", "correo",
)  # fmt: skip
IMPORT = re.compile(r"^\s*(?:from|import)\s+app\.([\w.]+)", re.MULTILINE)
FILE_PATH = re.compile(r"apps/api/app/[\w/]+\.py")


def _parts(path: str) -> list[str]:
    return [p.removesuffix(".py") for p in path.replace("app.", "", 1).replace("/", ".").split(".")]


def test_the_api_in_english_leaves_no_imports_or_module_paths_in_spanish_in_the_tests() -> None:
    """the API in English leaves no imports or module paths in Spanish in the tests @ENG-14-S1 @assumption:ENG-14-ASM-01"""
    forbidden = {*SPANISH_MODULES, *SPANISH_STEMS}
    leftovers: list[str] = []
    for test in sorted(TESTS.rglob("*.py")):
        if test.name == Path(__file__).name:
            continue
        text = test.read_text(encoding="utf-8")
        cited = [m for m in IMPORT.findall(text)]
        cited += [m.removeprefix("apps/api/") for m in FILE_PATH.findall(text)]
        for item in cited:
            if forbidden & set(_parts(item)):
                leftovers.append(f"{test.relative_to(TESTS)}: {item}")
    existing = [
        str(p.relative_to(APP))
        for p in APP.rglob("*.py")
        if p.stem in SPANISH_STEMS or p.parent.name in SPANISH_MODULES
    ]
    assert leftovers == []
    assert existing == []
