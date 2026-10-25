import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
APP = RAIZ / "apps" / "api" / "app"
MAPA = RAIZ / "docs" / "technical" / "mapa-del-codigo.md"
CAPAS = ["interfaz", "aplicacion", "dominio", "infraestructura"]
# Rutas que sólo se montan en las pruebas: no son de ninguna funcionalidad.
FUERA = {"interfaz/pruebas.py"}


def _filas() -> list[list[str]]:
    texto = MAPA.read_text(encoding="utf-8")
    seccion = texto.split("### Por funcionalidad", 1)[1].split("\n#", 1)[0]
    return [
        [c.strip() for c in linea.strip("|").split("|")]
        for linea in seccion.splitlines()
        if linea.startswith("| ") and not linea.startswith("| Funcionalidad")
    ]


def test_el_mapa_del_codigo_lista_por_funcionalidad_un_archivo_de_cada_capa_que_existe() -> None:
    """el mapa del código lista por funcionalidad un archivo de cada capa que existe
    @ARQ-01-ASM-03"""
    filas = _filas()
    assert filas
    nombrados: set[str] = set()
    for fila in filas:
        for capa, celda in zip(CAPAS, fila[1:5], strict=True):
            archivos = re.findall(r"`([\w.]+\.py)`", celda)
            assert archivos, f"{fila[0]} no nombra un archivo de {capa}"
            for archivo in archivos:
                assert (APP / capa / archivo).is_file(), f"{capa}/{archivo}"
                nombrados.add(f"{capa}/{archivo}")
    existentes = {
        f"{capa}/{a.name}"
        for capa in CAPAS
        for a in (APP / capa).glob("*.py")
        if a.name != "__init__.py"
    }
    assert existentes - nombrados - FUERA == set()
