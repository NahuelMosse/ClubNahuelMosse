"""The data model page shows the audit columns of each table."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import re
from pathlib import Path

MODEL = Path(__file__).resolve().parents[4] / "docs" / "technical" / "data-model.md"
TABLES = (
    "app_user",
    "venue",
    "space",
    "booking",
    "recovery_link",
    "outgoing_email",
    "device",
    "notification",
    "notification_booking",
)
AUDIT = ("created_at", "updated_at")


def test_each_table_of_the_diagram_and_of_its_section_shows_created_at_and_updated_at() -> None:
    """each table of the diagram and of its section shows created_at and updated_at @DOC-02-S1"""
    text = MODEL.read_text(encoding="utf-8")
    diagram = text.split("```mermaid", 1)[1].split("```", 1)[0]
    entities = text.split("## Entities", 1)[1].split("\n## ", 1)[0]

    for table in TABLES:
        block = re.search(rf"^\s+{table} \{{\n(.*?)\n\s+\}}", diagram, re.S | re.M)
        assert block is not None, table
        columns = {line.split()[1] for line in block.group(1).splitlines() if line.strip()}
        assert set(AUDIT) <= columns, (table, "diagram")
        section = entities.split(f"### {table}\n", 1)[1].split("\n### ", 1)[0]
        for column in AUDIT:
            assert f"`{column}`" in section, (table, column)
