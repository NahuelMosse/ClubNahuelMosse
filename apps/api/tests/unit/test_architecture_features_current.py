"""El contrato de la API se compara con el main de hoy: NOT-05 sumó `recordatorio_cinco` y esquemas."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
from tests.unit.test_api_in_english_contract_current import (
    contract_differs_from_main,
)


def test_el_contrato_es_el_de_main_salvo_los_cuatro_nombres_de_esquema() -> None:
    """el contrato tiene las mismas rutas, métodos, códigos y formas que el de main, salvo los cuatro nombres de esquema
    @ARQ-04-S3"""
    assert contract_differs_from_main() == {}
