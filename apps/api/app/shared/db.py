# kit-shape: the engine and its connection functions go together
from collections.abc import Iterator
from contextlib import contextmanager
from functools import cache
from typing import Annotated

from fastapi import Depends
from sqlalchemy import Connection, Engine, create_engine
from sqlalchemy.exc import IntegrityError

from app.shared.config import config

# How long after its creation a row is recognised as the same repeated request.
RETRY_WINDOW = "5 minutes"


@cache
def _create_engine() -> Engine:
    # No parameters in error messages: they carry ID number, email and name and end up in the log.
    return create_engine(config.database_url, pool_pre_ping=True, hide_parameters=True)


class _Engine:
    """The API engine, one per process. Discarding it closes its connections: one left
    open without an owner closes itself later, outside whoever opened it."""

    def __call__(self) -> Engine:
        return _create_engine()

    def cache_clear(self) -> None:
        if _create_engine.cache_info().currsize:
            _create_engine().dispose()
        _create_engine.cache_clear()


engine = _Engine()


def connection() -> Iterator[Connection]:
    """One connection per request. The use case commits before responding; whatever
    was not committed is discarded on close."""
    with engine().connect() as conn:
        yield conn


DbConnection = Annotated[Connection, Depends(connection, scope="function")]


@contextmanager
def in_transaction(conn: Connection) -> Iterator[None]:
    """Commits what the block does; on any error it rolls back and re-raises the original."""
    try:
        yield
        conn.commit()
    except BaseException:
        conn.rollback()
        raise


def violated_constraint(e: IntegrityError) -> str | None:
    """The name of the constraint that rejected the write, if the engine reports it."""
    return getattr(getattr(e.orig, "diag", None), "constraint_name", None)
