"""The API base (shared, config, main, health, e2e_support) is in English."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import ast
import io
import re
import tokenize
from pathlib import Path

from fastapi import FastAPI
from fastapi.testclient import TestClient

from tests.unit.test_glossary_english import GLOSSARY, _translations

API_ROOT = Path(__file__).resolve().parents[2]
APP = API_ROOT / "app"
SHARED = APP / "shared"

NEW_FILES = [
    APP / "main.py",
    APP / "health.py",
    APP / "e2e_support.py",
    SHARED / "config.py",
    SHARED / "db.py",
    SHARED / "firebase_credential.py",
    SHARED / "body_limit.py",
    SHARED / "input_validation.py",
    SHARED / "errors.py",
    SHARED / "http_errors.py",
    SHARED / "identity.py",
    SHARED / "responses.py",
    SHARED / "club_timezone.py",
]
OLD_FILES = [
    APP / "salud.py",
    APP / "pruebas.py",
    SHARED / "credencial_firebase.py",
    SHARED / "cuerpo.py",
    SHARED / "entradas.py",
    SHARED / "errores.py",
    SHARED / "errores_http.py",
    SHARED / "identidad.py",
    SHARED / "respuestas.py",
    SHARED / "zona.py",
]
# Words that are Spanish in the glossary and also English or proper names of the API.
ENGLISH = {"admin", "total", "token", "version", "dni", "club", "color", "plan", "no", "real"}
# The terms of today's names that the glossary does not list as a standalone word.
EXTRA_SPANISH = {
    "motor", "conexion", "transaccion", "restriccion", "violada", "ventana", "reintento",
    "body", "acotado", "limite", "plazo", "segundos", "entradas", "errors", "hora",
    "leer", "instalar", "forma", "identidad", "email", "password", "new_password", "crear",
    "cuenta", "borrar", "espera", "rechazos", "zona", "credencial", "servicio", "conflicto",
    "salud", "vivo", "pruebas", "ciclo", "vida", "barrido", "recordatorios", "raiz",
    "proyecto", "datos", "invalidos", "duplicado", "demorado", "existente", "prohibido",
    "available", "ocupado", "slot", "encontrada", "cambiado", "afuera", "agenda",
    "cambiada", "futuras", "fields", "siguiente", "cantidad", "mensajes", "generico",
    "origenes", "responder", "ingreso", "rechazo", "bookings", "space", "venue",
}  # fmt: skip
COMMON_WORDS = re.compile(r"\b(de|la|el|los|las|que|por|para|con|una|del|sin|cuando|si)\b", re.I)


def _spanish() -> set[str]:
    glossary = {
        p for p in _translations(GLOSSARY.read_text(encoding="utf-8")) if re.fullmatch(r"[a-z]+", p)
    }
    # A word the glossary gives as a translation is already English, even if another row lists it as a source.
    translated = {
        w
        for targets in _translations(GLOSSARY.read_text(encoding="utf-8")).values()
        for d in targets
        for w in re.findall(r"[a-z]+", d)
    }
    return (glossary | EXTRA_SPANISH) - ENGLISH - translated


def _words(name: str) -> list[str]:
    parts = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name).lower().split("_")
    return [p for p in parts if p]


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


def _prose_texts(source: str, tree: ast.AST) -> list[str]:
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


def test_the_api_base_files_are_named_as_the_glossary_says() -> None:
    """the API base files are named as the glossary says @ENG-01-S1"""
    missing = [str(p.relative_to(APP)) for p in NEW_FILES if not p.exists()]
    leftover = [str(p.relative_to(APP)) for p in OLD_FILES if p.exists()]

    assert not missing, missing
    assert not leftover, leftover


def test_the_names_comments_and_docstrings_of_the_api_base_are_in_english() -> None:
    """the names, comments and docstrings of the API base are in English @ENG-01-S2 @assumption:ENG-01-ASM-04"""
    spanish = _spanish()
    problems: list[str] = []
    for path in NEW_FILES:
        if not path.exists():
            problems.append(f"{path.name}: does not exist")
            continue
        source = path.read_text(encoding="utf-8")
        tree = ast.parse(source)
        for name in sorted(_defined_names(tree)):
            if spanish & set(_words(name)):
                problems.append(f"{path.name}: name {name}")
        for text in _prose_texts(source, tree):
            if COMMON_WORDS.search(text):
                problems.append(f"{path.name}: {text.strip().splitlines()[0][:60]}")

    assert not problems, problems


def _app_with_errors() -> FastAPI:
    from app.shared import errors, http_errors, input_validation
    from app.shared.body_limit import BodyLimit

    app = FastAPI()
    app.add_middleware(BodyLimit)
    input_validation.install(app)
    http_errors.install(app)

    @app.post("/eco")
    def echo(data: dict[str, int]) -> dict[str, int]:
        return data

    @app.get("/invalido")
    def invalid() -> None:
        raise errors.InvalidData({"name": "Falta"})

    @app.get("/prohibido")
    def forbidden() -> None:
        raise errors.Forbidden()

    @app.get("/ausente")
    def missing() -> None:
        raise errors.NotFound()

    return app


def test_the_413_422_403_and_404_error_bodies_are_main_s() -> None:
    """the 413, 422, 403 and 404 error bodies are main's @ENG-01-S3"""
    client = TestClient(_app_with_errors())

    large = client.post("/eco", content=b"x", headers={"content-length": str(1024 * 1024 + 1)})
    shape = client.post("/eco", json={"a": "no"})
    invalid = client.get("/invalido")
    forbidden = client.get("/prohibido")
    missing = client.get("/ausente")

    assert (large.status_code, large.content) == (413, b"")
    assert shape.status_code == 422
    assert shape.json() == {"errors": {"a": "The value is not valid"}}
    assert (invalid.status_code, invalid.json()) == (422, {"errors": {"name": "Falta"}})
    assert (forbidden.status_code, forbidden.content) == (403, b"")
    assert (missing.status_code, missing.content) == (404, b"")


def test_no_test_imports_a_base_module_by_its_spanish_name() -> None:
    """no test imports a base module by its Spanish name @assumption:ENG-01-ASM-03"""
    assert _old_imports(API_ROOT / "tests") == []


def test_no_api_file_imports_a_base_module_by_its_spanish_name() -> None:
    """no API file imports a base module by its Spanish name @assumption:ENG-01-ASM-06"""
    subject = [*_old_imports(APP), *_old_imports(API_ROOT / "migrations")]

    assert subject == []


def _old_imports(folder: Path) -> list[str]:
    old = re.compile(
        r"\bapp\.(salud|pruebas)\b"
        r"|\bapp\.shared\.(credencial_firebase|cuerpo|entradas|errores_http|errores|identidad|respuestas|zona)\b"
        r"|\bfrom app import [^\n]*\b(salud|pruebas)\b"
        r"|\bfrom app\.shared import [^\n]*\b(credencial_firebase|cuerpo|entradas|errores_http|errores|identidad|respuestas|zona)\b"
    )
    me = Path(__file__).resolve()
    return [
        str(p.relative_to(API_ROOT))
        for p in folder.rglob("*.py")
        if p.resolve() != me
        and ".venv" not in p.parts
        and old.search(p.read_text(encoding="utf-8"))
    ]
