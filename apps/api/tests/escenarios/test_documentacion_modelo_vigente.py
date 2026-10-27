"""El modelo de datos vive en su página: lo que REV-07-S8 exige de él."""

import re
from pathlib import Path

from tests.escenarios.test_documentacion_vigente import _columnas_por_tabla, _texto

MODELO = Path(__file__).resolve().parents[4] / "docs" / "technical" / "modelo-de-datos.md"


def test_el_modelo_de_datos_documenta_todas_las_tablas() -> None:
    """el modelo de datos documenta las nueve tablas con sus columnas @REV-07-S8"""
    datos = _texto(MODELO)
    tablas = _columnas_por_tabla()

    assert len(tablas) >= 9
    comunes = {"id", "creado_en", "modificado_en"}
    faltan = [
        f"{tabla}.{columna}"
        for tabla, columnas in sorted(tablas.items())
        for columna in sorted(columnas - comunes)
        if f"`{columna}`" not in datos
    ]
    assert faltan == []


def test_el_modelo_de_datos_lleva_columnas_claves_indices_y_triggers_de_cada_tabla() -> None:
    """el modelo de datos lleva columnas, claves, índices y triggers de cada tabla
    @REV-07-S8 @assumption:REV-07-ASM-03
    """
    datos = _texto(MODELO)

    assert re.search(r"PRIMARY KEY|clave primaria", datos, re.I)
    assert re.search(r"FOREIGN KEY|clave foránea|REFERENCES", datos, re.I)
    assert re.search(r"índice|INDEX", datos, re.I)
    assert re.search(r"trigger", datos, re.I)
    for tabla in _columnas_por_tabla():
        assert f"`{tabla}`" in datos or f"### {tabla}" in datos, tabla


def test_cada_tabla_del_esquema_migrado_figura_en_el_modelo_de_datos_con_sus_columnas() -> None:
    """cada tabla del esquema migrado figura en el modelo de datos con sus columnas
    @REV-07-S8 @assumption:REV-07-ASM-10
    """
    datos = _texto(MODELO)
    tablas = _columnas_por_tabla()

    assert len(tablas) == 9
    for tabla, columnas in tablas.items():
        trozos = re.split(rf"^### {tabla}$", datos, flags=re.M)
        assert len(trozos) > 1, tabla
        seccion = re.split(r"^#+ ", trozos[1], flags=re.M)[0]
        omitidas = [c for c in sorted(columnas) if f"`{c}`" not in seccion]
        assert set(omitidas) <= {"id", "creado_en", "modificado_en"}, (tabla, omitidas)
