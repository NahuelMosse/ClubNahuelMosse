import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
MODULOS = RAIZ / "apps" / "api" / "app" / "modules"
MAPA = RAIZ / "docs" / "technical" / "mapa-del-codigo.md"


def _filas() -> dict[str, set[str]]:
    texto = MAPA.read_text(encoding="utf-8")
    seccion = texto.split("### Por funcionalidad", 1)[1].split("\n#", 1)[0]
    filas: dict[str, set[str]] = {}
    for linea in seccion.splitlines():
        if not linea.startswith("| ") or linea.startswith("| Funcionalidad"):
            continue
        nombre, *celdas = [c.strip() for c in linea.strip("|").split("|")]
        filas[nombre.strip("`")] = set(re.findall(r"`([\w.]+\.py)`", " ".join(celdas)))
    return filas


def test_el_mapa_del_codigo_lista_por_funcionalidad_un_archivo_de_cada_capa_que_existe() -> None:
    """el mapa del código lista por funcionalidad un archivo de cada capa que existe
    @ARQ-01-ASM-03"""
    filas = _filas()
    assert filas
    for nombre, archivos in filas.items():
        assert archivos, f"{nombre} no nombra ningún archivo"
        for archivo in archivos:
            assert (MODULOS / nombre / archivo).is_file(), f"{nombre}/{archivo}"


def test_el_mapa_del_codigo_lista_cada_funcionalidad_con_sus_archivos() -> None:
    """el mapa del código lista cada funcionalidad con sus archivos
    @ARQ-04-S1"""
    filas = _filas()
    existentes = {
        carpeta.name: {a.name for a in carpeta.glob("*.py") if a.name != "__init__.py"}
        for carpeta in MODULOS.iterdir()
        if carpeta.is_dir() and carpeta.name != "__pycache__"
    }
    assert existentes
    assert filas == existentes
