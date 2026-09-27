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
        (elegidos if f"@{card}-H" in doc else descartados).append(item)
    items[:] = elegidos
    config.hook.pytest_deselected(items=descartados)


@pytest.fixture(scope="session")
def motor() -> Iterator[Engine]:
    motor = create_engine(URL_PRUEBAS)
    with motor.begin() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public"))
    alembic = AlembicConfig(str(RAIZ_API / "alembic.ini"))
    alembic.set_main_option("script_location", str(RAIZ_API / "migraciones"))
    alembic.set_main_option("sqlalchemy.url", URL_PRUEBAS)
    command.upgrade(alembic, "head")
    yield motor
    motor.dispose()


@pytest.fixture
def db(motor: Engine) -> Iterator[Connection]:
    """Cada test corre en su propia transacción y la deshace al terminar."""
    with motor.connect() as conn:
        tx = conn.begin()
        yield conn
        tx.rollback()
