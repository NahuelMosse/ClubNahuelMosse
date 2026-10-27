"""La anticipación sale de las reglas por clase de aviso (NOT-05): `LEAD_TIME_BY_KIND`."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast

from tests.unit.test_capas_funcionalidades import MODULOS, _textos


def test_la_anticipacion_sale_de_las_reglas_y_no_esta_en_el_sql() -> None:
    """la anticipación del recordatorio sale de las reglas y no está escrita en el SQL @REV-06-S9 @assumption:REV-06-ASM-08"""
    archivo = MODULOS / "notifications" / "repository.py"
    arbol = ast.parse(archivo.read_text(encoding="utf-8"))
    nombres = {n.id for n in ast.walk(arbol) if isinstance(n, ast.Name)}
    assert "LEAD_TIME_BY_KIND" in nombres
    assert not any("1 hour" in t for t in _textos(archivo))
