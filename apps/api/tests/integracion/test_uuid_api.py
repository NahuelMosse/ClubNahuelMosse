"""DAT-01: la API recibe y devuelve los ids como texto UUID."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import re
import uuid

import pytest
from fastapi.testclient import TestClient

UUID_V7 = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _espacio(sede_id: str) -> dict[str, object]:
    return {
        "sede_id": sede_id,
        "deporte": "Futbol",
        "tipo": "F5",
        "techada": False,
        "iluminada": True,
        "precio_por_hora": 38000,
    }


@pytest.fixture
def espacio_id(api: TestClient, token_admin: str, sede: tuple[str, str]) -> str:
    r = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede[0]))
    assert r.status_code == 201, r.text
    id_ = r.json()["id"]
    assert isinstance(id_, str)
    return id_


def test_la_api_devuelve_y_recibe_los_ids_como_texto_uuid(
    api: TestClient, token_admin: str, sede: tuple[str, str], espacio_id: str
) -> None:
    """la API devuelve y recibe los ids como texto UUID en rutas, cuerpos y consultas @DAT-01-S3"""
    sede_id = sede[0]

    assert UUID_V7.match(sede_id)
    assert UUID_V7.match(espacio_id)
    listado = api.get("/espacios", headers=_con(token_admin), params={"sede_id": sede_id})
    assert listado.status_code == 200
    assert espacio_id in [e["id"] for e in listado.json()]
    horarios = api.get(f"/espacios/{espacio_id}/horarios", headers=_con(token_admin))
    assert horarios.status_code == 200, horarios.text


def test_un_id_mal_formado_responde_422_y_uno_que_no_existe_404(
    api: TestClient, token_admin: str, sede: tuple[str, str]
) -> None:
    """un id mal formado en la ruta, en el cuerpo o en la consulta responde 422 y un UUID que no existe responde 404 @DAT-01-S3"""
    admin = _con(token_admin)
    inexistente = str(uuid.uuid4())

    assert api.put("/sedes/no-es-un-uuid", headers=admin, json={}).status_code == 422
    assert api.post("/espacios", headers=admin, json=_espacio("no-es-un-uuid")).status_code == 422
    assert (
        api.get("/espacios", headers=admin, params={"sede_id": "no-es-un-uuid"}).status_code
        == 422
    )
    assert api.delete(f"/espacios/{inexistente}", headers=admin).status_code == 404
    assert api.delete(f"/sedes/{inexistente}", headers=admin).status_code == 404


def test_un_uuid_en_mayusculas_o_sin_guiones_se_acepta(
    api: TestClient, token_admin: str, espacio_id: str
) -> None:
    """un UUID en mayúsculas o sin guiones se acepta y la respuesta lo trae en minúsculas con guiones @assumption:DAT-01-ASM-06"""
    admin = _con(token_admin)

    for escrito in (espacio_id.upper(), espacio_id.replace("-", "")):
        r = api.put(f"/espacios/{escrito}", headers=admin, json={"precio_por_hora": 40000})
        assert r.status_code == 200, r.text
        assert r.json()["id"] == espacio_id


def test_un_metodo_no_admitido_responde_405_aunque_el_id_este_mal_formado(
    api: TestClient, token_admin: str
) -> None:
    """un método no admitido responde 405 aunque el id esté mal formado @assumption:DAT-01-ASM-08"""
    assert api.patch("/sedes/no-es-un-uuid", headers=_con(token_admin)).status_code == 405
