import ast
import json
import re
import subprocess
from pathlib import Path
from typing import cast

RAIZ = Path(__file__).resolve().parents[4]
API = RAIZ / "apps" / "api"
APP = API / "app"
MODULOS = APP / "modules"
SHARED = APP / "shared"

CON_CUATRO = {"rutas", "casos_de_uso", "reglas", "repositorio"}
CON_CUATRO_EN_INGLES = {"routes", "use_cases", "rules", "repository"}
ARCHIVOS_DE_CADA_UNA = {
    "venues": CON_CUATRO_EN_INGLES,
    "spaces": CON_CUATRO_EN_INGLES,
    "availability": CON_CUATRO_EN_INGLES,
    "reservas": CON_CUATRO,
    "notificaciones": CON_CUATRO,
    "password_recovery": CON_CUATRO_EN_INGLES,
    "users": {
        "account_routes",
        "registration_routes",
        "registration",
        "profile",
        "password",
        "deactivation",
        "admins",
        "rules",
        "repository",
    },
    "session": {"profile", "use_cases", "current_user", "repository"},
}
FUNCIONALIDADES = set(ARCHIVOS_DE_CADA_UNA)
CASOS_DE_USO = [
    *(f"{f}/casos_de_uso.py" for f in ("reservas", "notificaciones")),
    *(
        f"{f}/use_cases.py"
        for f in ("venues", "spaces", "availability", "password_recovery", "session")
    ),
    *(f"users/{c}.py" for c in ("registration", "profile", "password", "deactivation", "admins")),
]
CAPAS_VIEJAS = ("dominio", "aplicacion", "infraestructura", "interfaz", "dependencias")
BASE_DE_DATOS_Y_WEB = ("sqlalchemy", "fastapi", "psycopg")
ERRORES_COMUNES = {"InvalidData", "Forbidden", "NotFound"}
# Commit en que nació la card: el contrato de la API antes de moverla.
BASE = "612d445fe18ee945ab3c3f8da31d133b11452d23"
RENOMBRADOS = {
    "app__interfaz__reservas__PedidoDeCambio": "PedidoDeCambioDeReserva",
    "app__interfaz__espacios__PedidoDeCambio": "SpaceChangeRequest",
    "app__interfaz__sedes__PedidoDeEdicion": "VenueEditRequest",
    "app__interfaz__sesion__PedidoDeEdicion": "ProfileEditRequest",
    "ConsultaDeEnlace": "LinkCheck",
    "ContrasenaNueva": "NewPassword",
    "ErroresDeCampo": "FieldErrors",
    "ErroresDeContrasena": "PasswordErrors",
    "ErroresDeSede": "VenueErrors",
    "PedidoCambioDeContrasena": "PasswordChangeRequest",
    "PedidoDeEnlace": "LinkRequest",
    "PedidoDeSede": "VenueRequest",
    "PedidoRegistro": "RegistrationRequest",
    "PerfilPropio": "OwnProfile",
    "RegistroCreado": "RegistrationCreated",
    "ReservasFueraDelHorario": "BookingsOutside",
    "SedeVista": "VenueView",
    "Sedes": "VenueList",
    "SinSesion": "NoSession",
    "UsuarioRepetido": "DuplicateUser",
    "Catalogo": "CatalogView",
    "DeporteVista": "SportView",
    "EspacioVista": "SpaceView",
    "FranjaVista": "SlotView",
    "GrillaVista": "SlotGridView",
    "ListaDeEspacios": "SpaceList",
    "PedidoDeEspacio": "SpaceRequest",
    "Sugerencia": "Suggestion",
    "TipoVista": "KindView",
}


def _entradas(carpeta: Path) -> set[str]:
    return {e.name for e in carpeta.iterdir() if e.name not in {"__pycache__", "__init__.py"}}


def _es_submodulo(nombre: str) -> bool:
    """El nombre es un archivo del módulo y el `__init__` de su carpeta no lo exporta."""
    ruta = API.joinpath(*nombre.split("."))
    if not ruta.parent.is_dir():
        return False
    existentes = {e.name for e in ruta.parent.iterdir()}
    if ruta.name not in existentes and f"{ruta.name}.py" not in existentes:
        return False
    init = ruta.parent / "__init__.py"
    exportado = init.is_file() and f'"{ruta.name}"' in init.read_text(encoding="utf-8")
    return not exportado


