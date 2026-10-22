"""RNF-01 probado contra el contrato que la API publica, sin leer el código de la app."""

import json
import re
from pathlib import Path
from typing import Any

from fastapi.testclient import TestClient

RAIZ_API = Path(__file__).resolve().parents[2]
METODOS = {"get", "post", "put", "delete", "patch"}

# Lo que la API sirve sin sesión: alta de cuenta y recuperación de contraseña (con la página del enlace del correo).
PUBLICAS = {
    ("post", "/registro"),
    ("post", "/recuperacion"),
    ("post", "/recuperacion/consulta"),
    ("put", "/recuperacion"),
    ("get", "/enlace/recuperar"),
}


def _operaciones(esquema: dict[str, Any]) -> set[tuple[str, str]]:
    return {
        (metodo, ruta)
        for ruta, ops in esquema["paths"].items()
        for metodo in ops
        if metodo in METODOS
    }


def test_la_api_publica_openapi_con_todos_los_endpoints_del_contrato(api: TestClient) -> None:
    """la API publica su documentación OpenAPI con todos los endpoints del contrato que usa la app @RNF-01-H04-01"""
    publicado = api.get("/openapi.json")
    versionado = json.loads((RAIZ_API / "openapi.json").read_text(encoding="utf-8"))
    docs = api.get("/docs")

    assert publicado.status_code == 200
    assert _operaciones(publicado.json()) == _operaciones(versionado)
    assert len(_operaciones(versionado)) >= 30
    assert PUBLICAS <= _operaciones(versionado)
    assert docs.status_code == 200
    assert "swagger" in docs.text.lower()


def test_toda_operacion_de_la_api_sin_usuario_se_rechaza_con_401(api: TestClient) -> None:
    """una operación sobre usuarios o reservas sin usuario autenticado se rechaza con 401 @RNF-01-H06-02 @supuesto:RNF-01-SUP-01"""
    esquema: dict[str, Any] = api.get("/openapi.json").json()
    protegidas = sorted(_operaciones(esquema) - PUBLICAS)
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


def test_rnf_01_h04_01_se_prueba_con_el_contrato_publicado_y_no_leyendo_el_readme(
    api: TestClient,
) -> None:
    """RNF-01-H04-01 se prueba con el contrato publicado y no leyendo el README @REV-08-S4 @assumption:REV-08-ASM-08"""
    contrato = api.get("/openapi.json")

    assert contrato.status_code == 200
    assert len(contrato.json()["paths"]) >= 20
    assert "swagger" in api.get("/docs").text.lower()
