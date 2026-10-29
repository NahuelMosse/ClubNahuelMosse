"""No Spanish contract name is left as a key in the code of the API."""

import ast
from pathlib import Path

from tests.contract_renames import SPANISH_NAMES

APP = Path(__file__).resolve().parents[2] / "app"


def _spanish_keys(path: Path) -> list[str]:
    found = []
    for node in ast.walk(ast.parse(path.read_text(encoding="utf-8"))):
        keys: list[ast.expr | None] = []
        if isinstance(node, ast.Dict):
            keys = list(node.keys)
        elif isinstance(node, ast.Subscript):
            keys = [node.slice]
        found += [
            f"{path.relative_to(APP)}:{k.lineno} {k.value}"
            for k in keys
            if isinstance(k, ast.Constant) and k.value in SPANISH_NAMES
        ]
    return found


def test_no_key_of_a_dict_literal_of_the_api_is_a_spanish_contract_name() -> None:
    """no key of a dict literal of the API is a Spanish contract name @ENG-18-S2"""
    assert [k for p in sorted(APP.rglob("*.py")) for k in _spanish_keys(p)] == []