def _importados(archivo: Path) -> set[str]:
    """Nombres de módulo absolutos que importa el archivo (relativos resueltos)."""
    paquete = list(archivo.relative_to(API).with_suffix("").parts)
    if archivo.name != "__init__.py":
        paquete = paquete[:-1]
    encontrados: set[str] = set()
    for nodo in ast.walk(ast.parse(archivo.read_text(encoding="utf-8"))):
        if isinstance(nodo, ast.Import):
            encontrados.update(a.name for a in nodo.names)
        elif isinstance(nodo, ast.ImportFrom):
            base = paquete[: len(paquete) - (nodo.level - 1)] if nodo.level else []
            modulo = ".".join([*base, *(nodo.module.split(".") if nodo.module else [])])
            encontrados.add(modulo)
            encontrados.update(
                f"{modulo}.{a.name}" for a in nodo.names if _es_submodulo(f"{modulo}.{a.name}")
            )
    return encontrados


def _fuentes(carpeta: Path) -> list[Path]:
    return sorted(p for p in carpeta.rglob("*.py") if "__pycache__" not in p.parts)


def _de_funcionalidades() -> list[Path]:
    return [p for p in _fuentes(MODULOS) if len(p.relative_to(MODULOS).parts) > 1]


def _ajenas(archivo: Path) -> set[tuple[str, str]]:
    """(funcionalidad ajena, resto del módulo) por cada import a otra funcionalidad."""
    propia = archivo.relative_to(MODULOS).parts[0]
    salida: set[tuple[str, str]] = set()
    for nombre in _importados(archivo):
        partes = nombre.split(".")
        if partes[:2] == ["app", "modules"] and len(partes) > 2 and partes[2] != propia:
            salida.add((partes[2], ".".join(partes[3:])))
    return salida


def test_arriba_solo_quedan_main_salud_pruebas_shared_y_modules() -> None:
    """arriba sólo quedan main, salud, pruebas, shared y modules
    @ARQ-04-S1 @assumption:ARQ-04-ASM-01"""
    assert _entradas(APP) == {"main.py", "health.py", "e2e_support.py", "shared", "modules"}
    assert _entradas(MODULOS) == FUNCIONALIDADES


def test_cada_funcionalidad_es_plana_con_rutas_casos_de_uso_reglas_y_repositorio() -> None:
    """cada funcionalidad es plana, con rutas, casos de uso, reglas y repositorio
    @ARQ-04-S1 @assumption:ARQ-04-ASM-02"""
    for nombre, esperados in ARCHIVOS_DE_CADA_UNA.items():
        carpeta = MODULOS / nombre
        assert (carpeta / "__init__.py").is_file(), nombre
        subcarpetas = [e for e in carpeta.iterdir() if e.is_dir() and e.name != "__pycache__"]
        assert subcarpetas == [], nombre
        presentes = {e.stem for e in carpeta.glob("*.py")}
        assert esperados <= presentes, f"{nombre}: faltan {esperados - presentes}"


def test_una_funcionalidad_importa_otra_solo_por_su_init_y_no_hay_ciclos() -> None:
    """una funcionalidad importa otra sólo por su __init__ y no hay ciclos
    @ARQ-04-S2"""
    grafo: dict[str, set[str]] = {f: set() for f in FUNCIONALIDADES}
    archivos = _de_funcionalidades()
    assert {a.relative_to(MODULOS).parts[0] for a in archivos} == FUNCIONALIDADES
    for archivo in archivos:
        propia = archivo.relative_to(MODULOS).parts[0]
        for ajena, resto in _ajenas(archivo):
            assert resto == "", f"{archivo.relative_to(APP)} entra a {ajena}.{resto}"
            grafo.setdefault(propia, set()).add(ajena)

    def ciclo(camino: list[str]) -> list[str] | None:
        for vecino in sorted(grafo.get(camino[-1], set())):
            if vecino in camino:
                return [*camino[camino.index(vecino) :], vecino]
            if (c := ciclo([*camino, vecino])) is not None:
                return c
        return None

    for f in sorted(grafo):
        assert ciclo([f]) is None, f"ciclo: {ciclo([f])}"


