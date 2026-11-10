"""Data: each migration runs in its own transaction, in a database of its own per run."""

from typing import Any

from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Engine, event
from test_data_migrations_lock import own_db  # noqa: F401 — fixture


def test_each_migration_makes_its_own_commit(
    own_db: tuple[Engine, AlembicConfig],  # noqa: F811
) -> None:
    """the upgrade commits once per migration, not once at the end
    @REV-03-S7 @assumption:REV-03-ASM-15
    """
    _, alembic = own_db
    commits: list[Any] = []

    def count(conn: Any) -> None:
        commits.append(conn)

    event.listen(Engine, "commit", count)
    try:
        command.upgrade(alembic, "0006")
    finally:
        event.remove(Engine, "commit", count)

    assert len(commits) >= 6
