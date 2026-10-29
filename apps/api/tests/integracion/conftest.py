"""Cuentas y sedes de prueba para los tests de integración, contra la base y el emulador."""

from collections.abc import Callable, Iterator

import pytest
from fastapi.testclient import TestClient

from app.modules.users.seed_admin import main as sembrar

CONTRASENA = "ClubNahuel1"


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def token_admin(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> Iterator[str]:
    s = unico()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(f"admin.{s}@club.com", CONTRASENA)
    assert token is not None
    yield token


@pytest.fixture
def token_usuario(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> str:
    s = unico()
    pedido = {
        "first_name": "Martín",
        "last_name": "Ferreyra",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1994-07-21",
        "email": f"socio.{s}@correo.com",
        "password": CONTRASENA,
    }
    assert api.post("/register", json=pedido).status_code == 201
    token = iniciar_sesion(f"socio.{s}@correo.com", CONTRASENA)
    assert token is not None
    return token


@pytest.fixture
def sede(api: TestClient, token_admin: str, unico: Callable[[], str]) -> tuple[str, str]:
    s = unico()
    r = api.post(
        "/venues",
        headers=_con(token_admin),
        json={
            "name": f"Sede Haedo {s}",
            "address": "Av. Vergara 1850",
            "opens_at": "08:00",
            "closes_at": "23:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    )
    assert r.status_code == 201
    # El nombre compuesto junta las palabras con mayúscula inicial: «Haedo b489» → «HaedoB489».
    return r.json()["id"], f"Haedo{s[0].upper()}{s[1:]}_Vergara_1850"
