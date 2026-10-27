"""El contrato de la API en inglés se compara con el main de hoy, que ya pasó de 1ee70de."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import json
import subprocess
from typing import Any

from tests.unit.test_api_en_ingles import RAIZ, _forma

MAIN_ACTUAL = "88d1a9c7161b62c2476822f15f045daa935e367a"
TIPOS_SIN_CINCO = ["recordatorio", "cancelacion_forzosa", "cancelacion_usuario"]


def _con_aviso_de_cinco_minutos(nodo: Any) -> Any:
    """El `openapi.json` de main no se regeneró tras NOT-05: su API ya publica `recordatorio_cinco`."""
    if isinstance(nodo, list):
        if nodo == TIPOS_SIN_CINCO:
            return ["recordatorio", "recordatorio_cinco", "cancelacion_forzosa", "cancelacion_usuario"]
        return [_con_aviso_de_cinco_minutos(n) for n in nodo]
    if isinstance(nodo, dict):
        return {k: _con_aviso_de_cinco_minutos(v) for k, v in nodo.items()}
    return nodo


def test_el_contrato_tiene_las_mismas_rutas_codigos_campos_operation_id_y_security_que_main_en_1ee70de() -> (
    None
):
    """el contrato tiene las mismas rutas, códigos, campos, operationId y security que main en 1ee70de @ENG-13-S2 @assumption:ENG-13-ASM-01"""
    from app.main import app

    de_main = subprocess.run(
        ["git", "show", f"{MAIN_ACTUAL}:apps/api/openapi.json"],
        cwd=RAIZ, capture_output=True, check=True, encoding="utf-8",
    ).stdout  # fmt: skip
    esperado = _forma(_con_aviso_de_cinco_minutos(json.loads(de_main)))
    actual = _forma(app.openapi())

    assert sorted(actual) == sorted(esperado)
    assert {k: v for k, v in actual.items() if v != esperado[k]} == {}
