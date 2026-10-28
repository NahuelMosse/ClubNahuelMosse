"""La API en inglés queda verde sobre el main de hoy y la rama no se mezcla con main."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import re
import subprocess
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
TESTS = RAIZ / "apps" / "api" / "tests"
APP = RAIZ / "apps" / "api" / "app"
MODULOS_EN_CASTELLANO = (
    "sedes", "usuarios", "sesion", "recuperacion", "espacios", "horarios", "notificaciones",
    "reservas",
)  # fmt: skip
STEMS_EN_CASTELLANO = (
    "casos_de_uso", "reglas", "repositorio", "rutas", "rutas_cuenta", "rutas_registro",
    "almacen", "barrido", "administradores", "baja", "contrasena", "registro",
    "sembrar_admin", "usuario_actual", "salud", "cuerpo", "entradas", "errores",
    "errores_http", "identidad", "respuestas", "zona", "credencial_firebase", "correo",
)  # fmt: skip
IMPORT = re.compile(r"^\s*(?:from|import)\s+app\.([\w.]+)", re.MULTILINE)
RUTA_DE_ARCHIVO = re.compile(r"apps/api/app/[\w/]+\.py")


def _partes(ruta: str) -> list[str]:
    return [p.removesuffix(".py") for p in ruta.replace("app.", "", 1).replace("/", ".").split(".")]


def test_la_api_en_ingles_no_deja_imports_ni_rutas_de_modulo_en_castellano_en_los_tests() -> None:
    """la API en inglés no deja imports ni rutas de módulo en castellano en los tests @ENG-14-S1 @assumption:ENG-14-ASM-01"""
    prohibidos = {*MODULOS_EN_CASTELLANO, *STEMS_EN_CASTELLANO}
    restos: list[str] = []
    for prueba in sorted(TESTS.rglob("*.py")):
        if prueba.name == Path(__file__).name:
            continue
        texto = prueba.read_text(encoding="utf-8")
        citados = [m for m in IMPORT.findall(texto)]
        citados += [m.removeprefix("apps/api/") for m in RUTA_DE_ARCHIVO.findall(texto)]
        for citado in citados:
            if prohibidos & set(_partes(citado)):
                restos.append(f"{prueba.relative_to(TESTS)}: {citado}")
    existentes = [
        str(p.relative_to(APP))
        for p in APP.rglob("*.py")
        if p.stem in STEMS_EN_CASTELLANO or p.parent.name in MODULOS_EN_CASTELLANO
    ]
    assert restos == []
    assert existentes == []


def test_la_rama_ingles_api_no_esta_en_main() -> None:
    """la rama ingles-api no está en main @ENG-14-S2"""
    for main in ("origin/main", "main"):
        existe = subprocess.run(["git", "rev-parse", "--verify", "-q", main], cwd=RAIZ).returncode
        if existe != 0:
            continue
        en_main = subprocess.run(
            ["git", "merge-base", "--is-ancestor", "HEAD", main], cwd=RAIZ
        ).returncode
        assert en_main != 0, f"HEAD ya está en {main}"