def test_shared_no_importa_funcionalidades_y_reglas_no_importa_base_de_datos_ni_web() -> None:
    """shared no importa funcionalidades y reglas no importa base de datos ni web
    @ARQ-04-S2"""
    fuentes_de_shared = _fuentes(SHARED)
    assert fuentes_de_shared
    for archivo in fuentes_de_shared:
        propios = [n for n in _importados(archivo) if n.startswith("app.modules")]
        assert propios == [], f"{archivo.relative_to(APP)} importa {propios}"
    reglas = [p for p in _de_funcionalidades() if p.name in {"reglas.py", "rules.py"}]
    assert {p.parent.name for p in reglas} == FUNCIONALIDADES - {"session"}
    for archivo in reglas:
        for nombre in _importados(archivo):
            assert nombre.split(".")[0] not in BASE_DE_DATOS_Y_WEB, f"{archivo}: {nombre}"


def test_los_casos_de_uso_no_importan_repositorio_ni_rutas() -> None:
    """los casos de uso de cada funcionalidad, también los de usuarios y sesión, no importan repositorio ni rutas
    @ARQ-04-S2"""  # noqa: E501
    for ruta in CASOS_DE_USO:
        archivo = MODULOS / ruta
        assert archivo.is_file(), ruta
        for nombre in _importados(archivo):
            ultimo = nombre.split(".")[-1]
            es_de_la_app = nombre.startswith("app.modules.")
            es_capa_de_arriba = (
                ultimo in {"repositorio", "repository"}
                or ultimo.startswith("rutas")
                or ultimo.endswith("routes")
            )
            assert not (es_de_la_app and es_capa_de_arriba), f"{ruta} importa {nombre}"


def _sin_titulos(documento: object) -> object:
    if isinstance(documento, dict):
        return {
            k: _sin_titulos(v)
            for k, v in documento.items()
            if not (k == "title" and isinstance(v, str))
        }
    if isinstance(documento, list):
        return [_sin_titulos(v) for v in documento]
    return documento


def _contrato(texto: str) -> dict[str, dict[str, object]]:
    contrato: dict[str, dict[str, object]] = json.loads(texto)
    return contrato


def _es_nombre_de_id(nombre: object) -> bool:
    return isinstance(nombre, str) and (
        nombre == "id" or nombre.endswith("_id") or nombre == "reemplazada_por"
    )


def _como_uuid(esquema: object) -> object:
    if not isinstance(esquema, dict):
        return esquema
    if esquema.get("type") == "integer":
        resto = {k: v for k, v in esquema.items() if k not in ("type", "maximum", "minimum")}
        return {**resto, "type": "string", "format": "uuid"}
    if isinstance(esquema.get("anyOf"), list):
        return {**esquema, "anyOf": [_como_uuid(v) for v in esquema["anyOf"]]}
    return esquema


def _con_ids_uuid(documento: object) -> object:
    """Los ids enteros del contrato viejo pasan a uuid, que es como son hoy."""
    if isinstance(documento, list):
        return [_con_ids_uuid(v) for v in documento]
    if not isinstance(documento, dict):
        return documento
    nuevo = {k: _con_ids_uuid(v) for k, v in documento.items()}
    if _es_nombre_de_id(nuevo.get("name")) and "schema" in nuevo:
        nuevo["schema"] = _como_uuid(nuevo["schema"])
    propiedades = nuevo.get("properties")
    if isinstance(propiedades, dict):
        nuevo["properties"] = {
            k: _como_uuid(v) if _es_nombre_de_id(k) else v for k, v in propiedades.items()
        }
    return nuevo


