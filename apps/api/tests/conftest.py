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

URL_PRUEBAS = os.environ.get(
    "TEST_DATABASE_URL", "postgresql+psycopg://club:club@127.0.0.1:8703/club_test"
)
# La API bajo test usa la misma base de pruebas y el emulador de Firebase Auth.
os.environ["DATABASE_URL"] = URL_PRUEBAS
os.environ.setdefault("FIREBASE_PROJECT_ID", "demo-clubnahuelmosse")
os.environ.setdefault("CORREO_MODO", "buzon")
# El barrido de recordatorios no corre solo en los tests: cada uno lo dispara con su reloj.
os.environ["RECORDATORIOS_CADA"] = "0"
# El cliente de pruebas pide con Host «testserver».
os.environ.setdefault("HOSTS_PERMITIDOS", "testserver")
RAIZ_API = Path(__file__).resolve().parents[1]


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption("--card", action="store", default=None, help="sólo los escenarios de una card")
    parser.addoption(
        "--sin-emulador",
        action="store_true",
        default=False,
        help="saltar los tests de API cuando no está el emulador de Firebase Auth",
    )


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    card = config.getoption("--card")
    if not card:
        return
    elegidos, descartados = [], []
    for item in items:
        doc = getattr(getattr(item, "function", None), "__doc__", "") or ""
        if f"@{card}-H" in doc or f"@{card}-S" in doc or f"@assumption:{card}-ASM-" in doc:
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


def _host_emulador(config: pytest.Config) -> str:
    """El emulador de Firebase Auth: sin él la corrida falla, salvo que se pida saltarlo."""
    host = os.environ.get("FIREBASE_AUTH_EMULATOR_HOST")
    motivo = ""
    if not host:
        motivo = "falta la variable FIREBASE_AUTH_EMULATOR_HOST"
    else:
        nombre, _, puerto = host.rpartition(":")
        try:
            socket.create_connection((nombre, int(puerto)), timeout=2).close()
        except (OSError, ValueError):
            motivo = f"no responde en {host}"
    if not motivo:
        return str(host)
    mensaje = f"hace falta el emulador de Firebase Auth: {motivo}"
    if config.getoption("--sin-emulador"):
        pytest.skip(f"{mensaje} (se salta por --sin-emulador)")
    pytest.fail(f"{mensaje}; levantalo o corré con --sin-emulador", pytrace=False)


@pytest.fixture
def api(request: pytest.FixtureRequest) -> Iterator[TestClient]:
    """La API real contra la base de pruebas y el emulador de Firebase Auth.

    No hay transacción envolvente: cada test usa datos propios y únicos.
    """
    _host_emulador(request.config)
    request.getfixturevalue("motor")
    from app.main import crear_app

    with TestClient(crear_app()) as cliente:
        yield cliente


@pytest.fixture
def iniciar_sesion(request: pytest.FixtureRequest) -> Callable[[str, str], str | None]:
    """Inicia sesión contra el emulador como lo haría la app: devuelve el token o None."""
    host = _host_emulador(request.config)

    def _iniciar(correo: str, contrasena: str) -> str | None:
        r = httpx2.post(
            f"http://{host}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword",
            params={"key": "clave-del-emulador"},
            json={"email": correo, "password": contrasena, "returnSecureToken": True},
        )
        token = r.json().get("idToken") if r.status_code == 200 else None
        return str(token) if token else None

    return _iniciar


@pytest.fixture
def unico() -> Callable[[], str]:
    return lambda: uuid.uuid4().hex[:8]
