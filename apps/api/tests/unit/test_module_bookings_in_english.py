"""The API's bookings module is in English."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
import ast
import io
import re
import tokenize
from pathlib import Path

from tests.unit.test_api_in_english_contract_current import (
    operations_differing_in,
)
from tests.unit.test_base_in_english import (
    COMMON_WORDS,
    _defined_names,
    _spanish,
    _words,
)

API_ROOT = Path(__file__).resolve().parents[2]
MODULE = API_ROOT / "app" / "modules" / "bookings"
FILES = ["__init__.py", "use_cases.py", "rules.py", "store.py", "repository.py", "routes.py"]
OLD_FILES = ["almacen.py", "casos_de_uso.py", "reglas.py", "repositorio.py", "rutas.py"]
# Booking terms that the glossary does not list as a standalone word (ENG-05-ASM-04).
EXTRA_SPANISH = {
    "reservar", "cancelar", "modificar", "anular", "historial", "cuando", "proximas",
    "agenda", "cuenta", "alta", "baja", "limpio", "detalle", "pedido", "vista", "lista",
    "cualquiera", "movible", "repetida", "vigente", "mover", "insertar", "bloquear",
    "contar", "comunes", "condiciones", "filtros", "orden", "filas", "fila", "previa",
    "mismo", "pagina", "maximo", "intentos", "exigir", "misma", "propia", "antes",
    "ocupado", "campos", "usuario", "motivo", "estado", "precio", "inicio", "fin",
    "fecha", "desde", "hasta", "horas", "duracion", "futuras", "tipo", "deporte",
}  # fmt: skip


def _is_pydantic_model(cls: ast.ClassDef) -> bool:
    return any(
        isinstance(b, ast.Name) and b.id.startswith(("BaseModel", "_Booking")) for b in cls.bases
    ) or any(isinstance(b, ast.Name) and b.id.endswith("Fields") for b in cls.bases)


def _exempt_names(tree: ast.AST) -> set[str]:
    """Fields of the Pydantic models and parameters of the route handlers (ENG-05-ASM-05)."""
    exempt: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef) and _is_pydantic_model(node):
            exempt |= {
                c.target.id
                for c in node.body
                if isinstance(c, ast.AnnAssign) and isinstance(c.target, ast.Name)
            }
        if isinstance(node, ast.FunctionDef) and any(
            isinstance(d, ast.Call)
            and isinstance(d.func, ast.Attribute)
            and isinstance(d.func.value, ast.Name)
            and d.func.value.id == "router"
            for d in node.decorator_list
        ):
            exempt |= {a.arg for a in node.args.args}
    return exempt


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


def test_the_bookings_module_is_named_as_the_glossary_says() -> None:
    """the bookings module is named as the glossary says @ENG-05-S1 @assumption:ENG-05-ASM-02 @assumption:ENG-05-ASM-03"""
    missing = [a for a in FILES if not (MODULE / a).exists()]
    left_over = [p for p in (MODULE.parent / "reservas").glob("*") if p.name != "__pycache__"]
    old = [a for a in OLD_FILES if (MODULE / a).exists()]
    imports = [
        str(p.relative_to(API_ROOT))
        for folder in ("app", "tests", "migrations")
        for p in (API_ROOT / folder).rglob("*.py")
        if p.resolve() != Path(__file__).resolve()
        and ".venv" not in p.parts
        and re.search(
            r"app\.modules\.reservas|modules import [^\n]*\breservas\b",
            p.read_text(encoding="utf-8"),
        )
    ]

    assert not missing, missing
    assert not left_over, left_over
    assert not old, old
    assert imports == [], imports


def test_the_names_comments_and_docstrings_of_bookings_are_in_english() -> None:
    """the names, comments and docstrings of bookings are in English @ENG-05-S2 @assumption:ENG-05-ASM-04"""
    spanish = _spanish() | EXTRA_SPANISH
    problems: list[str] = []
    for file_name in FILES:
        path = MODULE / file_name
        if not path.exists():
            problems.append(f"{file_name}: does not exist")
            continue
        source = path.read_text(encoding="utf-8")
        tree = ast.parse(source)
        for name in sorted(_defined_names(tree) - _exempt_names(tree)):
            if spanish & set(_words(name)):
                problems.append(f"{file_name}: name {name}")
        for text in _prose(source, tree):
            if COMMON_WORDS.search(text):
                problems.append(f"{file_name}: {text.strip().splitlines()[0][:60]}")

    assert not problems, problems


def test_the_bookings_contract_has_the_same_routes_methods_codes_fields_and_operation_id_as_main() -> (
    None
):
    """the bookings contract has the same routes, methods, codes, fields and operationId as main @ENG-05-S3 @assumption:ENG-05-ASM-01"""
    assert operations_differing_in("/bookings") == []
