"""Lo que confirma un repositorio sigue en la base para otra conexión, como al reiniciar la API."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.interfaz.sembrar_admin import main as sembrar
from app.main import crear_app

CONTRASENA = "ClubNahuel1"


def test_una_sede_dada_de_alta_sobrevive_a_reiniciar_la_api_sobre_la_misma_base(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    motor: Engine,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """una sede dada de alta sobrevive a reiniciar la API sobre la misma base @ARQ-02-S2"""
    s = unico()
    correo = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    argumentos = ["--correo", correo, "--nombre", "Ana", "--apellido", "Díaz",
                  "--dni", dni, "--nacimiento", "1985-06-01"]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(correo, CONTRASENA)
    assert token is not None
    sede = {
        "nombre": f"Sede {s}",
        "direccion": "Calle 1",
        "apertura": "08:00",
        "cierre": "23:00",
        "dias": [1, 2, 3, 4, 5],
    }

    alta = TestClient(crear_app(), base_url="http://localhost").post(
        "/sedes", json=sede, headers={"Authorization": f"Bearer {token}"}
    )
    assert alta.status_code == 201

    with motor.connect() as otra:
        guardada = otra.execute(
            text("SELECT nombre FROM sede WHERE id = :id"), {"id": alta.json()["id"]}
        ).scalar_one()
    assert guardada == sede["nombre"]
    otra_api = TestClient(crear_app(), base_url="http://localhost")
    listado = otra_api.get("/sedes", headers={"Authorization": f"Bearer {token}"}).json()
    assert sede["nombre"] in [x["nombre"] for x in listado["sedes"]]
