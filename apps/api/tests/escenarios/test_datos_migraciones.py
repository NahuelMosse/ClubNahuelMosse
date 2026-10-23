"""Datos: la ida y vuelta de las migraciones, cada corrida con su propia base.

Reemplaza los dos tests de migraciones de test_datos.py, que usaban un nombre fijo de base:
dos corridas a la vez (suite, escenarios y mutaciones) se pisaban al crearla.
"""

import threading
import uuid
from collections.abc import Iterator

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.exc import OperationalError
from test_datos import (
    RAIZ_API,
    REVISIONES,
    URL_PRUEBAS,
    _capturar,
    _esquema,
    _reservas,
    _sembrar,
)


@pytest.fixture
def base_propia(motor: Engine) -> Iterator[tuple[Engine, AlembicConfig]]:
    """Una base vacía con nombre único, para subir y bajar migraciones sin pisar a otra corrida."""
    nombre = f"club_rev03_m{uuid.uuid4().hex[:10]}_test"
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


def test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo_en_base_propia(
    base_propia: tuple[Engine, AlembicConfig],
) -> None:
    """la migración nueva no bloquea las tablas mientras la versión anterior atiende @REV-03-S7"""
    base, alembic = base_propia
    command.upgrade(alembic, "0007")
    _sembrar(base)
    bloqueo = base.connect()
    bloqueo.execute(text("LOCK TABLE reserva IN ACCESS EXCLUSIVE MODE"))
    resultado: list[BaseException] = []
    hilo = threading.Thread(
        target=lambda: _capturar(resultado, lambda: command.upgrade(alembic, "0008"))
    )

    hilo.start()
    hilo.join(timeout=60)
    bloqueo.rollback()
    bloqueo.close()

    assert not hilo.is_alive()
    assert isinstance(resultado[0], OperationalError)
    assert "lock timeout" in str(resultado[0])
    command.upgrade(alembic, "0008")
    with base.connect() as conn:
        invalidos = conn.execute(
            text("SELECT count(*) FROM pg_index WHERE NOT indisvalid")
        ).scalar_one()
    assert invalidos == 0
    assert _reservas(base) == 1


@pytest.mark.parametrize(
    ("anterior", "revision"), list(zip(["0001", *REVISIONES], REVISIONES, strict=False))
)
def test_cada_migracion_va_y_vuelve_con_datos_en_base_propia(
    base_propia: tuple[Engine, AlembicConfig], anterior: str, revision: str
) -> None:
    """@REV-03-S8 @assumption:REV-03-ASM-06"""
    base, alembic = base_propia
    command.upgrade(alembic, "0001")
    _sembrar(base)
    command.upgrade(alembic, anterior)
    antes = _esquema(base)

    command.upgrade(alembic, revision)
    despues = _esquema(base)
    command.downgrade(alembic, "-1")
    vuelta = _esquema(base)
    command.upgrade(alembic, revision)

    assert vuelta == antes
    assert _esquema(base) == despues
    assert _reservas(base) == 1
