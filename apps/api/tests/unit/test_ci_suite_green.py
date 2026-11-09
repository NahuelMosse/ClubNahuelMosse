"""The frozen tests that cited files or names the English migration renamed follow the rename, so the CI suite can be green."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
API = ROOT / "apps" / "api"
TESTS = API / "tests"
# Each frozen test, the name it cited and the one it cites now. The suite runs the frozen tests themselves; running them
# again in a nested pytest would fight the outer one for the same database.
RENAMED = [
    ("escenarios/test_basquet.py", '"Básquet"', '"Basketball 3x3"'),
    ("escenarios/test_documentacion_supuestos_vigente.py", "pantalla_*.dart", "*_screen.dart"),
    ("escenarios/test_readme_app_configuracion.py", '"comun" / "configuracion.dart"', '"common" / "config.dart"'),
    ("escenarios/test_requisitos_no_funcionales_readme_app.py", '"comun" / "configuracion.dart"', '"common" / "config.dart"'),
    ("escenarios/test_requisitos_no_funcionales.py", '"spaces" / "espacios.dart"', '"spaces" / "data" / "spaces_repository.dart"'),
    ("escenarios/test_requisitos_no_funcionales.py", '"bookings" / "horarios.dart"', '"bookings" / "data" / "availability_api.dart"'),
]
CITED_FILES = [
    "apps/mobile/lib/common/config.dart",
    "apps/mobile/lib/features/spaces/data/spaces_repository.dart",
    "apps/mobile/lib/features/bookings/data/availability_api.dart",
]
OBSOLETE = "def test_la_rama_ingles_api_no_esta_en_main("


def _text(name: str) -> str:
    return (TESTS / name).read_text(encoding="utf-8")


def test_the_frozen_tests_that_cited_renamed_files_cite_the_current_ones() -> None:
    """the frozen tests that cited renamed files or Spanish names cite the current ones @CI-01-S1 @assumption:CI-01-ASM-02"""
    stale = [(name, old) for name, old, new in RENAMED if old in _text(name) or new not in _text(name)]
    assert stale == []
    assert [f for f in CITED_FILES if not (ROOT / f).is_file()] == []
    assert list((ROOT / "apps" / "mobile" / "lib").rglob("*_screen.dart"))


def test_the_named_constraints_ignore_the_not_null_ones_postgres_18_records() -> None:
    """the named constraints check ignores the NOT NULL constraints PostgreSQL 18 records @CI-01-S1 @assumption:CI-01-ASM-02"""
    assert "c.contype <> 'n'" in _text("escenarios/test_english_schema.py")


def test_plain_ruff_passes_on_the_api() -> None:
    """plain ruff passes on the API @CI-01-S1 @assumption:CI-01-ASM-03"""
    run = subprocess.run(
        [sys.executable, "-m", "ruff", "check", "."],
        cwd=API, capture_output=True, text=True, encoding="utf-8",
    )  # fmt: skip
    assert run.returncode == 0, run.stdout[-2000:]


def test_the_check_that_the_ingles_api_branch_is_not_in_main_is_gone() -> None:
    """the check that the ingles-api branch is not in main is gone @CI-01-S1 @assumption:CI-01-ASM-05"""
    assert OBSOLETE not in _text("unit/test_api_en_ingles_verde.py")
