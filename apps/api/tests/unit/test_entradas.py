from typing import Annotated

import pytest
from fastapi import FastAPI, Query
from fastapi.testclient import TestClient
from pydantic import BaseModel, TypeAdapter, ValidationError

from app.interfaz import entradas
from app.interfaz.entradas import (
    Busqueda,
    Clave,
    Correo,
    Identificador,
    Parrafo,
    Texto40,
    Texto120,
    TokenDeDispositivo,
)


class _Pedido(BaseModel):
    nombre: Texto120 = ""
    motivo: Parrafo = ""
    cantidad: Identificador = 1


@pytest.fixture(scope="module")
def cliente() -> TestClient:
    app = FastAPI()
    entradas.instalar(app)

    @app.post("/pedido")
    def pedido(p: _Pedido) -> dict[str, str]:
        return {"nombre": p.nombre, "motivo": p.motivo}

    @app.get("/buscar")
    def buscar(q: Annotated[Busqueda | None, Query()] = None) -> dict[str, str | None]:
        return {"q": q}

    return TestClient(app)


@pytest.mark.parametrize("tipo", [Texto40, Texto120, Busqueda, Correo, TokenDeDispositivo])
@pytest.mark.parametrize("malo", ["a\x00b", "a\x07b", "a\nb", "a\tb", "a\x7fb"])
def test_una_linea_rechaza_los_caracteres_de_control(tipo: object, malo: str) -> None:
    with pytest.raises(ValidationError) as e:
        TypeAdapter(tipo).validate_python(malo)

    assert e.value.errors()[0]["type"] == entradas.CARACTERES_NO_PERMITIDOS


def test_un_parrafo_admite_saltos_de_linea_y_tabulaciones_pero_no_nulos() -> None:
    parrafo = TypeAdapter(Parrafo)

    assert parrafo.validate_python("Lluvia\ny\tviento\r\n") == "Lluvia\ny\tviento\r\n"
    with pytest.raises(ValidationError):
        parrafo.validate_python("Lluvia\x00")


@pytest.mark.parametrize(
    "legitimo", ["Martín Núñez", "O'Brien", "Ñandú  Pérez", "+54 011", "007", "李雷", "Ana-María"]
)
def test_los_datos_legitimos_pasan_intactos(legitimo: str) -> None:
    assert TypeAdapter(Texto120).validate_python(legitimo) == legitimo


@pytest.mark.parametrize(
    ("tipo", "largo"),
    [
        (Texto40, 40),
        (Texto120, 120),
        (Busqueda, 100),
        (Correo, 254),
        (Clave, 128),
        (TokenDeDispositivo, 4096),
    ],
)
def test_el_largo_maximo_pasa_y_uno_mas_no(tipo: object, largo: int) -> None:
    adaptador = TypeAdapter(tipo)

    assert adaptador.validate_python("a" * largo) == "a" * largo
    with pytest.raises(ValidationError) as e:
        adaptador.validate_python("a" * (largo + 1))
    assert e.value.errors()[0]["type"] == "string_too_long"


def test_el_parrafo_tiene_su_cota() -> None:
    with pytest.raises(ValidationError):
        TypeAdapter(Parrafo).validate_python("a" * 1001)


@pytest.mark.parametrize("numero", [0, -1, 2**63, 2**70])
def test_un_identificador_cabe_en_un_bigint(numero: int) -> None:
    with pytest.raises(ValidationError):
        TypeAdapter(Identificador).validate_python(numero)


def test_los_bordes_de_un_identificador_pasan() -> None:
    adaptador = TypeAdapter(Identificador)

    assert adaptador.validate_python(1) == 1
    assert adaptador.validate_python(2**63 - 1) == 2**63 - 1


def test_un_dato_invalido_responde_422_con_un_mensaje_por_campo_sin_repetirlo(
    cliente: TestClient,
) -> None:
    r = cliente.post("/pedido", json={"nombre": "Ana\x00 secreta", "motivo": "x" * 2000})

    assert r.status_code == 422
    assert r.json() == {
        "errores": {
            "nombre": "Tiene caracteres no permitidos",
            "motivo": "Es demasiado largo",
        }
    }
    assert "secreta" not in r.text


def test_un_numero_fuera_de_rango_dice_que_esta_fuera_de_rango(cliente: TestClient) -> None:
    r = cliente.post("/pedido", json={"cantidad": 2**70})

    assert r.json() == {"errores": {"cantidad": "Está fuera del rango permitido"}}


def test_un_dato_de_otro_tipo_tiene_un_mensaje_general(cliente: TestClient) -> None:
    r = cliente.post("/pedido", json={"nombre": 5})

    assert r.json() == {"errores": {"nombre": "El dato no es válido"}}


def test_un_sustituto_suelto_responde_422_con_el_mensaje_de_caracteres(
    cliente: TestClient,
) -> None:
    r = cliente.post(
        "/pedido",
        content='{"nombre": "a\\ud800b"}',
        headers={"Content-Type": "application/json"},
    )

    assert r.status_code == 422
    assert "Tiene caracteres no permitidos" in r.text


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


def test_un_caracter_nulo_en_la_consulta_nombra_el_parametro(cliente: TestClient) -> None:
    r = cliente.get("/buscar", params={"q": "ana\x00"})

    assert r.status_code == 422
    assert r.json() == {"errores": {"q": "Tiene caracteres no permitidos"}}


def test_una_consulta_valida_pasa_intacta(cliente: TestClient) -> None:
    assert cliente.get("/buscar", params={"q": "María O'Neil"}).json() == {"q": "María O'Neil"}