def test_el_contrato_es_el_de_main_salvo_los_cuatro_nombres_de_esquema() -> None:
    """el contrato tiene las mismas rutas, métodos, códigos y formas que el de main, salvo los cuatro nombres de esquema
    @ARQ-04-S3"""  # noqa: E501
    de_main = subprocess.run(
        ["git", "show", f"{BASE}:apps/api/openapi.json"],
        cwd=RAIZ,
        capture_output=True,
        check=True,
        encoding="utf-8",
    ).stdout
    for viejo, nuevo in RENOMBRADOS.items():
        if viejo.startswith("app__"):
            de_main = de_main.replace(viejo, nuevo)
        else:
            de_main = re.sub(rf'(?<=["/]){viejo}(?=")', nuevo, de_main)
    esperado = cast(dict[str, dict[str, object]], _con_ids_uuid(_contrato(de_main)))
    actual = _contrato(
        (API / "openapi.json").read_text(encoding="utf-8").replace("ErrorBody", "Errores")
    )
    assert set(actual["paths"]) == set(esperado["paths"])
    assert _sin_titulos(actual["paths"]) == _sin_titulos(esperado["paths"])
    assert _sin_titulos(actual["components"]) == _sin_titulos(esperado["components"])


def test_los_esquemas_del_contrato_tienen_nombres_de_clase_sin_la_ruta_del_modulo() -> None:
    """los esquemas del contrato tienen nombres de clase, sin la ruta del módulo
    @ARQ-04-S3 @assumption:ARQ-04-ASM-05"""
    contrato = _contrato((API / "openapi.json").read_text(encoding="utf-8"))
    esquemas = set(cast(dict[str, object], contrato["components"]["schemas"]))
    assert [n for n in esquemas if "__" in n] == []
    assert set(RENOMBRADOS.values()) <= esquemas


def _rutas_viejas(archivo: Path) -> list[str]:
    patron = re.compile(r"\bapp\.(" + "|".join(CAPAS_VIEJAS) + r")\b")
    hallados = [n for n in _importados(archivo) if patron.match(n)]
    for nodo in ast.walk(ast.parse(archivo.read_text(encoding="utf-8"))):
        if (
            isinstance(nodo, ast.Constant)
            and isinstance(nodo.value, str)
            and patron.search(nodo.value)
        ):
            hallados.append(nodo.value)
    return hallados


def test_ningun_test_importa_las_rutas_viejas_de_capas() -> None:
    """ningún test importa las rutas viejas de capas
    @ARQ-04-S3 @assumption:ARQ-04-ASM-07"""
    for archivo in sorted((API / "tests").rglob("*.py")):
        if archivo.resolve() == Path(__file__).resolve():
            continue
        assert _rutas_viejas(archivo) == [], f"{archivo.relative_to(API)}"


def test_sesion_lee_la_tabla_usuario_sin_escribirla() -> None:
    """sesion lee la tabla usuario sin escribirla
    @ARQ-04-S2 @assumption:ARQ-04-ASM-03"""
    repositorio = MODULOS / "session" / "repository.py"
    assert repositorio.is_file()
    texto = repositorio.read_text(encoding="utf-8")
    assert re.findall(r"\b(?:insert|update|delete)\(|\.(?:add|commit|merge|flush)\(", texto) == []


def test_los_errores_comunes_viven_en_shared_errores() -> None:
    """los errores comunes viven en shared/errores.py
    @ARQ-04-S1 @assumption:ARQ-04-ASM-06"""

    def clases(archivo: Path) -> set[str]:
        arbol = ast.parse(archivo.read_text(encoding="utf-8"))
        return {n.name for n in ast.walk(arbol) if isinstance(n, ast.ClassDef)}

    errores = SHARED / "errors.py"
    assert errores.is_file()
    assert clases(errores) >= ERRORES_COMUNES
    for archivo in _fuentes(MODULOS):
        assert not clases(archivo) & ERRORES_COMUNES, archivo


def test_notificaciones_no_importa_reservas_el_aviso_recibe_los_datos_que_necesita() -> None:
    """notificaciones no importa reservas: el aviso recibe los datos que necesita
    @ARQ-04-S2 @assumption:ARQ-04-ASM-04"""
    archivos = _fuentes(MODULOS / "notificaciones")
    assert archivos
    for archivo in archivos:
        for nombre in _importados(archivo):
            assert not nombre.startswith("app.modules.reservas"), f"{archivo.name}: {nombre}"
