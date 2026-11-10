"""The data model describes the current schema (uuid keys, renamed audit)."""

import re

from tests.current_schema import column, table as current_table
from tests.scenarios.test_documentation_current import (
    API,
    DESIGN,
    _columns_by_table,
    _section,
    _text,
)
from tests.scenarios.test_documentation_model_current import MODEL

COMMON = {"id", "created_at", "updated_at"}
RENAMES = re.compile(r"ALTER TABLE (\w+) RENAME COLUMN (\w+) TO (\w+)")


def _current_columns() -> dict[str, set[str]]:
    """The columns of each table after the RENAME COLUMN of the `upgrade()` of 0010."""
    tables = _columns_by_table()
    migration = next((API / "migrations" / "versions").glob("0010_*.py"))
    upgrade = _text(migration).split("def _auditoria_abajo")[0]
    for table, old, new in RENAMES.findall(upgrade):
        tables[current_table(table)].discard(column(table, old))
        tables[current_table(table)].add(column(table, new))
    return tables


def test_the_data_model_documents_each_column_of_the_current_schema() -> None:
    """the data model documents the nine tables with their current columns
    @REV-07-S8 @DAT-01-S2
    """
    data = _text(MODEL)
    tables = _current_columns()

    assert len(tables) == 9
    missing = [
        f"{table}.{column}"
        for table, columns in sorted(tables.items())
        for column in sorted(columns - COMMON)
        if f"`{column}`" not in data
    ]
    assert missing == []


def test_each_table_section_names_its_current_columns() -> None:
    """each table section of the model names its current columns
    @REV-07-S8 @DAT-01-S1
    """
    data = _text(MODEL)

    for table, columns in _current_columns().items():
        chunks = re.split(rf"^### {table}$", data, flags=re.M)
        assert len(chunks) > 1, table
        section = re.split(r"^#+ ", chunks[1], flags=re.M)[0]
        omitted = [c for c in sorted(columns) if f"`{c}`" not in section]
        assert set(omitted) <= COMMON, (table, omitted)


def test_the_data_section_of_the_design_points_to_the_data_model() -> None:
    """the Data section of the system design points to the data model @REV-07-S8"""
    data = _section(_text(DESIGN), "Data")

    assert "data-model.md" in data
    assert "nine tables" in data
