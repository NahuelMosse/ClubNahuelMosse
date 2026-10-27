import ast
import re
from pathlib import Path

API = Path(__file__).resolve().parents[2]
RAIZ = API.parents[1]
MODULOS = API / "app" / "modules"
SHARED = API / "app" / "shared"


def _metodo(archivo: str, nombre: str) -> str:
    arbol = ast.parse((MODULOS / archivo).read_text(encoding="utf-8"))
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.FunctionDef) and nodo.name == nombre:
            return ast.unparse(nodo)
    raise AssertionError(f"{archivo} no tiene {nombre}")


def _codigo(archivos: list[Path]) -> dict[str, str]:
    return {a.parent.name + "/" + a.name: a.read_text(encoding="utf-8") for a in archivos}


def test_el_mapa_del_codigo_sigue_al_dia() -> None:
    """el mapa del código sigue al día @ARQ-02-S3"""
    mapa = (RAIZ / "docs" / "technical" / "mapa-del-codigo.md").read_text(encoding="utf-8")

    assert "`errores_http.py`" in mapa


def test_la_agenda_de_una_sede_se_arma_en_una_sola_funcion_y_con_los_dias_en_tupla() -> None:
    """la agenda de una sede se arma en una sola función y con los días en tupla
    @ARQ-02-S2 @assumption:ARQ-02-ASM-06"""
    codigo = _codigo([a for a in MODULOS.rglob("*.py") if "__pycache__" not in a.parts])
    armados = {n: len(re.findall(r"\bAgenda\(", t)) for n, t in codigo.items()}

    assert sum(armados.values()) == 1
    (archivo,) = [n for n, c in armados.items() if c]
    assert re.search(r"Agenda\([^)]*tuple\(", codigo[archivo], flags=re.DOTALL)


def test_los_repositorios_confirman_con_en_transaccion() -> None:
    """los repositorios confirman con en_transaccion y los métodos que corren dentro de otro
    no lo usan @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    db = (SHARED / "db.py").read_text(encoding="utf-8")
    assert "def in_transaction(" in db
    usan = [
        a.parent.name
        for a in MODULOS.glob("*/repositorio.py")
        if "in_transaction(" in a.read_text(encoding="utf-8")
    ]
    assert len(usan) >= 6

    for archivo, metodo in [
        ("reservas/repositorio.py", "cancelar_futuras_de"),
        ("espacios/repositorio.py", "dar_de_baja_de_sede"),
        ("notificaciones/repositorio.py", "encolar_cancelacion_usuario"),
    ]:
        cuerpo = _metodo(archivo, metodo)
        assert "in_transaction" not in cuerpo, metodo
        assert ".commit()" not in cuerpo, metodo


def test_las_reservas_se_arman_con_fila_mapping() -> None:
    """las reservas se arman con fila._mapping @ARQ-02-S1 @assumption:ARQ-02-ASM-06"""
    reservas = (MODULOS / "reservas" / "repositorio.py").read_text(encoding="utf-8")

    assert "Reserva(**" in reservas
    assert "._mapping" in reservas
