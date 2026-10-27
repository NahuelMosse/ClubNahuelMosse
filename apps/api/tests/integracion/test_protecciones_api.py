"""El repaso de seguridad del borde de la API, probado contra la app real."""

from collections.abc import Callable
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.shared.config import config


def test_json_roto_da_400(api: TestClient) -> None:
    r = api.post("/registro", content=b"{roto", headers={"content-type": "application/json"})
    assert r.status_code == 400


@pytest.mark.parametrize(
    "cuerpo",
    [b"[]", b'{"nombre": 12, "dni": {"a": 1}}', b'"texto"', b""],
)
def test_tipos_equivocados_dan_422(api: TestClient, cuerpo: bytes) -> None:
    r = api.post("/registro", content=cuerpo, headers={"content-type": "application/json"})
    assert r.status_code == 422


def test_un_campo_desconocido_no_llega_a_ningun_lado(
    api: TestClient, unico: Callable[[], str]
) -> None:
    s = unico()
    r = api.post(
        "/registro",
        json={
            "nombre": "Ana",
            "apellido": "Pérez",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "2000-03-14",
            "correo": f"rol.{s}@correo.com",
            "contrasena": "ClubNahuel1",
            "rol": "admin",
        },
    )
    assert r.status_code == 201
    # El rol no se toma del pedido: la cuenta nueva siempre es de usuario.
    motor = create_engine(config.database_url)
    with motor.connect() as conn:
        rol: Any = conn.execute(
            text("SELECT rol FROM usuario WHERE correo = :c"), {"c": f"rol.{s}@correo.com"}
        ).scalar_one()
    motor.dispose()
    assert rol == "usuario"


def test_un_error_no_expone_detalles_internos(api: TestClient) -> None:
    r = api.post("/registro", content=b"{roto", headers={"content-type": "application/json"})
    texto = r.text.lower()
    for fuga in ("traceback", "sqlalchemy", "psycopg", "firebase", 'file "'):
        assert fuga not in texto
