# kit-shape: el motor y sus funciones de conexión van juntos
from collections.abc import Iterator
from contextlib import contextmanager
from functools import cache
from typing import Annotated

from fastapi import Depends
from sqlalchemy import Connection, Engine, create_engine
from sqlalchemy.exc import IntegrityError

from app.shared.config import config

# Cuánto después de su alta una fila se reconoce como el mismo pedido repetido.
VENTANA_DE_REINTENTO = "5 minutes"


@cache
def _crear_motor() -> Engine:
    # Sin los parámetros en los mensajes de error: llevan DNI, correo y nombre y terminan en el log.
    return create_engine(config.database_url, pool_pre_ping=True, hide_parameters=True)


class _Motor:
    """El motor de la API, uno por proceso. Descartarlo cierra sus conexiones: una que
    queda abierta sin dueño se cierra sola más tarde, fuera de quien la abrió."""

    def __call__(self) -> Engine:
        return _crear_motor()

    def cache_clear(self) -> None:
        if _crear_motor.cache_info().currsize:
            _crear_motor().dispose()
        _crear_motor.cache_clear()


motor = _Motor()


def conexion() -> Iterator[Connection]:
    """Una conexión por pedido. Confirma el caso de uso, antes de responder; lo que no
    se confirmó se descarta al cerrar."""
    with motor().connect() as conn:
        yield conn


Conexion = Annotated[Connection, Depends(conexion, scope="function")]


@contextmanager
def en_transaccion(conn: Connection) -> Iterator[None]:
    """Confirma lo que hace el bloque; ante cualquier error lo deshace y relanza el original."""
    try:
        yield
        conn.commit()
    except BaseException:
        conn.rollback()
        raise


def restriccion_violada(e: IntegrityError) -> str | None:
    """El nombre de la restricción que rechazó la escritura, si el motor la informa."""
    return getattr(getattr(e.orig, "diag", None), "constraint_name", None)
