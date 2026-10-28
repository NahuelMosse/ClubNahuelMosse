"""El contrato de la API se compara con el main de hoy: NOT-05 sumó `recordatorio_cinco` y esquemas."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
from tests.unit.test_api_en_ingles_contrato_actual import (
    contrato_distinto_del_de_main,
)


def test_el_contrato_es_el_de_main_salvo_los_cuatro_nombres_de_esquema() -> None:
    """el contrato tiene las mismas rutas, métodos, códigos y formas que el de main, salvo los cuatro nombres de esquema
    @ARQ-04-S3"""
    assert contrato_distinto_del_de_main() == {}
