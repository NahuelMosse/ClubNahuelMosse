"""Escenario mínimo que necesita el emulador de Firebase: lo usan las pruebas de la suite confiable."""

from fastapi.testclient import TestClient


def test_un_pedido_sin_sesion_se_rechaza_con_401(api: TestClient) -> None:
    assert api.get("/me").status_code == 401
