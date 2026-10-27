"""El contrato de la API se compara con el main de hoy: NOT-05 sumó `recordatorio_cinco` y esquemas."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import json
import subprocess

from tests.unit.test_api_en_ingles import RAIZ, _forma
from tests.unit.test_api_en_ingles_contrato_actual import (
    MAIN_ACTUAL,
    _con_aviso_de_cinco_minutos,
)


def test_el_contrato_es_el_de_main_salvo_los_cuatro_nombres_de_esquema() -> None:
    """el contrato tiene las mismas rutas, métodos, códigos y formas que el de main, salvo los cuatro nombres de esquema
    @ARQ-04-S3"""
    from app.main import app

    de_main = subprocess.run(
        ["git", "show", f"{MAIN_ACTUAL}:apps/api/openapi.json"],
        cwd=RAIZ, capture_output=True, check=True, encoding="utf-8",
    ).stdout  # fmt: skip
    esperado = _forma(_con_aviso_de_cinco_minutos(json.loads(de_main)))
    actual = _forma(app.openapi())

    assert sorted(actual) == sorted(esperado)
    assert {k: v for k, v in actual.items() if v != esperado[k]} == {}
