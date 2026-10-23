"""RNF-01-H06-02 sobre el contrato publicado: /health es público (REV-01-ASM-07)."""

import re
from typing import Any

from fastapi.testclient import TestClient

METODOS = {"get", "post", "put", "delete", "patch"}
PUBLICAS = {
    ("post", "/registro"),
    ("post", "/recuperacion"),
    ("post", "/recuperacion/consulta"),
    ("put", "/recuperacion"),
    ("get", "/enlace/recuperar"),
    ("get", "/health"),
}


def test_toda_operacion_de_la_api_sin_usuario_salvo_las_publicas_se_rechaza_con_401(
    api: TestClient,
) -> None:
    """una operación sobre usuarios o reservas sin usuario autenticado se rechaza con 401 @RNF-01-H06-02 @supuesto:RNF-01-SUP-01"""
    esquema: dict[str, Any] = api.get("/openapi.json").json()
    operaciones = {
        (metodo, ruta)
        for ruta, ops in esquema["paths"].items()
        for metodo in ops
        if metodo in METODOS
    }
    protegidas = sorted(operaciones - PUBLICAS)
    aceptadas = []

    for metodo, ruta in protegidas:
        url = re.sub(r"\{[^}]*\}", "1", ruta)
        r = api.request(metodo.upper(), url, json={} if metodo != "get" else None)
        if r.status_code != 401:
            aceptadas.append((metodo, ruta, r.status_code))

    assert not aceptadas, aceptadas
    assert len(protegidas) >= 28
    token_falso = {"Authorization": "Bearer no-es-un-token"}
    assert api.get("/reservas", headers=token_falso).status_code == 401
    assert api.get("/yo", headers=token_falso).status_code == 401
