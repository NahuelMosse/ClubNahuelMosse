"""The API's venues, users, session and password recovery modules are in English."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
import ast
import io
import json
import re
import tokenize
from pathlib import Path

from tests.contract_renames import SPANISH_NAMES
from tests.unit.test_api_in_english_contract_current import operations_differing_in

API_ROOT = Path(__file__).resolve().parents[2]
ROOT = API_ROOT.parents[1]
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
NEW_FILES = [MODULES / m / f"{a}.py" for m, files in FILES.items() for a in files]
OLD_NAMES = ("sedes", "usuarios", "sesion", "recuperacion")
OLD_IMPORT = re.compile(
    r"\bapp\.modules\.(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bfrom app\.modules import [^\n]*\b(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bapp/modules/(?:sedes|usuarios|sesion|recuperacion)\b"
    r"|\bmodules/(?:sedes|usuarios|sesion|recuperacion)\b"
)


def _route_params(source: str) -> set[str]:
    """The `{name}` of the routes: they are part of the URL and do not change."""
    return set(re.findall(r"\{(\w+)\}", source))


def _model_fields(tree: ast.AST) -> set[str]:
    """The annotated fields of a class: they are the JSON keys and keep their name."""
    return {
        n.target.id
        for cls in ast.walk(tree)
        if isinstance(cls, ast.ClassDef)
        for n in cls.body
        if isinstance(n, ast.AnnAssign) and isinstance(n.target, ast.Name)
    }


def _defined_names(tree: ast.AST) -> set[str]:
    names: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef):
            names.add(node.name)
        elif isinstance(node, ast.arg):
            names.add(node.arg)
        elif isinstance(node, ast.Name) and isinstance(node.ctx, ast.Store):
            names.add(node.id)
        elif isinstance(node, ast.Attribute) and isinstance(node.ctx, ast.Store):
            names.add(node.attr)
        elif isinstance(node, ast.Global | ast.Nonlocal):
            names.update(node.names)
    return names


def _prose(source: str, tree: ast.AST) -> list[str]:
    texts = [
        t.string
        for t in tokenize.generate_tokens(io.StringIO(source).readline)
        if t.type == tokenize.COMMENT
    ]
    for node in ast.walk(tree):
        if isinstance(node, ast.Module | ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef):
            doc = ast.get_docstring(node, clean=False)
            if doc:
                texts.append(doc)
    return texts


def _normalized_contract(contract: dict) -> dict:
    """Operations with their parameters, security and codes, and the fields of each schema, without the schema names."""

    def without_name(value: object) -> object:
        if isinstance(value, dict):
            if "$ref" in value:
                return {"$ref": "schema"}
            return {k: without_name(v) for k, v in value.items() if k != "title"}
        if isinstance(value, list):
            return [without_name(v) for v in value]
        return value

    schemas = contract.get("components", {}).get("schemas", {})
    operations = {
        f"{method.upper()} {route}": without_name(op)
        for route, methods in contract["paths"].items()
        for method, op in methods.items()
    }
    fields = sorted(
        json.dumps(without_name(e), sort_keys=True, ensure_ascii=False) for e in schemas.values()
    )
    return {"operations": operations, "schemas": fields}


def _published_contract() -> dict:
    return json.loads((API_ROOT / "openapi.json").read_text(encoding="utf-8"))


def test_the_fields_of_the_input_and_output_models_are_the_json_keys_in_english() -> None:
    """the fields of the input and output models are the JSON keys in English @assumption:ENG-02-ASM-05"""
    published = {
        k
        for e in _published_contract()["components"]["schemas"].values()
        for k in e.get("properties", {})
    }
    in_spanish = sorted(published & SPANISH_NAMES)
    with_alias = [
        str(p.relative_to(APP))
        for p in NEW_FILES
        if p.exists() and re.search(r"\balias\s*=", p.read_text(encoding="utf-8"))
    ]

    assert not in_spanish, in_spanish
    assert not with_alias, with_alias


def test_e2e_sh_and_e2e_support_use_the_new_modules_with_the_same_options() -> None:
    """scripts/e2e.sh and e2e_support use the new modules with the same options @assumption:ENG-02-ASM-06"""
    script = (ROOT / "scripts" / "e2e.sh").read_text(encoding="utf-8")
    support = (APP / "e2e_support.py").read_text(encoding="utf-8")

    assert not OLD_IMPORT.search(script)
    assert not OLD_IMPORT.search(support)
    assert "--email" in script
    assert "app.modules.users" in script or "app.modules.users" in support


def test_each_operation_keeps_its_parameters_and_its_security() -> None:
    """each operation keeps its parameters and its security @assumption:ENG-02-ASM-07"""
    assert (
        operations_differing_in("/register", "/me", "/password-recovery", "/link", "/venues") == []
    )


def test_no_document_names_the_old_spanish_account_modules_as_a_module() -> None:
    """no document names «sedes», «usuarios», «sesion» or «recuperacion» as a module @assumption:ENG-02-ASM-08"""
    documents = [
        ROOT / "docs" / "technical" / "code-map.md",
        API_ROOT / "README.md",
        *(ROOT / "docs" / "features").glob("*.md"),
    ]

    problems = [
        p.name for p in documents if p.exists() and OLD_IMPORT.search(p.read_text(encoding="utf-8"))
    ]

    assert not problems, problems
