from collections.abc import Iterator
from functools import cache
from pathlib import Path

from alembic.config import Config as AlembicConfig
from alembic.script import ScriptDirectory
from sqlalchemy import Connection, Engine, create_engine, text

from app.config import RAIZ_API, config

POOL_BASE = 5
POOL_EXTRA = 5
POOL_MAXIMO = POOL_BASE + POOL_EXTRA
# Una base que no responde tiene que fallar rápido y no colgar los pedidos.
_ESPERA_CONEXION_S = 5
_OPCIONES = "-c statement_timeout=10000 -c lock_timeout=5000"


@cache
def motor() -> Engine:
    # Sin los parámetros en los mensajes de error: llevan DNI, correo y nombre y terminan en el log.
    return create_engine(
        config.database_url_app or config.database_url,
        pool_pre_ping=True,
        hide_parameters=True,
        pool_size=POOL_BASE,
        max_overflow=POOL_EXTRA,
        pool_timeout=_ESPERA_CONEXION_S,
        connect_args={"connect_timeout": _ESPERA_CONEXION_S, "options": _OPCIONES},
    )


def conexion() -> Iterator[Connection]:
    """Una conexión por pedido. Confirma el caso de uso, antes de responder; lo que no
    se confirmó se descarta al cerrar."""
    with motor().connect() as conn:
        yield conn


def base_disponible() -> bool:
    try:
        with motor().connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception:
        return False
    return True


def esquema_al_dia() -> bool:
    """La base está en la última migración del código."""
    try:
        ajustes = AlembicConfig(str(RAIZ_API / "alembic.ini"))
        ajustes.set_main_option("script_location", str(Path(RAIZ_API / "migraciones")))
        ultima = ScriptDirectory.from_config(ajustes).get_current_head()
        with motor().connect() as conn:
            actual = conn.execute(text("SELECT version_num FROM alembic_version")).scalar()
    except Exception:
        return False
    return actual == ultima
