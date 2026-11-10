"""The migrations folder is named in English and the applied revisions are untouched."""

import configparser
import subprocess
from pathlib import Path

API_ROOT = Path(__file__).resolve().parents[2]

# `git hash-object` of 0001 to 0011 as they were in main before the move.
APPLIED_REVISIONS = {
    "0001": "41811a3d6b92eb78a060adb653496a1443c21ad3",
    "0002": "9d627a8d65659c29f3b286ef815c7721f9e6da45",
    "0003": "5c1954c52dbb456824331d1f4151006747782a9b",
    "0004": "7bdb050ee11ba1cab2a88cc1224458783766e288",
    "0005": "4501eda897c35dcb6db030836b73626169aaf188",
    "0006": "c06f9d10e0864b9e85c23db49570baa9afff6ed7",
    "0007": "79c136659927607cfd8cc126fa41401689d4d0f1",
    "0008": "da9822a256af48a0fcc699bf68695037b9d52bb1",
    "0009": "ee726c53d499b37f78fd0440afb12bb360564e8b",
    "0010": "d31f589c47a21bb217831deff2e1f804258674bc",
    "0011": "d15faa26e22355aa8e6194d2ebfe6bf1a8c5c96b",
}


def _blob_hash(path: Path) -> str:
    out = subprocess.run(
        ["git", "hash-object", str(path)], capture_output=True, text=True, check=True
    )
    return out.stdout.strip()


def test_the_migrations_live_in_migrations_and_0001_to_0011_are_unchanged() -> None:
    """the migrations live in migrations/ and 0001 to 0011 are unchanged @ENG-17-S3 @assumption:ENG-17-ASM-08"""
    versions = API_ROOT / "migrations" / "versions"
    ini = configparser.ConfigParser()
    ini.read(API_ROOT / "alembic.ini")

    numbers = sorted(f.name[:4] for f in versions.glob("0*.py"))

    assert numbers == [f"{n:04d}" for n in range(1, 13)]
    assert not (API_ROOT / "migraciones").exists()
    assert ini["alembic"]["script_location"].endswith("/migrations")
    for number, expected in APPLIED_REVISIONS.items():
        (file,) = versions.glob(f"{number}_*.py")
        assert _blob_hash(file) == expected, number
    assert "def run_migrations" not in (API_ROOT / "migrations" / "env.py").read_text()
    for translated in ("env.py", "script.py.mako"):
        text = (API_ROOT / "migrations" / translated).read_text()
        assert "motor" not in text and "correr" not in text and "Revises" in (
            text if translated.endswith("mako") else "Revises"
        )
