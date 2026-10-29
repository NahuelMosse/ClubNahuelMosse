"""The current schema is the one of 0012: this module maps the names of earlier migrations (tables, columns, stored
values) to the ones the database has at head."""

import importlib.util
from pathlib import Path
from types import ModuleType

_PATH = Path(__file__).resolve().parents[1] / "migrations" / "versions" / "0012_english_schema.py"


def _load() -> ModuleType:
    spec = importlib.util.spec_from_file_location("migration_0012", _PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_M = _load()


def table(old: str) -> str:
    """The current name of a table (the same one if it is already current)."""
    return str(_M.TABLES.get(old, old))


def column(old_table: str, old: str) -> str:
    """The current name of column `old` of table `old_table`."""
    if old_table not in _M.TABLES:
        return old
    return str(_M._columns_of(old_table).get(old, old))


def value(old: str) -> str:
    """The current stored value (the same one if it did not change)."""
    return str(_M.VALUES.get(old, old))


def current(tables: dict[str, set[str]]) -> dict[str, set[str]]:
    """The columns of each table with the names they have after 0012."""
    return {table(t): {column(t, c) for c in columns} for t, columns in tables.items()}


def names() -> set[str]:
    """Every name 0012 gives the database, also the ones it builds instead of writing them."""
    move = _M.TO_ENGLISH
    given = {*move.tables.values(), *move.functions.values()}
    given |= {*move.triggers.values(), *move.indexes.values()}
    given |= {*move.constraints.values(), *move.views.values()}
    for columns in move.columns.values():
        given |= set(columns.values())
    return given
