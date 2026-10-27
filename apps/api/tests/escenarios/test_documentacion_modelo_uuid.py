"""El modelo de datos describe el esquema vigente (claves uuid, auditoría renombrada)."""

import re

from tests.escenarios.test_documentacion_vigente import (
    API,
    DISENO,
    _columnas_por_tabla,
    _seccion,
    _texto,
)
from tests.escenarios.test_documentacion_modelo_vigente import MODELO

COMUNES = {"id", "creado_en", "modificado_en"}
RENOMBRES = re.compile(r"ALTER TABLE (\w+) RENAME COLUMN (\w+) TO (\w+)")


def _columnas_vigentes() -> dict[str, set[str]]:
    """Las columnas de cada tabla tras los RENAME COLUMN de `upgrade()` de la 0010."""
    tablas = _columnas_por_tabla()
    migracion = next((API / "migraciones" / "versions").glob("0010_*.py"))
    subida = _texto(migracion).split("def _auditoria_abajo")[0]
    for tabla, viejo, nuevo in RENOMBRES.findall(subida):
        tablas[tabla].discard(viejo)
        tablas[tabla].add(nuevo)
    return tablas


def test_el_modelo_de_datos_documenta_cada_columna_del_esquema_vigente() -> None:
    """el modelo de datos documenta las nueve tablas con sus columnas vigentes
    @REV-07-S8 @DAT-01-S2
    """
    datos = _texto(MODELO)
    tablas = _columnas_vigentes()

    assert len(tablas) == 9
    faltan = [
        f"{tabla}.{columna}"
        for tabla, columnas in sorted(tablas.items())
        for columna in sorted(columnas - COMUNES)
        if f"`{columna}`" not in datos
    ]
    assert faltan == []


def test_cada_seccion_de_tabla_nombra_sus_columnas_vigentes() -> None:
    """cada sección de tabla del modelo nombra sus columnas vigentes
    @REV-07-S8 @DAT-01-S1
    """
    datos = _texto(MODELO)

    for tabla, columnas in _columnas_vigentes().items():
        trozos = re.split(rf"^### {tabla}$", datos, flags=re.M)
        assert len(trozos) > 1, tabla
        seccion = re.split(r"^#+ ", trozos[1], flags=re.M)[0]
        omitidas = [c for c in sorted(columnas) if f"`{c}`" not in seccion]
        assert set(omitidas) <= COMUNES, (tabla, omitidas)


def test_la_seccion_de_datos_del_diseno_remite_al_modelo_de_datos() -> None:
    """la sección Data del diseño de sistema remite al modelo de datos @REV-07-S8"""
    datos = _seccion(_texto(DISENO), "Data")

    assert "modelo-de-datos.md" in datos
    assert "nueve tablas" in datos
