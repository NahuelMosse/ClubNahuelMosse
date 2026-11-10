"""Lo que confirma un repositorio sigue en la base para otra conexión, como al reiniciar la API."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.main import create_app
from app.modules.users.seed_admin import main as sembrar

CONTRASENA = "ClubNahuel1"


def test_una_sede_dada_de_alta_sobrevive_a_reiniciar_la_api_sobre_la_misma_base(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    engine: Engine,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """una sede dada de alta sobrevive a reiniciar la API sobre la misma base @ARQ-02-S2"""
    s = unique()
    correo = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    argumentos = ["--correo", correo, "--nombre", "Ana", "--apellido", "Díaz",
                  "--dni", dni, "--nacimiento", "1985-06-01"]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = sign_in(correo, CONTRASENA)
    assert token is not None
    venue = {
        "name": f"Sede {s}",
        "address": "Calle 1",
        "opens_at": "08:00",
        "closes_at": "23:00",
        "open_days": [1, 2, 3, 4, 5],
    }

    alta = TestClient(create_app(), base_url="http://localhost").post(
        "/venues", json=venue, headers={"Authorization": f"Bearer {token}"}
    )
    assert alta.status_code == 201

    with engine.connect() as otra:
        guardada = otra.execute(
            text("SELECT name FROM venue WHERE id = :id"), {"id": alta.json()["id"]}
        ).scalar_one()
    assert guardada == venue["name"]
    otra_api = TestClient(create_app(), base_url="http://localhost")
    listado = otra_api.get("/venues", headers={"Authorization": f"Bearer {token}"}).json()
    assert venue["name"] in [x["name"] for x in listado["venues"]]
