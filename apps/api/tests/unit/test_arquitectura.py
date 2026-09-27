import ast
from pathlib import Path

APP = Path(__file__).resolve().parents[2] / "app"
PERMITIDOS_EN_DOMINIO = {
    "re",
    "unicodedata",
    "dataclasses",
    "datetime",
    "enum",
    "typing",
    "collections",
}


def _imports(archivo: Path) -> set[str]:
    arbol = ast.parse(archivo.read_text(encoding="utf-8"))
    nombres: set[str] = set()
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.Import):
            nombres.update(a.name for a in nodo.names)
        elif isinstance(nodo, ast.ImportFrom) and nodo.module and nodo.level == 0:
            nombres.add(nodo.module)
    return nombres


def test_el_dominio_no_importa_nada_de_afuera() -> None:
    archivos = list((APP / "dominio").rglob("*.py"))
    assert archivos, "no hay módulos de dominio que revisar"
    for archivo in archivos:
        for nombre in _imports(archivo):
            raiz = nombre.split(".")[0]
            assert raiz in PERMITIDOS_EN_DOMINIO or nombre.startswith("app.dominio"), (
                f"{archivo.name} importa {nombre}"
            )


def test_la_aplicacion_no_importa_infraestructura_ni_interfaz() -> None:
    archivos = list((APP / "aplicacion").rglob("*.py"))
    assert archivos, "no hay casos de uso que revisar"
    for archivo in archivos:
        for nombre in _imports(archivo):
            assert not nombre.startswith(("app.infraestructura", "app.interfaz")), (
                f"{archivo.name} importa {nombre}"
            )
