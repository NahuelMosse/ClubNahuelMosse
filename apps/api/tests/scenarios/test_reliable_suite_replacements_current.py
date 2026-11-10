"""Replacements of the bookings unit tests after renaming the module to bookings (see `replaces:` in the Log of the card ENG-14)."""

import ast
import os
import re
import subprocess
import sys
from pathlib import Path

API_ROOT = Path(__file__).resolve().parents[2]
UNIT_TESTS = API_ROOT / "tests" / "unit" / "test_use_cases_bookings.py"
USE_CASES = API_ROOT / "app" / "modules" / "bookings" / "use_cases.py"


def _env_without_services() -> dict[str, str]:
    base = {k: v for k, v in os.environ.items() if k != "FIREBASE_AUTH_EMULATOR_HOST"}
    return base | {
        "DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
        "TEST_DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
    }


def _use_cases() -> list[str]:
    source = USE_CASES.read_text(encoding="utf-8")
    return [
        n.name
        for n in ast.parse(source).body
        if isinstance(n, ast.FunctionDef) and not n.name.startswith("_")
    ]


def _without_unit_test(code: str) -> list[str]:
    return [c for c in _use_cases() if not re.search(rf"\b{c}\(", code)]


def test_every_public_bookings_function_has_its_unit_test_with_the_call_in_the_code() -> None:
    """every public function of bookings/use_cases.py is called by name in the unit tests
    @REV-08-S7 @assumption:REV-08-ASM-09
    """
    code = UNIT_TESTS.read_text(encoding="utf-8") if UNIT_TESTS.exists() else ""

    assert len(_use_cases()) >= 7
    assert _without_unit_test(code) == []


def test_the_bookings_unit_tests_pass_without_database_or_emulator_and_cover_every_use_case() -> (
    None
):
    """the unit tests of the bookings use cases pass without database or emulator and call each use case
    @REV-08-S7
    """
    run = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", str(UNIT_TESTS)],
        cwd=API_ROOT, env=_env_without_services(), capture_output=True, text=True,
        timeout=300, check=False,
    )  # fmt: skip

    assert run.returncode == 0, run.stdout[-2000:]
    assert _without_unit_test(UNIT_TESTS.read_text(encoding="utf-8")) == []
