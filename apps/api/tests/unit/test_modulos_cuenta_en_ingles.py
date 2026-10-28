"""Los módulos de sedes, usuarios, sesión y recuperación de la API están en inglés."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast
import io
import json
import re
import tokenize
from pathlib import Path

RAIZ_API = Path(__file__).resolve().parents[2]
RAIZ = RAIZ_API.parents[1]
APP = RAIZ_API / "app"
MODULOS = APP / "modules"
LINEA_BASE = Path(__file__).parent / "contrato_cuenta_main.json"

ARCHIVOS = {
    "venues": ["__init__", "use_cases", "rules", "repository", "routes"],
    "users": [
        "__init__", "admins", "deactivation", "password", "profile", "registration",
        "rules", "repository", "account_routes", "registration_routes", "seed_admin",
    ],
    "session": ["__init__", "use_cases", "profile", "repository", "current_user"],
    "password_recovery": ["__init__", "use_cases", "email", "rules", "repository", "routes"],
}  # fmt: skip
NUEVOS = [MODULOS / m / f"{a}.py" for m, archivos in ARCHIVOS.items() for a in archivos]
VIEJOS = ("sedes", "usuarios", "sesion", "recuperacion")
IMPORTE_VIEJO = re.compile(
    r"\bapp\.modules\.(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bfrom app\.modules import [^\n]*\b(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bapp/modules/(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bmodules/(?:sedes|usuarios|sesion|recuperacion)\b"
)


def _parametros_de_ruta(fuente: str) -> set[str]:
    """Los `{nombre}` de las rutas: son parte de la URL y no cambian."""
    return set(re.findall(r"\{(\w+)\}", fuente))


def _campos_de_modelo(arbol: ast.AST) -> set[str]:
    """Los campos anotados de una clase: son las claves JSON y conservan su nombre."""
    return {
        n.target.id
        for clase in ast.walk(arbol)
        if isinstance(clase, ast.ClassDef)
        for n in clase.body
        if isinstance(n, ast.AnnAssign) and isinstance(n.target, ast.Name)
    }


def _nombres_definidos(arbol: ast.AST) -> set[str]:
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


def _prosa(fuente: str, arbol: ast.AST) -> list[str]:
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
    return json.loads((RAIZ_API / "openapi.json").read_text(encoding="utf-8"))


def test_los_campos_de_los_modelos_de_entrada_y_salida_siguen_siendo_las_claves_json_en_castellano() -> (
    None
):
    """los campos de los modelos de entrada y salida siguen siendo las claves JSON en castellano @assumption:ENG-02-ASM-05"""
    base = json.loads(LINEA_BASE.read_text(encoding="utf-8"))
    propiedades = {
        k
        for e in base["esquemas"]
        for k in json.loads(e).get("properties", {})
        if re.fullmatch(r"[a-z_]+", k)
    }
    publicado = {
        k
        for e in _contrato_publicado()["components"]["schemas"].values()
        for k in e.get("properties", {})
    }
    con_alias = [
        str(p.relative_to(APP))
        for p in NUEVOS
        if p.exists() and re.search(r"\balias\s*=", p.read_text(encoding="utf-8"))
    ]

    assert propiedades <= publicado, sorted(propiedades - publicado)
    assert not con_alias, con_alias


def test_e2e_sh_y_e2e_support_usan_los_modulos_nuevos_con_las_mismas_opciones() -> None:
    """scripts/e2e.sh y e2e_support usan los módulos nuevos con las mismas opciones @assumption:ENG-02-ASM-06"""
    script = (RAIZ / "scripts" / "e2e.sh").read_text(encoding="utf-8")
    soporte = (APP / "e2e_support.py").read_text(encoding="utf-8")

    assert not IMPORTE_VIEJO.search(script)
    assert not IMPORTE_VIEJO.search(soporte)
    assert "--correo" in script
    assert "app.modules.users" in script or "app.modules.users" in soporte


def test_cada_operacion_conserva_sus_parametros_y_su_security() -> None:
    """cada operación conserva sus parámetros y su security @assumption:ENG-02-ASM-07"""
    base = json.loads(LINEA_BASE.read_text(encoding="utf-8"))["operaciones"]
    hoy = _contrato_normalizado(_contrato_publicado())["operaciones"]

    for clave, op in base.items():
        assert hoy[clave].get("parameters") == op.get("parameters"), clave
        assert hoy[clave].get("security") == op.get("security"), clave


def test_ningun_documento_nombra_sedes_usuarios_sesion_ni_recuperacion_como_modulo() -> None:
    """ningún documento nombra sedes, usuarios, sesion ni recuperacion como módulo @assumption:ENG-02-ASM-08"""
    documentos = [
        RAIZ / "docs" / "technical" / "mapa-del-codigo.md",
        RAIZ_API / "README.md",
        *(RAIZ / "docs" / "features").glob("*.md"),
    ]

    problemas = [
        p.name
        for p in documentos
        if p.exists() and IMPORTE_VIEJO.search(p.read_text(encoding="utf-8"))
    ]

    assert not problemas, problemas
