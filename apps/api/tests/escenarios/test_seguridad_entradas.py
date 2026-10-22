"""Seguridad de la API: lo que se agrega sobre los escenarios congelados de test_seguridad_api."""

from fastapi.testclient import TestClient


def test_health_responde_aunque_el_host_no_este_en_la_lista(api: TestClient) -> None:
    """/health responde aunque el Host no esté en la lista @REV-01-S17 @assumption:REV-01-ASM-13"""
    salud = api.get("/health", headers={"Host": "interno.render.local"})
    otra = api.get("/yo", headers={"Host": "interno.render.local"})

    assert salud.status_code == 200
    assert otra.status_code == 400
