"""Reemplazo del test de REV-01 sobre el blueprint de Render: se chequea por /ready."""

from pathlib import Path

import yaml

RAIZ_REPO = Path(__file__).resolve().parents[4]


def test_el_blueprint_de_render_apaga_la_documentacion_y_chequea_por_ready() -> None:
    """el blueprint de producción apaga la documentación interactiva y se chequea por /ready
    @REV-01-S15 @assumption:REV-01-ASM-05 @assumption:REV-01-ASM-07 @REV-02-ASM-03
    """
    blueprint = yaml.safe_load((RAIZ_REPO / "render.yaml").read_text(encoding="utf-8"))
    web = blueprint["services"][0]
    variables = {v["key"]: v.get("value") for v in web["envVars"]}

    assert variables["DOCUMENTACION_INTERACTIVA"] == "false"
    assert web["healthCheckPath"] == "/ready"
