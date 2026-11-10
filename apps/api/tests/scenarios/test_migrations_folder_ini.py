"""The migrations folder is named in English and the applied revisions are untouched."""

import configparser

from test_migrations_folder import API_ROOT, APPLIED_REVISIONS, _blob_hash


def test_the_migrations_live_in_migrations_and_0001_to_0011_are_unchanged() -> None:
    """the migrations live in migrations/ and 0001 to 0011 are unchanged @ENG-17-S3 @assumption:ENG-17-ASM-08"""
    versions = API_ROOT / "migrations" / "versions"
    ini = configparser.ConfigParser(interpolation=None)
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
        assert "motor" not in text and "correr" not in text
    assert "Revises" in (API_ROOT / "migrations" / "script.py.mako").read_text()
