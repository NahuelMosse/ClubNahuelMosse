"""The API's notifications module is in English."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
import ast
import re
from pathlib import Path

from tests.unit.test_base_in_english import (
    COMMON_WORDS,
    _defined_names,
    _prose_texts,
    _spanish,
    _words,
)

APP = Path(__file__).resolve().parents[2] / "app"
MODULE = APP / "modules" / "notifications"
FILES = ["use_cases", "rules", "repository", "routes", "store", "sweep", "push"]
OLD_FILES = ["casos_de_uso", "reglas", "repositorio", "rutas", "almacen", "barrido", "push"]
# Terms of this module that the glossary does not list as a standalone word.
EXTRA_SPANISH = {
    "aviso", "avisos", "canal", "envio", "enviar", "enviado", "enviados", "invalido",
    "invalidos", "anticipacion", "espera", "motivo", "vigente", "registro", "pedido",
    "cuenta", "fila", "filas", "vencidos", "varados", "atascados", "muertos", "previo",
    "nuevas", "nuevo", "anuladas", "anulada", "perdido", "dispositivo", "dispositivos",
    "leida", "leer", "todas", "creada", "baja", "centro", "lista", "vista",
    "bloqueo", "recordatorio", "cancelacion", "forzosa", "hora", "cuando", "momento",
    "usuario", "reserva", "sede", "tipo", "titulo", "cuerpo", "datos", "plataforma",
    "permiso", "notificacion", "notificaciones", "inicio", "fin", "deporte", "unica",
    "total", "cantidad", "pendiente", "pendientes", "fallida", "fallidos", "siguiente",
    "tomar", "marcar", "registrar", "entregar", "despachar", "barrer", "armar", "mensaje",
}  # fmt: skip
ENGLISH = {"total", "token", "tokens", "push", "id", "ids"}  # `total` and `token` are English too
# Fields of the Pydantic models: they are JSON keys and stay in Spanish (ENG-04-ASM-05).
FIELD_CLASSES = {"BaseModel"}


def _json_fields(tree: ast.AST) -> set[str]:
    fields: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef) and any(
            isinstance(b, ast.Name) and b.id in FIELD_CLASSES for b in node.bases
        ):
            fields |= {
                s.target.id
                for s in node.body
                if isinstance(s, ast.AnnAssign) and isinstance(s.target, ast.Name)
            }
    return fields


def test_the_notifications_module_is_named_as_the_glossary_says() -> None:
    """the notifications module is named as the glossary says @ENG-04-S1 @assumption:ENG-04-ASM-02 @assumption:ENG-04-ASM-03"""
    missing = [f"{n}.py" for n in FILES if not (MODULE / f"{n}.py").exists()]
    left_over = [
        f"notificaciones/{n}.py"
        for n in OLD_FILES
        if (APP / "modules" / "notificaciones" / f"{n}.py").exists()
    ]
    imports = re.compile(
        r"\bapp\.modules\.notificaciones\b|\bmodules import [^\n]*\bnotificaciones\b"
    )
    root = APP.parent
    old = [
        str(p.relative_to(root))
        for folder in (APP, root / "tests", root / "migrations")
        for p in folder.rglob("*.py")
        if p.resolve() != Path(__file__).resolve()
        and ".venv" not in p.parts
        and imports.search(p.read_text(encoding="utf-8"))
    ]

    assert not missing, missing
    assert not left_over, left_over
    assert not old, old
    assert (MODULE / "__init__.py").exists()


def test_the_names_comments_and_docstrings_of_notifications_are_in_english() -> None:
    """the names, comments and docstrings of notifications are in English @ENG-04-S2 @assumption:ENG-04-ASM-04"""
    spanish = (_spanish() | EXTRA_SPANISH) - ENGLISH
    problems: list[str] = []
    files = [MODULE / "__init__.py", *(MODULE / f"{n}.py" for n in FILES)]
    for path in files:
        if not path.exists():
            problems.append(f"{path.name}: does not exist")
            continue
        source = path.read_text(encoding="utf-8")
        tree = ast.parse(source)
        for name in sorted(_defined_names(tree) - _json_fields(tree)):
            if spanish & set(_words(name)):
                problems.append(f"{path.name}: name {name}")
        for text in _prose_texts(source, tree):
            if COMMON_WORDS.search(text):
                problems.append(f"{path.name}: {text.strip().splitlines()[0][:60]}")

    assert not problems, problems
