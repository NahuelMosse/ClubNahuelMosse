import re

import pytest
from fastapi.testclient import TestClient

from app.config import config
from app.main import crear_app


def test_las_metricas_no_publican_created_y_el_histograma_conserva_sus_cortes(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """las métricas no publican _created y el histograma conserva sus cortes
    @ARQ-02-S1 @assumption:ARQ-02-ASM-02"""
    monkeypatch.setattr(config, "metricas_token", "secreto")
    app = crear_app()
    app.add_api_route("/otra-cosa", lambda: {"ok": True})
    c = TestClient(app, base_url="http://localhost")
    c.get("/otra-cosa")
    metricas = c.get("/metrics", headers={"Authorization": "Bearer secreto"}).text

    assert "_created" not in metricas
    les = set(re.findall(r'solicitud_segundos_bucket\{ruta="/otra-cosa",le="([^"]+)"\}', metricas))
    assert les == {"0.05", "0.1", "0.25", "0.5", "1.0", "2.5", "5.0", "10.0", "+Inf"}
    assert re.search(r'solicitudes_total\{metodo="GET",ruta="/otra-cosa",codigo="200"\}', metricas)
