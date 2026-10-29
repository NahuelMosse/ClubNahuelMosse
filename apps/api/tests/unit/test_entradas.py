from uuid import UUID

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from pydantic import BaseModel, TypeAdapter, ValidationError

from app.shared import input_validation
from app.shared.input_validation import Identifier


class _Pedido(BaseModel):
    name: str = ""
    cantidad: Identifier = UUID(int=1)


@pytest.fixture(scope="module")
def cliente() -> TestClient:
    app = FastAPI()
    input_validation.install(app)

    @app.post("/pedido")
    def pedido(p: _Pedido) -> dict[str, str]:
        return {"name": p.name}

    return TestClient(app)


@pytest.mark.parametrize("texto", ["", "1", "no-es-un-uuid", "0123456789abcdef0123456789abcdeg"])
def test_un_identificador_mal_formado_no_pasa(texto: str) -> None:
    with pytest.raises(ValidationError):
        TypeAdapter(Identifier).validate_python(texto)


def test_un_identificador_acepta_mayusculas_y_sin_guiones() -> None:
    adaptador = TypeAdapter(Identifier)
    esperado = UUID("0197b5a2-7c3e-7a10-8f4d-1e2f3a4b5c6d")

    assert adaptador.validate_python("0197B5A2-7C3E-7A10-8F4D-1E2F3A4B5C6D") == esperado
    assert adaptador.validate_python("0197b5a27c3e7a108f4d1e2f3a4b5c6d") == esperado


def test_un_identificador_mal_formado_tiene_un_mensaje_general(cliente: TestClient) -> None:
    r = cliente.post("/pedido", json={"cantidad": "1"})

    assert r.json() == {"errors": {"cantidad": "El dato no es válido"}}


def test_un_dato_de_otro_tipo_tiene_un_mensaje_general(cliente: TestClient) -> None:
    r = cliente.post("/pedido", json={"name": 5})

    assert r.json() == {"errors": {"name": "El dato no es válido"}}


def test_un_json_roto_responde_400_sin_repetirlo(cliente: TestClient) -> None:
    r = cliente.post(
        "/pedido", content='{"name": "clave-secreta', headers={"Content-Type": "application/json"}
    )

    assert r.status_code == 400
    assert r.json() == {"errors": {"body": "El cuerpo no es JSON válido"}}


def test_un_cuerpo_que_falta_responde_422(cliente: TestClient) -> None:
    r = cliente.post("/pedido")

    assert r.status_code == 422
    assert list(r.json()["errors"]) == ["body"]
