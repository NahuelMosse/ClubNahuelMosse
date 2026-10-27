"""SIM-02: la API se lee fácil y hace lo mismo."""

import ast
import re
import subprocess
import sys
import tomllib
from pathlib import Path

API = Path(__file__).resolve().parents[2]
APP = API / "app"
REGLAS = "E,F,I,B,UP,SIM,C90,PLR,RET,N,ERA,FBT"
TOPE_DE_LINEAS = 40


def _fuentes() -> list[Path]:
    return [p for p in sorted(APP.rglob("*.py")) if "__pycache__" not in p.parts]


def test_la_api_pasa_ruff_con_las_reglas_de_codigo_legible() -> None:
    """la API pasa ruff con las reglas de código legible @SIM-02-S2 @assumption:SIM-02-ASM-01 @assumption:SIM-02-ASM-02 @assumption:SIM-02-ASM-05"""
    ruff = tomllib.loads((API / "pyproject.toml").read_text(encoding="utf-8"))["tool"]["ruff"]
    lint = ruff["lint"]
    assert set(REGLAS.split(",")) <= set(lint["select"])
    assert lint["mccabe"]["max-complexity"] == 10
    assert lint["pylint"]["max-args"] == 4
    assert "N818" in lint["ignore"]
    assert set(lint["per-file-ignores"]["app/modules/*/*routes.py"]) >= {"PLR0913", "PLR0917"}

    corrida = subprocess.run(
        [sys.executable, "-m", "ruff", "check", "app", "--select", REGLAS, "--no-cache"],
        cwd=API,
        capture_output=True,
        text=True,
        check=False,
    )
    assert corrida.returncode == 0, corrida.stdout + corrida.stderr


def test_ninguna_funcion_de_la_api_pasa_de_40_lineas() -> None:
    """ninguna función de la API pasa de 40 líneas @SIM-02-S2 @assumption:SIM-02-ASM-05"""
    largas = []
    for archivo in _fuentes():
        for nodo in ast.walk(ast.parse(archivo.read_text(encoding="utf-8"))):
            if isinstance(nodo, ast.FunctionDef | ast.AsyncFunctionDef):
                largo = (nodo.end_lineno or nodo.lineno) - nodo.lineno + 1
                if largo > TOPE_DE_LINEAS:
                    largas.append(f"{archivo.relative_to(API)}:{nodo.name} {largo}")
    assert not largas, largas


def test_no_queda_codigo_muerto_ni_valores_con_regla_sin_nombre() -> None:
    """no queda código muerto ni valores con regla sin nombre @SIM-02-S3"""
    problemas = []
    for archivo in _fuentes():
        arbol = ast.parse(archivo.read_text(encoding="utf-8"))
        con_nombre = {
            id(n.value)
            for n in arbol.body
            if isinstance(n, ast.Assign | ast.AnnAssign)
            and n.value is not None
            and all(isinstance(t, ast.Name) and t.id.isupper() for t in _destinos(n))
        }
        for nodo in ast.walk(arbol):
            if isinstance(nodo, ast.Attribute) and nodo.attr == "usuario_id":
                if isinstance(nodo.value, ast.Attribute) and nodo.value.attr == "state":
                    problemas.append(f"{archivo.name}: request.state.usuario_id")
            if isinstance(nodo, ast.Name) and nodo.id == "reemplaza":
                problemas.append(f"{archivo.name}: reemplaza")
            if isinstance(nodo, ast.Constant) and nodo.value in (3600, "23P01"):
                if id(nodo) not in con_nombre:
                    problemas.append(f"{archivo.name}:{nodo.lineno}: {nodo.value!r}")
    assert not problemas, problemas


def _destinos(nodo: ast.Assign | ast.AnnAssign) -> list[ast.expr]:
    return nodo.targets if isinstance(nodo, ast.Assign) else [nodo.target]


def _firmas(fuente: str) -> dict[str, list[str]]:
    firmas: dict[str, list[str]] = {}

    def recorrer(cuerpo: list[ast.stmt], prefijo: str) -> None:
        for nodo in cuerpo:
            if isinstance(nodo, ast.ClassDef):
                recorrer(nodo.body, f"{prefijo}{nodo.name}.")
            elif isinstance(nodo, ast.FunctionDef | ast.AsyncFunctionDef):
                if nodo.name.startswith("_") and not nodo.name.startswith("__"):
                    continue
                a = nodo.args
                nombres = [x.arg for x in (*a.posonlyargs, *a.args, *a.kwonlyargs)]
                firmas[f"{prefijo}{nodo.name}"] = nombres

    recorrer(ast.parse(fuente).body, "")
    return firmas


