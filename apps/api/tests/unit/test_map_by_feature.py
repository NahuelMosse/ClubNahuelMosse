import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
MODULES = ROOT / "apps" / "api" / "app" / "modules"
CODE_MAP = ROOT / "docs" / "technical" / "code-map.md"


def _rows() -> dict[str, set[str]]:
    text = CODE_MAP.read_text(encoding="utf-8")
    section = text.split("### By feature", 1)[1].split("\n#", 1)[0]
    rows: dict[str, set[str]] = {}
    for line in section.splitlines():
        if not line.startswith("| ") or line.startswith("| Feature"):
            continue
        name, *cells = [c.strip() for c in line.strip("|").split("|")]
        rows[name.strip("`")] = set(re.findall(r"`([\w.]+\.py)`", " ".join(cells)))
    return rows


def test_the_code_map_lists_one_file_per_existing_layer_for_each_feature() -> None:
    """the code map lists one file per existing layer for each feature
    @ARQ-01-ASM-03"""
    rows = _rows()
    assert rows
    for name, files in rows.items():
        assert files, f"{name} names no file"
        for file in files:
            assert (MODULES / name / file).is_file(), f"{name}/{file}"


def test_the_code_map_lists_each_feature_with_its_files() -> None:
    """the code map lists each feature with its files
    @ARQ-04-S1"""
    rows = _rows()
    existing = {
        folder.name: {a.name for a in folder.glob("*.py") if a.name != "__init__.py"}
        for folder in MODULES.iterdir()
        if folder.is_dir() and folder.name != "__pycache__"
    }
    assert existing
    assert rows == existing
