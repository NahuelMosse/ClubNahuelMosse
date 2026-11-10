"""Data: migration 0008 aborts on lock_timeout, in a database of its own per run.

Replaces the lock_timeout test of test_data_batches_and_queue.py, which used the fixed-name database
of test_data.py: two simultaneous runs clobbered each other when creating it.
"""

import threading
import uuid
from collections.abc import Iterator

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Engine, create_engine, text
from test_data import API_ROOT, TEST_DATABASE_URL, _capture


@pytest.fixture
def own_db(engine: Engine) -> Iterator[tuple[Engine, AlembicConfig]]:
    """An empty database with a unique name, so that another run does not clobber it."""
    name = f"club_rev03_l{uuid.uuid4().hex[:10]}_test"
    server = TEST_DATABASE_URL.rsplit("/", 1)[0]
    admin = create_engine(server + "/postgres", isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        conn.execute(text(f'CREATE DATABASE "{name}"'))
    url = f"{server}/{name}"
    db = create_engine(url)
    alembic = AlembicConfig(str(API_ROOT / "alembic.ini"))
    alembic.set_main_option("sqlalchemy.url", url.replace("%", "%%"))
    try:
        yield db, alembic
    finally:
        db.dispose()
        with admin.connect() as conn:
            conn.execute(text(f'DROP DATABASE IF EXISTS "{name}" WITH (FORCE)'))
        admin.dispose()


def test_migration_0008_aborts_on_lock_timeout_and_can_be_run_again(
    own_db: tuple[Engine, AlembicConfig],
) -> None:
    """migration 0008 aborts on lock_timeout if a long transaction holds the table
    @REV-03-S7 @assumption:REV-03-ASM-15
    """
    db, alembic = own_db
    command.upgrade(alembic, "0007")
    lock = db.connect()
    lock.execute(text("LOCK TABLE notificacion IN ACCESS EXCLUSIVE MODE"))
    result: list[BaseException] = []
    thread = threading.Thread(
        target=lambda: _capture(result, lambda: command.upgrade(alembic, "0008"))
    )

    thread.start()
    thread.join(timeout=60)
    lock.rollback()
    lock.close()

    assert not thread.is_alive()
    assert "lock timeout" in str(result[0])
    with db.connect() as conn:
        version = conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
    assert version == "0007"
    command.upgrade(alembic, "0008")
