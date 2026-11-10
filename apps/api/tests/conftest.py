import os
import socket
import uuid
from collections.abc import Callable, Iterator
from pathlib import Path

import httpx2
import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from fastapi.testclient import TestClient
from sqlalchemy import Connection, Engine, create_engine, text

TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL", "postgresql+psycopg://club:club@127.0.0.1:8703/club_test"
)
# The API under test uses the same test database and the Firebase Auth emulator.
os.environ["DATABASE_URL"] = TEST_DATABASE_URL
os.environ.setdefault("FIREBASE_PROJECT_ID", "demo-clubnahuelmosse")
os.environ.setdefault("EMAIL_MODE", "outbox")
# The reminder sweep does not run by itself in the tests: each one fires it with its own clock.
os.environ["REMINDERS_EVERY"] = "0"
API_ROOT = Path(__file__).resolve().parents[1]


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption("--card", action="store", default=None, help="only the scenarios of one card")
    parser.addoption(
        "--no-emulator",
        action="store_true",
        default=False,
        help="skip the API tests when the Firebase Auth emulator is not there",
    )


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    card = config.getoption("--card")
    if not card:
        return
    selected, deselected = [], []
    for item in items:
        doc = getattr(getattr(item, "function", None), "__doc__", "") or ""
        if f"@{card}-H" in doc or f"@{card}-S" in doc or f"@assumption:{card}-ASM-" in doc:
            selected.append(item)
        else:
            deselected.append(item)
    items[:] = selected
    config.hook.pytest_deselected(items=deselected)


@pytest.fixture(scope="session")
def engine() -> Iterator[Engine]:
    engine = create_engine(TEST_DATABASE_URL)
    if not (engine.url.database or "").endswith("_test"):
        pytest.exit(f"the test database must end in _test: {engine.url.database}", 2)
    # Two runs at once on the same database wait for each other: the session drops the whole schema.
    lock = engine.connect()
    lock.execute(text("SELECT pg_advisory_lock(hashtext('club_test'))"))
    lock.commit()
    with engine.begin() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public"))
    alembic = AlembicConfig(str(API_ROOT / "alembic.ini"))
    alembic.set_main_option("sqlalchemy.url", TEST_DATABASE_URL.replace("%", "%%"))
    command.upgrade(alembic, "head")
    yield engine
    lock.close()
    engine.dispose()


@pytest.fixture
def db(engine: Engine) -> Iterator[Connection]:
    """Each test runs in its own transaction and rolls it back at the end."""
    with engine.connect() as conn:
        tx = conn.begin()
        yield conn
        tx.rollback()


def _emulator_host(config: pytest.Config) -> str:
    """The Firebase Auth emulator: without it the run fails, unless skipping is requested."""
    host = os.environ.get("FIREBASE_AUTH_EMULATOR_HOST")
    reason = ""
    if not host:
        reason = "the variable FIREBASE_AUTH_EMULATOR_HOST is missing"
    else:
        name, _, port = host.rpartition(":")
        try:
            socket.create_connection((name, int(port)), timeout=2).close()
        except (OSError, ValueError):
            reason = f"it does not answer at {host}"
    if not reason:
        return str(host)
    message = f"the Firebase Auth emulator is required: {reason}"
    if config.getoption("--no-emulator"):
        pytest.skip(f"{message} (skipped by --no-emulator)")
    pytest.fail(f"{message}; start it or run with --no-emulator", pytrace=False)


@pytest.fixture
def api(request: pytest.FixtureRequest) -> Iterator[TestClient]:
    """The real API against the test database and the Firebase Auth emulator.

    There is no wrapping transaction: each test uses its own unique data.
    """
    _emulator_host(request.config)
    request.getfixturevalue("engine")
    from app.main import create_app

    with TestClient(create_app()) as client:
        yield client


@pytest.fixture
def sign_in(request: pytest.FixtureRequest) -> Callable[[str, str], str | None]:
    """Signs in against the emulator the way the app does: returns the token or None."""
    host = _emulator_host(request.config)

    def _sign_in(email: str, password: str) -> str | None:
        r = httpx2.post(
            f"http://{host}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword",
            params={"key": "clave-del-emulador"},
            json={"email": email, "password": password, "returnSecureToken": True},
        )
        token = r.json().get("idToken") if r.status_code == 200 else None
        return str(token) if token else None

    return _sign_in


@pytest.fixture
def unique() -> Callable[[], str]:
    return lambda: uuid.uuid4().hex[:8]
