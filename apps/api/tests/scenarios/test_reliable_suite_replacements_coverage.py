"""Replacements of two tests of the reliable suite that fail the same on main (see `replaces:` in the Log of the card ENG-14)."""

import ast
import re
from pathlib import Path

from fastapi.testclient import TestClient

API_ROOT = Path(__file__).resolve().parents[2]
UNIT_TESTS = API_ROOT / "tests" / "unit" / "test_use_cases_bookings.py"
USE_CASES = API_ROOT / "app" / "modules" / "bookings" / "use_cases.py"
NFR_TEST = API_ROOT / "tests" / "scenarios" / "test_non_functional_requirements.py"


def _use_cases() -> list[str]:
    return re.findall(r"^def ([a-z]\w*)\(", USE_CASES.read_text(encoding="utf-8"), re.M)


def _body_of(source: str, name: str) -> str:
    for node in ast.parse(source).body:
        if isinstance(node, ast.FunctionDef) and node.name == name:
            return ast.get_source_segment(source, node) or ""
    return ""


def test_every_public_bookings_function_has_its_unit_test() -> None:
    """every public function of bookings/use_cases.py has its unit test
    @REV-08-S7 @assumption:REV-08-ASM-09
    """
    code = UNIT_TESTS.read_text(encoding="utf-8") if UNIT_TESTS.exists() else ""

    assert len(_use_cases()) >= 7
    assert [c for c in _use_cases() if not re.search(rf"\b{c}\(", code)] == []


def test_rnf_01_h04_01_is_tested_against_the_published_contract(api: TestClient) -> None:
    """RNF-01-H04-01 is tested against the published contract and not by reading the README
    @REV-08-S4 @assumption:REV-08-ASM-08
    """
    contract = api.get("/openapi.json")
    source = NFR_TEST.read_text(encoding="utf-8")
    test = _body_of(source, "test_the_api_publishes_openapi_with_every_endpoint_the_app_uses")

    assert contract.status_code == 200
    assert len(contract.json()["paths"]) >= 20
    assert "swagger" in api.get("/docs").text.lower()
    assert "_operations(api)" in test
    assert "README" not in test
    assert "README" not in _body_of(source, "_endpoints_the_app_uses")
