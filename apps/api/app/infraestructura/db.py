from collections.abc import Iterator
from functools import cache

from sqlalchemy import Connection, Engine, create_engine

from app.config import config


@cache
def motor() -> Engine:
    # Sin los parámetros en los mensajes de error: llevan DNI, correo y nombre y terminan en el log.
    return create_engine(config.database_url, pool_pre_ping=True, hide_parameters=True)


def conexion() -> Iterator[Connection]:
    """Una conexión por pedido. Confirma el caso de uso, antes de responder; lo que no
    se confirmó se descarta al cerrar."""
    with motor().connect() as conn:
        yield conn