def test_las_firmas_publicas_de_los_casos_de_uso_y_los_repositorios_son_las_de_main() -> None:
    """las firmas públicas de los casos de uso y los repositorios de cada módulo son las de main @assumption:SIM-02-ASM-03"""
    distintas = []
    comparados = 0
    for archivo in _fuentes():
        if archivo.name == "__init__.py" or archivo.name.startswith("routes"):
            continue
        ruta = archivo.relative_to(API).as_posix()
        en_main = subprocess.run(
            ["git", "show", f"main:./{ruta}"],
            cwd=API,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
        )
        if en_main.returncode != 0:
            continue
        comparados += 1
        antes = _firmas(en_main.stdout)
        ahora = _firmas(archivo.read_text(encoding="utf-8"))
        for nombre, parametros in antes.items():
            if nombre in ahora and ahora[nombre] != parametros:
                distintas.append(f"{ruta}:{nombre} {parametros} -> {ahora.get(nombre)}")
    # Los archivos que se renombraron al inglés ya no tienen ruta en main: sólo se comparan los que conservan el nombre, y de ellos las funciones que lo conservan.
    assert comparados > 2
    assert not distintas, distintas


def test_el_sql_que_se_repetia_en_reservas_vive_en_un_solo_lugar() -> None:
    """el SQL que se repetía en reservas vive en un solo lugar: el total por hora y la superposición 23P01 @SIM-02-S3"""
    texto = "\n".join(
        p.read_text(encoding="utf-8") for p in sorted((APP / "modules" / "bookings").glob("*.py"))
    )
    assert len(re.findall(r"/ 3600", texto)) == 1
    assert texto.count("3600") == 1
    assert texto.count("23P01") == 1


_BLOQUEO = re.compile(r"\bFOR (?:SHARE|NO KEY UPDATE|UPDATE)\b")
_TABLA = re.compile(r"\bFROM\s+(\w+)")
_ORDEN = {"usuario": 0, "sede": 1, "espacio": 2, "reserva": 3}


def _bloqueos(repositorio: Path, metodo: str) -> list[str]:
    """Las tablas que `metodo` bloquea, en el orden en que sus sentencias se ejecutan, siguiendo
    las llamadas a funciones y métodos del mismo archivo y a sus constantes de texto."""
    arbol = ast.parse(repositorio.read_text(encoding="utf-8"))
    funciones: dict[str, ast.FunctionDef] = {}
    constantes: dict[str, str] = {}
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.FunctionDef):
            funciones[nodo.name] = nodo
    for nodo in arbol.body:
        if isinstance(nodo, ast.Assign) and isinstance(nodo.value, ast.Constant):
            for t in nodo.targets:
                if isinstance(t, ast.Name) and isinstance(nodo.value.value, str):
                    constantes[t.id] = nodo.value.value
    vistas: list[str] = []

    def texto(nodo: ast.AST) -> None:
        sql = None
        if isinstance(nodo, ast.Constant) and isinstance(nodo.value, str):
            sql = nodo.value
        elif isinstance(nodo, ast.Name) and nodo.id in constantes:
            sql = constantes[nodo.id]
        if sql and _BLOQUEO.search(sql) and (tabla := _TABLA.search(sql)):
            vistas.append(tabla.group(1))

    def seguir(nodo: ast.AST, visitadas: frozenset[str]) -> None:
        texto(nodo)
        if isinstance(nodo, ast.Call):
            f = nodo.func
            nombre = f.attr if isinstance(f, ast.Attribute) else getattr(f, "id", None)
            for hijo in (nodo.func, *nodo.args, *(k.value for k in nodo.keywords)):
                seguir(hijo, visitadas)
            if nombre in funciones and nombre not in visitadas:
                for sentencia in funciones[nombre].body:
                    seguir(sentencia, visitadas | {nombre})
            return
        for hijo in ast.iter_child_nodes(nodo):
            seguir(hijo, visitadas)

    for sentencia in funciones[metodo].body:
        seguir(sentencia, frozenset({metodo}))
    return vistas


def test_una_reserva_toma_sus_bloqueos_en_el_mismo_orden() -> None:
    """una reserva toma sus bloqueos en el mismo orden @assumption:SIM-02-ASM-04"""
    repositorio = APP / "modules" / "bookings" / "repository.py"
    assert _bloqueos(repositorio, "insert") == ["usuario", "sede", "espacio"]
    assert _bloqueos(repositorio, "move") == ["sede", "espacio", "reserva"]
    for metodo in ("insert", "move"):
        rangos = [_ORDEN[t] for t in _bloqueos(repositorio, metodo)]
        assert rangos == sorted(rangos)
