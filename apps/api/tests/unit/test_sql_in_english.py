"""The SQL of the API names only English tables, columns, values, aliases and parameters."""

import ast
import importlib.util
import re
from pathlib import Path

API = Path(__file__).resolve().parents[2]
APP = API / "app"
MIGRATION = API / "migrations" / "versions" / "0012_english_schema.py"

# Spanish names the SQL used besides the schema's: bind parameters and column aliases.
OLD_ALIASES = {
    "ahora", "anticipacion", "antes", "autor", "canchas", "clase", "como_se_vio",
    "creada_en", "deportes", "desde", "desde_antes", "donde_estaba", "empezo", "espera",
    "espacio_previo", "hasta", "leida", "limite", "nacimiento", "nombre_usuario", "nuevo",
    "precio", "sede", "vinculo", "administrador", "aviso",
}  # fmt: skip
# Words that are the same in both languages or are not names of the schema.
NOT_NAMES = {"id", "dni", "token", "total", "offset", "ids", "ns", "p", "c", "h", "m", "u", "a"}


def _old_vocabulary() -> set[str]:
    spec = importlib.util.spec_from_file_location("migration_0012", MIGRATION)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    words = set(module.TABLES) | set(module.VALUES) | set(module.VIEWS) | set(module.INDEXES)
    words |= set(module.COMMON_COLUMNS) | set(module.FUNCTIONS) | set(module.TRIGGERS)
    for columns in module.OWN_COLUMNS.values():
        words |= set(columns)
    words |= set(module.SOFT_DELETE.values()) | {"estado_actual"}
    return (words | OLD_ALIASES) - NOT_NAMES


def _sql_strings(tree: ast.AST) -> list[str]:
    """Strings of every `text(...)` call, of the module constants that hold SQL, and the keys
    of the dicts that carry bind parameters."""
    found: list[str] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and getattr(node.func, "id", "") == "text":
            found += [c.value for c in ast.walk(node) if _is_str(c)]
        if isinstance(node, ast.Assign) and isinstance(node.value, (ast.Constant, ast.JoinedStr)):
            found += [c.value for c in ast.walk(node.value) if _is_str(c)]
        if isinstance(node, ast.FunctionDef) and _has_sql(node):
            for inner in ast.walk(node):
                if isinstance(inner, ast.Dict):
                    found += [k.value for k in inner.keys if _is_str(k)]
    return found


def _has_sql(function: ast.FunctionDef) -> bool:
    return any(
        isinstance(n, ast.Call) and getattr(n.func, "id", "") == "text"
        for n in ast.walk(function)
    )


def _is_str(node: object) -> bool:
    return isinstance(node, ast.Constant) and isinstance(node.value, str)


def _quoted_values_and_words(sql: str) -> set[str]:
    return set(re.findall(r"[a-z_]+", sql.lower()))


def test_every_sql_text_of_the_api_names_only_english_tables_columns_and_parameters() -> None:
    """@ENG-17-S4"""
    old = _old_vocabulary()
    allowed_files = {"config.py"}
    leftovers: dict[str, set[str]] = {}
    for path in sorted(APP.rglob("*.py")):
        if path.name in allowed_files:
            continue
        words: set[str] = set()
        for sql in _sql_strings(ast.parse(path.read_text(encoding="utf-8"))):
            if re.search(r"[A-Z]{3,}|:\w|^\s*\w+\.\w+", sql) or " " not in sql:
                words |= _quoted_values_and_words(sql)
        found = words & old
        if found:
            leftovers[str(path.relative_to(APP))] = found
    assert leftovers == {}
