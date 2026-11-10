"""The data model lives on its page: what REV-07-S8 demands of it."""

import re
from pathlib import Path

from tests.scenarios.test_documentation_current import _columns_by_table, _text

MODEL = Path(__file__).resolve().parents[4] / "docs" / "technical" / "data-model.md"


def test_the_data_model_documents_all_the_tables() -> None:
    """the data model documents the nine tables with their columns @REV-07-S8"""
    data = _text(MODEL)
    tables = _columns_by_table()

    assert len(tables) >= 9
    common = {"id", "created_at", "updated_at"}
    missing = [
        f"{table}.{column}"
        for table, columns in sorted(tables.items())
        for column in sorted(columns - common)
        if f"`{column}`" not in data
    ]
    assert missing == []


def test_the_data_model_carries_columns_keys_indexes_and_triggers_of_each_table() -> None:
    """the data model carries columns, keys, indexes and triggers of each table
    @REV-07-S8 @assumption:REV-07-ASM-03
    """
    data = _text(MODEL)

    assert re.search(r"PRIMARY KEY|clave primaria", data, re.I)
    assert re.search(r"FOREIGN KEY|clave foránea|REFERENCES", data, re.I)
    assert re.search(r"índice|INDEX", data, re.I)
    assert re.search(r"trigger", data, re.I)
    for table in _columns_by_table():
        assert f"`{table}`" in data or f"### {table}" in data, table


def test_each_table_of_the_migrated_schema_appears_in_the_data_model_with_its_columns() -> None:
    """each table of the migrated schema appears in the data model with its columns
    @REV-07-S8 @assumption:REV-07-ASM-10
    """
    data = _text(MODEL)
    tables = _columns_by_table()

    assert len(tables) == 9
    for table, columns in tables.items():
        chunks = re.split(rf"^### {table}$", data, flags=re.M)
        assert len(chunks) > 1, table
        section = re.split(r"^#+ ", chunks[1], flags=re.M)[0]
        omitted = [c for c in sorted(columns) if f"`{c}`" not in section]
        assert set(omitted) <= {"id", "created_at", "updated_at"}, (table, omitted)
