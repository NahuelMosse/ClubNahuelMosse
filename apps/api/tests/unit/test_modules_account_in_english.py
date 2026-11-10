"""Los módulos de sedes, usuarios, sesión y recuperación de la API están en inglés."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast
import io
import json
import re
import tokenize
from pathlib import Path

from tests.contract_renames import SPANISH_NAMES
from tests.unit.test_api_in_english_contract_current import operations_differing_in

API_ROOT = Path(__file__).resolve().parents[2]
RAIZ = API_ROOT.parents[1]
APP = API_ROOT / "app"
MODULES = APP / "modules"

FILES = {
    "venues": ["__init__", "use_cases", "rules", "repository", "routes"],
    "users": [
        "__init__", "admins", "deactivation", "password", "profile", "registration",
        "rules", "repository", "account_routes", "registration_routes", "seed_admin",
    ],
    "session": ["__init__", "use_cases", "profile", "repository", "current_user"],
    "password_recovery": ["__init__", "use_cases", "email", "rules", "repository", "routes"],
}  # fmt: skip
NUEVOS = [MODULES / m / f"{a}.py" for m, archivos in FILES.items() for a in archivos]
OLD_NAMES = ("sedes", "usuarios", "sesion", "recuperacion")
OLD_IMPORT = re.compile(
    r"\bapp\.modules\.(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bfrom app\.modules import [^\n]*\b(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bapp/modules/(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bmodules/(?:sedes|usuarios|sesion|recuperacion)\b"
)


def _route_params(fuente: str) -> set[str]:
    """Los `{nombre}` de las rutas: son parte de la URL y no cambian."""
    return set(re.findall(r"\{(\w+)\}", fuente))


def _model_fields(arbol: ast.AST) -> set[str]:
    """Los campos anotados de una clase: son las claves JSON y conservan su nombre."""
    return {
        n.target.id
        for clase in ast.walk(arbol)
        if isinstance(clase, ast.ClassDef)
        for n in clase.body
        if isinstance(n, ast.AnnAssign) and isinstance(n.target, ast.Name)
    }


def _defined_names(arbol: ast.AST) -> set[str]:
    nombres: set[str] = set()
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef):
            nombres.add(nodo.name)
        elif isinstance(nodo, ast.arg):
            nombres.add(nodo.arg)
        elif isinstance(nodo, ast.Name) and isinstance(nodo.ctx, ast.Store):
            nombres.add(nodo.id)
        elif isinstance(nodo, ast.Attribute) and isinstance(nodo.ctx, ast.Store):
            nombres.add(nodo.attr)
        elif isinstance(nodo, ast.Global | ast.Nonlocal):
            nombres.update(nodo.names)
    return nombres


def _prose(fuente: str, arbol: ast.AST) -> list[str]:
    textos = [
        t.string
        for t in tokenize.generate_tokens(io.StringIO(fuente).readline)
        if t.type == tokenize.COMMENT
    ]
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.Module | ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef):
            doc = ast.get_docstring(nodo, clean=False)
            if doc:
                textos.append(doc)
    return textos


def _contrato_normalizado(contrato: dict) -> dict:
    """Operaciones con sus parámetros, security y códigos, y los campos de cada esquema, sin los nombres de esquema."""

    def sin_nombre(valor: object) -> object:
        if isinstance(valor, dict):
            if "$ref" in valor:
                return {"$ref": "schema"}
            return {k: sin_nombre(v) for k, v in valor.items() if k != "title"}
        if isinstance(valor, list):
            return [sin_nombre(v) for v in valor]
        return valor

    esquemas = contrato.get("components", {}).get("schemas", {})
    operaciones = {
        f"{metodo.upper()} {ruta}": sin_nombre(op)
        for ruta, metodos in contrato["paths"].items()
        for metodo, op in metodos.items()
    }
    campos = sorted(
        json.dumps(sin_nombre(e), sort_keys=True, ensure_ascii=False) for e in esquemas.values()
    )
    return {"operaciones": operaciones, "esquemas": campos}


def _contrato_publicado() -> dict:
    return json.loads((API_ROOT / "openapi.json").read_text(encoding="utf-8"))


def test_los_campos_de_los_modelos_de_entrada_y_salida_son_las_claves_json_en_ingles() -> (
    None
):
    """los campos de los modelos de entrada y salida son las claves JSON en inglés @assumption:ENG-02-ASM-05"""
    publicado = {
        k
        for e in _contrato_publicado()["components"]["schemas"].values()
        for k in e.get("properties", {})
    }
    en_castellano = sorted(publicado & SPANISH_NAMES)
    con_alias = [
        str(p.relative_to(APP))
        for p in NUEVOS
        if p.exists() and re.search(r"\balias\s*=", p.read_text(encoding="utf-8"))
    ]

    assert not en_castellano, en_castellano
    assert not con_alias, con_alias


def test_e2e_sh_y_e2e_support_usan_los_modulos_nuevos_con_las_mismas_opciones() -> None:
    """scripts/e2e.sh y e2e_support usan los módulos nuevos con las mismas opciones @assumption:ENG-02-ASM-06"""
    script = (RAIZ / "scripts" / "e2e.sh").read_text(encoding="utf-8")
    soporte = (APP / "e2e_support.py").read_text(encoding="utf-8")

    assert not OLD_IMPORT.search(script)
    assert not OLD_IMPORT.search(soporte)
    assert "--correo" in script
    assert "app.modules.users" in script or "app.modules.users" in soporte


def test_cada_operacion_conserva_sus_parametros_y_su_security() -> None:
    """cada operación conserva sus parámetros y su security @assumption:ENG-02-ASM-07"""
    assert operations_differing_in("/register", "/me", "/password-recovery", "/link", "/venues") == []


def test_ningun_documento_nombra_sedes_usuarios_sesion_ni_recuperacion_como_modulo() -> None:
    """ningún documento nombra sedes, usuarios, sesion ni recuperacion como módulo @assumption:ENG-02-ASM-08"""
    documentos = [
        RAIZ / "docs" / "technical" / "code-map.md",
        API_ROOT / "README.md",
        *(RAIZ / "docs" / "features").glob("*.md"),
    ]

    problemas = [
        p.name
        for p in documentos
        if p.exists() and OLD_IMPORT.search(p.read_text(encoding="utf-8"))
    ]

    assert not problemas, problemas
