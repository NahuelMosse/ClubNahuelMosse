"""La página del modelo de datos muestra las columnas de auditoría de cada tabla."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import re
from pathlib import Path

MODELO = Path(__file__).resolve().parents[4] / "docs" / "technical" / "modelo-de-datos.md"
TABLAS = (
    "app_user",
    "venue",
    "space",
    "booking",
    "recovery_link",
    "outgoing_email",
    "device",
    "notification",
    "notification_booking",
)
AUDITORIA = ("created_at", "updated_at")


def test_cada_tabla_del_diagrama_y_de_su_seccion_muestra_creado_en_y_modificado_en() -> None:
    """cada tabla del diagrama y de su sección muestra creado_en y modificado_en @DOC-02-S1"""
    texto = MODELO.read_text(encoding="utf-8")
    diagrama = texto.split("```mermaid", 1)[1].split("```", 1)[0]
    entidades = texto.split("## Entidades", 1)[1].split("\n## ", 1)[0]

    for tabla in TABLAS:
        bloque = re.search(rf"^\s+{tabla} \{{\n(.*?)\n\s+\}}", diagrama, re.S | re.M)
        assert bloque is not None, tabla
        columnas = {linea.split()[1] for linea in bloque.group(1).splitlines() if linea.strip()}
        assert set(AUDITORIA) <= columnas, (tabla, "diagrama")
        seccion = entidades.split(f"### {tabla}\n", 1)[1].split("\n### ", 1)[0]
        for columna in AUDITORIA:
            assert f"`{columna}`" in seccion, (tabla, columna)
