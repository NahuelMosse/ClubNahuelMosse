"""Reemplaza al escenario H06-02 de test_requisitos_no_funcionales: /health es público (REV-01-ASM-07)."""

import re
from typing import Any

from fastapi.testclient import TestClient

METODOS = {"get", "post", "put", "delete", "patch"}
PUBLICAS = {
    ("post", "/register"),
    ("post", "/password-recovery"),
    ("post", "/password-recovery/check"),
    ("put", "/password-recovery"),
    ("get", "/link/recover"),
    ("get", "/health"),
}


def test_toda_operacion_de_la_api_sin_usuario_autenticado_se_rechaza(api: TestClient) -> None:
    """una operación sobre usuarios o reservas sin usuario autenticado se rechaza @RNF-01-H06-02 @supuesto:RNF-01-SUP-01"""
    esquema: dict[str, Any] = api.get("/openapi.json").json()
    aceptadas = []
    rechazadas = 0

    for ruta, ops in esquema["paths"].items():
        for metodo in ops:
            if metodo not in METODOS or (metodo, ruta) in PUBLICAS:
                continue
            url = re.sub(r"\{[^}]*\}", "1", ruta)
            r = api.request(metodo.upper(), url, json={} if metodo != "get" else None)
            if r.status_code == 401:
                rechazadas += 1
            else:
                aceptadas.append((metodo, ruta, r.status_code))

    assert not aceptadas, aceptadas
    assert rechazadas >= 25
    token_falso = {"Authorization": "Bearer no-es-un-token"}
    assert api.get("/bookings", headers=token_falso).status_code == 401
    assert api.get("/me", headers=token_falso).status_code == 401
