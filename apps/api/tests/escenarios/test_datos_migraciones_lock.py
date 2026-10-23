"""Datos: la migración 0008 corta por lock_timeout, en una base propia por corrida.

Reemplaza el test de lock_timeout de test_datos_tandas_y_cola.py, que usaba la base de nombre fijo
de test_datos.py: dos corridas a la vez se pisaban al crearla.
"""

import threading
import uuid
from collections.abc import Iterator

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Engine, create_engine, text
from test_datos import RAIZ_API, URL_PRUEBAS, _capturar


@pytest.fixture
def base_propia(motor: Engine) -> Iterator[tuple[Engine, AlembicConfig]]:
    """Una base vacía con nombre único, para que otra corrida no la pise."""
    nombre = f"club_rev03_l{uuid.uuid4().hex[:10]}_test"
    servidor = URL_PRUEBAS.rsplit("/", 1)[0]
    admin = create_engine(servidor + "/postgres", isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        conn.execute(text(f'CREATE DATABASE "{nombre}"'))
    url = f"{servidor}/{nombre}"
    base = create_engine(url)
    alembic = AlembicConfig(str(RAIZ_API / "alembic.ini"))
    alembic.set_main_option("sqlalchemy.url", url.replace("%", "%%"))
    try:
        yield base, alembic
    finally:
        base.dispose()
        with admin.connect() as conn:
            conn.execute(text(f'DROP DATABASE IF EXISTS "{nombre}" WITH (FORCE)'))
        admin.dispose()


def test_la_migracion_0008_corta_por_lock_timeout_y_se_puede_volver_a_correr(
    base_propia: tuple[Engine, AlembicConfig],
) -> None:
    """la migración 0008 corta por lock_timeout si una transacción larga tiene la tabla
    @REV-03-S7 @assumption:REV-03-ASM-15
    """
    base, alembic = base_propia
    command.upgrade(alembic, "0007")
    bloqueo = base.connect()
    bloqueo.execute(text("LOCK TABLE notificacion IN ACCESS EXCLUSIVE MODE"))
    resultado: list[BaseException] = []
    hilo = threading.Thread(
        target=lambda: _capturar(resultado, lambda: command.upgrade(alembic, "0008"))
    )

    hilo.start()
    hilo.join(timeout=60)
    bloqueo.rollback()
    bloqueo.close()

    assert not hilo.is_alive()
    assert "lock timeout" in str(resultado[0])
    with base.connect() as conn:
        version = conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
    assert version == "0007"
    command.upgrade(alembic, "0008")
