import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from pydantic import BaseModel, TypeAdapter, ValidationError

from app.interfaz import entradas
from app.interfaz.entradas import Identificador


class _Pedido(BaseModel):
    nombre: str = ""
    cantidad: Identificador = 1


@pytest.fixture(scope="module")
def cliente() -> TestClient:
    app = FastAPI()
    entradas.instalar(app)

    @app.post("/pedido")
    def pedido(p: _Pedido) -> dict[str, str]:
        return {"nombre": p.nombre}

    return TestClient(app)


@pytest.mark.parametrize("numero", [0, -1, 2**63, 2**70])
def test_un_identificador_cabe_en_un_bigint(numero: int) -> None:
    with pytest.raises(ValidationError):
        TypeAdapter(Identificador).validate_python(numero)


def test_los_bordes_de_un_identificador_pasan() -> None:
    adaptador = TypeAdapter(Identificador)

    assert adaptador.validate_python(1) == 1
    assert adaptador.validate_python(2**63 - 1) == 2**63 - 1


def test_un_numero_fuera_de_rango_dice_que_esta_fuera_de_rango(cliente: TestClient) -> None:
    r = cliente.post("/pedido", json={"cantidad": 2**70})

    assert r.json() == {"errores": {"cantidad": "Está fuera del rango permitido"}}


def test_un_dato_de_otro_tipo_tiene_un_mensaje_general(cliente: TestClient) -> None:
    r = cliente.post("/pedido", json={"nombre": 5})

    assert r.json() == {"errores": {"nombre": "El dato no es válido"}}




def test_un_json_roto_responde_400_sin_repetirlo(cliente: TestClient) -> None:
    r = cliente.post(
        "/pedido", content='{"nombre": "clave-secreta', headers={"Content-Type": "application/json"}
    )

    assert r.status_code == 400
    assert r.json() == {"errores": {"cuerpo": "El cuerpo no es JSON válido"}}


def test_un_cuerpo_que_falta_responde_422(cliente: TestClient) -> None:
    r = cliente.post("/pedido")

    assert r.status_code == 422
    assert list(r.json()["errores"]) == ["cuerpo"]
