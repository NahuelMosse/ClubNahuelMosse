"""Rows of 0011 across the English migration, compared by position because the tables are renamed."""

from alembic import command
from sqlalchemy import text
from test_datos_migraciones import base_propia  # noqa: F401  (fixture)
from test_english_schema import _english_tally, _seed_spanish, _stored

Base = tuple


def test_the_migration_translates_the_rows_of_0011_without_touching_them_otherwise(
    base_propia: Base,  # noqa: F811
) -> None:
    """the migration translates the rows of 0011 without touching them otherwise and goes back to 0011 @ENG-17-S1 @assumption:ENG-17-ASM-05 @assumption:ENG-17-ASM-06"""
    base, alembic = base_propia
    command.upgrade(alembic, "0011")
    _seed_spanish(base)
    before = _stored(base, spanish=True)
    with base.connect() as conn:
        content = conn.execute(text("SELECT titulo, cuerpo FROM notificacion ORDER BY id")).all()

    command.upgrade(alembic, "head")

    after = _stored(base, spanish=False)
    assert list(after["counts"].values()) == list(before["counts"].values())
    assert after["stamps"] == before["stamps"]
    for key in ("roles", "status", "kind", "delivery"):
        assert after[key] == _english_tally(before[key]), key
    with base.connect() as conn:
        assert (
            conn.execute(text("SELECT title, body FROM notification ORDER BY id")).all() == content
        )
        assert conn.execute(text("SELECT first_name FROM app_user LIMIT 1")).scalar_one() == "Ana"
    command.downgrade(alembic, "0011")
    assert _stored(base, spanish=True) == before
