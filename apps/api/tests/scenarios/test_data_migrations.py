"""Data: the migrations' round trip, each run with its own database.

Replaces the two migration tests of test_data.py, which used a fixed database name:
two simultaneous runs (suite, scenarios and mutations) clobbered each other when creating it.
"""

import threading
import uuid
from collections.abc import Iterator

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.exc import OperationalError
from test_data import (
    API_ROOT,
    REVISIONS,
    TEST_DATABASE_URL,
    _capture,
    _schema,
    _bookings,
    _seed,
)


@pytest.fixture
def own_db(engine: Engine) -> Iterator[tuple[Engine, AlembicConfig]]:
    """An empty database with a unique name, to migrate up and down without clobbering another run."""
    name = f"club_rev03_m{uuid.uuid4().hex[:10]}_test"
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


def test_the_new_migration_does_not_wait_on_a_lock_in_its_own_database(
    own_db: tuple[Engine, AlembicConfig],
) -> None:
    """the new migration does not lock the tables while the previous version serves @REV-03-S7"""
    db, alembic = own_db
    command.upgrade(alembic, "0007")
    _seed(db)
    lock = db.connect()
    lock.execute(text("LOCK TABLE reserva IN ACCESS EXCLUSIVE MODE"))
    result: list[BaseException] = []
    thread = threading.Thread(
        target=lambda: _capture(result, lambda: command.upgrade(alembic, "0008"))
    )

    thread.start()
    thread.join(timeout=60)
    lock.rollback()
    lock.close()

    assert not thread.is_alive()
    assert isinstance(result[0], OperationalError)
    assert "lock timeout" in str(result[0])
    command.upgrade(alembic, "0008")
    with db.connect() as conn:
        invalid = conn.execute(
            text("SELECT count(*) FROM pg_index WHERE NOT indisvalid")
        ).scalar_one()
    assert invalid == 0
    assert _bookings(db) == 1


@pytest.mark.parametrize(
    ("previous", "revision"), list(zip(["0001", *REVISIONS], REVISIONS, strict=False))
)
def test_each_migration_goes_up_and_back_with_data_in_its_own_database(
    own_db: tuple[Engine, AlembicConfig], previous: str, revision: str
) -> None:
    """@REV-03-S8 @assumption:REV-03-ASM-06"""
    db, alembic = own_db
    command.upgrade(alembic, "0001")
    _seed(db)
    command.upgrade(alembic, previous)
    before = _schema(db)

    command.upgrade(alembic, revision)
    after = _schema(db)
    command.downgrade(alembic, "-1")
    back = _schema(db)
    command.upgrade(alembic, revision)

    assert back == before
    assert _schema(db) == after
    assert _bookings(db) == 1
