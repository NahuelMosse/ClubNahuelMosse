import ast
import re
import tomllib
from pathlib import Path

API = Path(__file__).resolve().parents[2]
APP = API / "app"
RAIZ = API.parents[1]
INFRA = APP / "infraestructura"

# Cada repositorio escribe sólo las tablas que son suyas.
TABLAS_PROPIAS = {
    "usuarios.py": {"usuario"},
    "reservas.py": {"reserva"},
    "sedes.py": {"sede"},
    "notificaciones.py": {"notificacion", "notificacion_reserva", "dispositivo"},
    "espacios.py": {"espacio"},
    "enlaces.py": {"enlace_recuperacion"},
    "correo.py": {"correo_saliente"},
}
ESCRITURA = re.compile(
    r"(?:INSERT\s+INTO|(?<!FOR\s)(?<!DO\s)UPDATE|DELETE\s+FROM)\s+(\w+)", re.IGNORECASE
)
ZONA_LITERAL = "America/Argentina/Buenos_Aires"


def _modulos(archivo: Path) -> set[str]:
    arbol = ast.parse(archivo.read_text(encoding="utf-8"))
    nombres: set[str] = set()
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.Import):
            nombres.update(a.name for a in nodo.names)
        elif isinstance(nodo, ast.ImportFrom) and nodo.module and nodo.level == 0:
            nombres.add(nodo.module)
    return nombres


def _textos(archivo: Path) -> list[str]:
    arbol = ast.parse(archivo.read_text(encoding="utf-8"))
    return [
        n.value for n in ast.walk(arbol) if isinstance(n, ast.Constant) and isinstance(n.value, str)
    ]


def _fuentes(carpeta: Path) -> list[Path]:
    return [a for a in carpeta.rglob("*.py") if "__pycache__" not in a.parts]


def test_interfaz_no_importa_infraestructura() -> None:
    """interfaz no importa infraestructura: las dependencias salen de dependencias.py @REV-06-S1 @assumption:REV-06-ASM-01"""
    dependencias = APP / "dependencias.py"
    assert dependencias.exists(), "falta app/dependencias.py"
    assert any(m.startswith("app.infraestructura") for m in _modulos(dependencias))
    archivos = _fuentes(APP / "interfaz")
    assert archivos
    for archivo in archivos:
        for nombre in _modulos(archivo):
            assert not nombre.startswith("app.infraestructura"), f"{archivo.name} importa {nombre}"


def test_infraestructura_no_importa_interfaz_ni_aplicacion() -> None:
    """infraestructura no importa interfaz ni aplicacion @REV-06-S1 @assumption:REV-06-ASM-01"""
    archivos = _fuentes(INFRA)
    assert archivos
    for archivo in archivos:
        for nombre in _modulos(archivo):
            assert not nombre.startswith(("app.interfaz", "app.aplicacion")), (
                f"{archivo.name} importa {nombre}"
            )


def test_cada_repositorio_escribe_solo_su_tabla() -> None:
    """cada repositorio escribe sólo su tabla @REV-06-S6 @assumption:REV-06-ASM-05"""
    for archivo in _fuentes(INFRA):
        propias = TABLAS_PROPIAS.get(archivo.name, set())
        for texto in _textos(archivo):
            for tabla in ESCRITURA.findall(texto):
                assert tabla.lower() in propias, f"{archivo.name} escribe la tabla {tabla}"


def test_no_queda_una_supresion_de_tipos() -> None:
    """no queda un type: ignore en la API ni en sus tests @REV-06-S7 @assumption:REV-06-ASM-06"""
    aguja = "type" + ": ignore"
    for carpeta in (APP, API / "tests"):
        for archivo in _fuentes(carpeta):
            assert aguja not in archivo.read_text(encoding="utf-8"), f"{archivo.name} la tiene"


def test_mypy_estricto_cubre_app_y_tests() -> None:
    """mypy estricto cubre app y tests @REV-06-S8"""
    mypy = tomllib.loads((API / "pyproject.toml").read_text(encoding="utf-8"))["tool"]["mypy"]
    assert mypy["strict"] is True
    assert set(mypy["files"]) >= {"app", "tests"}


def test_la_zona_del_club_se_define_una_sola_vez_en_la_api() -> None:
    """la zona del club se define una sola vez en la API @REV-06-S10 @assumption:REV-06-ASM-07"""
    con_zona = sorted(
        a.relative_to(APP).as_posix()
        for a in _fuentes(APP)
        if any(ZONA_LITERAL in t for t in _textos(a))
    )
    assert con_zona == ["dominio/zona.py"]


def test_la_anticipacion_sale_de_dominio_y_no_esta_en_el_sql() -> None:
    """la anticipación del recordatorio sale de dominio y no está escrita en el SQL @REV-06-S9 @assumption:REV-06-ASM-08"""
    archivo = INFRA / "notificaciones.py"
    arbol = ast.parse(archivo.read_text(encoding="utf-8"))
    nombres = {n.id for n in ast.walk(arbol) if isinstance(n, ast.Name)}
    assert "ANTICIPACION" in nombres
    assert not any("1 hour" in t for t in _textos(archivo))


def test_las_rutas_de_mis_reservas_y_de_cancelar_entran_por_aplicacion() -> None:
    """las rutas de mis reservas y de cancelar entran por aplicacion @REV-06-S11 @assumption:REV-06-ASM-09"""
    arbol = ast.parse((APP / "interfaz" / "reservas.py").read_text(encoding="utf-8"))
    traidos = {
        a.name
        for n in ast.walk(arbol)
        if isinstance(n, ast.ImportFrom) and n.module == "app.aplicacion.reservas"
        for a in n.names
    }
    assert {"mis_reservas", "cancelar_reserva"} <= traidos


def test_cada_card_tiene_su_seccion_de_cambios_a_lo_existente() -> None:
    """cada card.md tiene su sección de cambios a lo existente @REV-06-S12 @assumption:REV-06-ASM-10"""
    cards = sorted((RAIZ / "specs").glob("*/card.md"))
    assert cards
    for card in cards:
        lineas = card.read_text(encoding="utf-8").splitlines()
        assert "## Changes to existing behavior" in lineas, f"{card.parent.name} no la tiene"
