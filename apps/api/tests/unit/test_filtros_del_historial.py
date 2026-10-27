"""Las condiciones del historial global según la búsqueda de texto."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import pytest

from app.modules.reservas.reglas import FiltrosHistorial
from app.modules.reservas.repositorio import _condiciones_comunes


@pytest.mark.parametrize("q", [None, "", "   "])
def test_sin_busqueda_o_con_busqueda_en_blanco_el_historial_no_filtra_por_texto(
    q: str | None,
) -> None:
    """sin búsqueda o con búsqueda en blanco el historial no filtra por texto @SIM-02-S1"""
    condiciones, parametros = _condiciones_comunes(FiltrosHistorial(q=q))

    assert not any(":q" in c for c in condiciones)
    assert "q" not in parametros


def test_la_busqueda_filtra_por_socio_sede_o_espacio_y_escapa_los_comodines() -> None:
    """la búsqueda filtra por socio, sede o espacio y escapa los comodines @SIM-02-S1"""
    condiciones, parametros = _condiciones_comunes(FiltrosHistorial(q=" 50%_a "))

    assert any(":q" in c for c in condiciones)
    assert parametros["q"] == "%50\\%\\_a%"
