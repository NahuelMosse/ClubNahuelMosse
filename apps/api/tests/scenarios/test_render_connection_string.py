"""No versioned file holds the Render database host."""

import re
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
BINARY_SUFFIXES = (".png", ".jpg", ".pdf", ".ttf", ".otf", ".ico", ".webp")
# A Render database host is `dpg-` followed by its id; the bare prefix in a test or a log is not one.
RENDER_HOST = re.compile(r"dpg-[a-z0-9]{8,}")


def test_no_versioned_file_holds_the_render_connection_string() -> None:
    """no versioned file holds the Render connection string @assumption:ENG-17-ASM-09"""
    files = subprocess.run(
        ["git", "ls-files"], cwd=REPO_ROOT, capture_output=True, text=True, check=True
    ).stdout.split("\n")
    leaking = [
        name
        for name in files
        if name
        and Path(REPO_ROOT, name).is_file()
        and not name.endswith(BINARY_SUFFIXES)
        and RENDER_HOST.search(Path(REPO_ROOT, name).read_text(encoding="utf-8", errors="ignore"))
    ]

    assert leaking == []
