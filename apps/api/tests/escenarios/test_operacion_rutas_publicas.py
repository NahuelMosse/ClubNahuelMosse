"""Reemplazos de los tests de REV-01 que contradicen a REV-02: /ready y /metrics no piden sesión
(/metrics responde 404 sin su token) y /ready sale del filtro de Host, como /health."""

import re
from pathlib import Path
from typing import Any

import yaml
from fastapi.testclient import TestClient

METODOS = {"get", "post", "put", "delete", "patch"}
PUBLICAS = {
    ("post", "/registro"),
    ("post", "/recuperacion"),
    ("post", "/recuperacion/consulta"),
    ("put", "/recuperacion"),
    ("get", "/enlace/recuperar"),
    ("get", "/health"),
    ("get", "/ready"),
    ("get", "/metrics"),
}
RAIZ_REPO = Path(__file__).resolve().parents[4]


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


def test_el_despliegue_en_render_apaga_la_documentacion_interactiva() -> None:
    """el blueprint de producción apaga la documentación interactiva y se chequea por /ready
    @REV-01-S15 @assumption:REV-01-ASM-05 @REV-02-ASM-03
    """
    blueprint = yaml.safe_load((RAIZ_REPO / "render.yaml").read_text(encoding="utf-8"))
    web = blueprint["services"][0]
    variables = {v["key"]: v.get("value") for v in web["envVars"]}

    assert variables["DOCUMENTACION_INTERACTIVA"] == "false"
    assert web["healthCheckPath"] == "/ready"


def test_el_contrato_documenta_el_429_el_400_por_host_y_el_422(api: TestClient) -> None:
    """el contrato OpenAPI documenta el 429, el 400 por Host ajeno y el 422 de forma;
    /health y /ready quedan fuera del filtro de Host @REV-01-S15 @REV-02-ASM-03
    """
    rutas = api.get("/openapi.json").json()["paths"]

    for ruta in ("/registro", "/recuperacion"):
        assert {"422", "429"} <= set(rutas[ruta]["post"]["responses"])
    assert "429" in rutas["/yo"]["put"]["responses"]
    for ruta, operaciones in rutas.items():
        if ruta in ("/health", "/ready"):
            continue
        for operacion in operaciones.values():
            assert "400" in operacion["responses"], ruta
