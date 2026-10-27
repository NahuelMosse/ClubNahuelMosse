"""Sólo las rutas de cuenta y /health se sirven sin sesión."""

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


def test_toda_operacion_de_la_api_sin_usuario_autenticado_se_rechaza(api: TestClient) -> None:
    """una operación sobre usuarios o reservas sin usuario autenticado se rechaza
    @RNF-01-H06-02 @supuesto:RNF-01-SUP-01 @REV-02-ASM-03
    """
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
