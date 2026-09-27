from collections.abc import Iterator
from functools import cache

from sqlalchemy import Connection, Engine, create_engine

from app.config import config


@cache
def motor() -> Engine:
    return create_engine(config.database_url, pool_pre_ping=True)


def conexion() -> Iterator[Connection]:
    """Una transacción por pedido: se confirma si el pedido termina bien."""
    with motor().begin() as conn:
        yield conn
