import os
from collections.abc import Iterator
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Connection, Engine, create_engine, text

URL_PRUEBAS = os.environ.get(
    "TEST_DATABASE_URL", "postgresql+psycopg://club:club@127.0.0.1:8703/club_test"
)
RAIZ_API = Path(__file__).resolve().parents[1]


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption("--card", action="store", default=None, help="sólo los escenarios de una card")


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    card = config.getoption("--card")
    if not card:
        return
    elegidos, descartados = [], []
    for item in items:
        doc = getattr(getattr(item, "function", None), "__doc__", "") or ""
        if f"@{card}-H" in doc:
            elegidos.append(item)
        else:
            descartados.append(item)
    items[:] = elegidos
    config.hook.pytest_deselected(items=descartados)


@pytest.fixture(scope="session")
def motor() -> Iterator[Engine]:
    motor = create_engine(URL_PRUEBAS)
    if not (motor.url.database or "").endswith("_test"):
        pytest.exit(f"la base de pruebas tiene que terminar en _test: {motor.url.database}", 2)
    # Dos corridas a la vez sobre la misma base se esperan: la sesión borra el esquema entero.
    candado = motor.connect()
    candado.execute(text("SELECT pg_advisory_lock(hashtext('club_test'))"))
    candado.commit()
    with motor.begin() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public"))
    alembic = AlembicConfig(str(RAIZ_API / "alembic.ini"))
    alembic.set_main_option("sqlalchemy.url", URL_PRUEBAS.replace("%", "%%"))
    command.upgrade(alembic, "head")
    yield motor
    candado.close()
    motor.dispose()


@pytest.fixture
def db(motor: Engine) -> Iterator[Connection]:
    """Cada test corre en su propia transacción y la deshace al terminar."""
    with motor.connect() as conn:
        tx = conn.begin()
        yield conn
        tx.rollback()
