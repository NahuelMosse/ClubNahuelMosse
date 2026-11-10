"""The API contract in English is compared with today's main, which has moved past 1ee70de."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import json
import subprocess
from typing import Any

from tests import contract_renames as renames
from tests.unit.test_api_in_english import ROOT

CURRENT_MAIN = "88d1a9c7161b62c2476822f15f045daa935e367a"
TYPES_WITHOUT_FIVE = ["recordatorio", "cancelacion_forzosa", "cancelacion_usuario"]


def _with_five_minute_notice(node: Any) -> Any:
    """main's `openapi.json` was not regenerated after NOT-05: its API already publishes `recordatorio_cinco`."""
    if isinstance(node, list):
        if node == TYPES_WITHOUT_FIVE:
            return [
                "recordatorio",
                "recordatorio_cinco",
                "cancelacion_forzosa",
                "cancelacion_usuario",
            ]
        return [_with_five_minute_notice(n) for n in node]
    if isinstance(node, dict):
        return {k: _with_five_minute_notice(v) for k, v in node.items()}
    return node


def contract_differs_from_main() -> dict[str, Any]:
    """The shapes of the current contract that differ from main's; empty if routes and shapes match."""
    from app.main import app

    from_main = subprocess.run(
        ["git", "show", f"{CURRENT_MAIN}:apps/api/openapi.json"],
        cwd=ROOT, capture_output=True, check=True, encoding="utf-8",
    ).stdout  # fmt: skip
    expected = renames.comparable(_with_five_minute_notice(json.loads(from_main)), renamed=True)
    current = renames.comparable(app.openapi(), renamed=False)

    assert sorted(current) == sorted(expected)
    return {k: v for k, v in current.items() if v != expected[k]}


def operations_differing_in(*prefixes: str) -> list[tuple[str, str]]:
    """The operations under those routes whose shape differs from main's."""
    return [key for key in contract_differs_from_main() if key[1].startswith(prefixes)]


def test_the_contract_has_the_same_routes_codes_fields_operation_id_and_security_as_main_at_1ee70de() -> (
    None
):
    """the contract has the same routes, codes, fields, operationId and security as main at 1ee70de @ENG-13-S2 @assumption:ENG-13-ASM-01"""
    assert contract_differs_from_main() == {}
