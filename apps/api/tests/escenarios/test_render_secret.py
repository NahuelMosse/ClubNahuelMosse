"""The Render connection string stays outside the repository (ENG-17-ASM-09)."""

import re
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
# Render's Postgres hosts start with that prefix; written as a class so this file does not match itself.
RENDER_HOST = re.compile(r"\bdpg[-][a-z0-9]")
BINARY = (".png", ".jpg", ".jpeg", ".gif", ".pdf", ".ttf", ".otf", ".ico", ".webp", ".jar", ".keystore")


def test_no_versioned_file_holds_the_render_host() -> None:
    """no versioned file holds the Render connection string @assumption:ENG-17-ASM-09"""
    files = subprocess.run(
        ["git", "ls-files"], cwd=REPO_ROOT, capture_output=True, text=True, check=True
    ).stdout.splitlines()
    leaking = [
        name
        for name in files
        if not name.endswith(BINARY)
        and Path(REPO_ROOT, name).is_file()
        and RENDER_HOST.search(Path(REPO_ROOT, name).read_text(encoding="utf-8", errors="ignore"))
    ]

    assert leaking == []
