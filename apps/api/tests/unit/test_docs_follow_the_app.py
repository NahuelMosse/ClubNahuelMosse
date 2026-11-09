"""The documentation tests run whole on main, and the pages they read cite files that exist."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import re
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
API = ROOT / "apps" / "api"
DOC_TESTS = [
    "tests/unit/test_documentacion_del_modelo.py",
    "tests/unit/test_rutas_documentadas.py",
    "tests/unit/test_integraciones_documentadas.py",
    "tests/unit/test_readme_conciso.py",
    "tests/unit/test_readme_capturas_sin_el_logo.py",
]
PAGES = [
    ROOT / "docs" / "technical" / "app-navigation.md",
    ROOT / "docs" / "technical" / "integrations.md",
]
LOGO_COUNTED_AS_A_CAPTURE = "test_el_readme_muestra_a_lo_sumo_4_capturas_en_una_fila_y_no_quedan_capturas_sin_usar("


def test_the_documentation_tests_pass_without_deselecting_any() -> None:
    """the documentation tests pass without deselecting any @DOC-10-S1 @assumption:DOC-10-ASM-02"""
    conciso = (API / "tests" / "unit" / "test_readme_conciso.py").read_text(encoding="utf-8")
    assert LOGO_COUNTED_AS_A_CAPTURE not in conciso
    run = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", *DOC_TESTS],
        cwd=API, capture_output=True, text=True, encoding="utf-8", errors="replace",
        env={**os.environ, "PYTHONUTF8": "1"},
    )  # fmt: skip
    assert run.returncode == 0, run.stdout[-2000:]


def test_every_app_file_the_navigation_and_integrations_pages_cite_exists() -> None:
    """every app file the navigation and integrations pages cite exists @DOC-10-S2 @assumption:DOC-10-ASM-01"""
    missing = [
        cited
        for page in PAGES
        for cited in re.findall(r"`(apps/[^`<>\s]+)`", page.read_text(encoding="utf-8"))
        if not (ROOT / cited).exists()
    ]
    assert missing == []
