"""The lead time comes from the rules by notice kind (NOT-05): `LEAD_TIME_BY_KIND`."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import ast

from tests.unit.test_layers_features import MODULES, _texts


def test_the_lead_time_comes_from_the_rules_and_is_not_in_the_sql() -> None:
    """the reminder lead time comes from the rules and is not written in the SQL @REV-06-S9 @assumption:REV-06-ASM-08"""
    file = MODULES / "notifications" / "repository.py"
    tree = ast.parse(file.read_text(encoding="utf-8"))
    names = {n.id for n in ast.walk(tree) if isinstance(n, ast.Name)}
    assert "LEAD_TIME_BY_KIND" in names
    assert not any("1 hour" in t for t in _texts(file))
