"""Seguridad de la API: el cuerpo que no es JSON."""

from fastapi.testclient import TestClient

ENCABEZADOS = {"Content-Type": "application/json"}


def test_cuerpo_no_json_responde_400_y_forma_invalida_422(api: TestClient) -> None:
    """un cuerpo que no es JSON válido responde 400 y no repite lo recibido; un dato con forma inválida sigue en 422 @REV-01-S5 @assumption:REV-01-ASM-16"""
    roto = api.post("/registro", content='{"nombre": "SECRETO-ZZ9', headers=ENCABEZADOS)
    assert roto.status_code == 400
    assert roto.json() == {"errores": {"cuerpo": "El cuerpo no es JSON válido"}}
    assert "SECRETO-ZZ9" not in roto.text

    forma = api.post("/registro", json={"nombre": 5})
    assert forma.status_code == 422
    assert "errores" in forma.json()
