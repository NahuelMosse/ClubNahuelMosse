"""La base de la API (shared, config, main, health, e2e_support) está en inglés."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast
import io
import json
import re
import tokenize
from pathlib import Path

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from tests.unit.test_glosario_ingles import GLOSARIO, _traducciones

RAIZ_API = Path(__file__).resolve().parents[2]
APP = RAIZ_API / "app"
SHARED = APP / "shared"

NUEVOS = [
    APP / "main.py",
    APP / "health.py",
    APP / "e2e_support.py",
    SHARED / "config.py",
    SHARED / "db.py",
    SHARED / "firebase_credential.py",
    SHARED / "body_limit.py",
    SHARED / "input_validation.py",
    SHARED / "errors.py",
    SHARED / "http_errors.py",
    SHARED / "identity.py",
    SHARED / "responses.py",
    SHARED / "club_timezone.py",
]
VIEJOS = [
    APP / "salud.py",
    APP / "pruebas.py",
    SHARED / "credencial_firebase.py",
    SHARED / "cuerpo.py",
    SHARED / "entradas.py",
    SHARED / "errores.py",
    SHARED / "errores_http.py",
    SHARED / "identidad.py",
    SHARED / "respuestas.py",
    SHARED / "zona.py",
]
# Palabras que son castellano en el glosario y también inglés o nombres propios de la API.
INGLES = {"admin", "total", "token", "version", "dni", "club", "color", "plan", "no", "real"}
# Los términos de los nombres de hoy que el glosario no lista como palabra suelta.
EXTRA_CASTELLANO = {
    "motor", "conexion", "transaccion", "restriccion", "violada", "ventana", "reintento",
    "cuerpo", "acotado", "limite", "plazo", "segundos", "entradas", "errores", "hora",
    "leer", "instalar", "forma", "identidad", "correo", "contrasena", "nueva", "crear",
    "cuenta", "borrar", "espera", "rechazos", "zona", "credencial", "servicio", "conflicto",
    "salud", "vivo", "pruebas", "ciclo", "vida", "barrido", "recordatorios", "raiz",
    "proyecto", "datos", "invalidos", "duplicado", "demorado", "existente", "prohibido",
    "disponible", "ocupado", "horario", "encontrada", "cambiado", "afuera", "agenda",
    "cambiada", "futuras", "campos", "siguiente", "cantidad", "mensajes", "generico",
    "origenes", "responder", "ingreso", "rechazo", "reservas", "espacio", "sede",
}  # fmt: skip
PALABRAS_COMUNES = re.compile(
    r"\b(de|la|el|los|las|que|por|para|con|una|del|sin|cuando|si)\b", re.I
)


def _castellano() -> set[str]:
    glosario = {
        p for p in _traducciones(GLOSARIO.read_text(encoding="utf-8")) if re.fullmatch(r"[a-z]+", p)
    }
    return (glosario | EXTRA_CASTELLANO) - INGLES


def _palabras(nombre: str) -> list[str]:
    partes = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", nombre).lower().split("_")
    return [p for p in partes if p]


def _nombres_definidos(arbol: ast.AST) -> set[str]:
    nombres: set[str] = set()
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef):
            nombres.add(nodo.name)
        elif isinstance(nodo, ast.arg):
            nombres.add(nodo.arg)
        elif isinstance(nodo, ast.Name) and isinstance(nodo.ctx, ast.Store):
            nombres.add(nodo.id)
        elif isinstance(nodo, ast.Attribute) and isinstance(nodo.ctx, ast.Store):
            nombres.add(nodo.attr)
        elif isinstance(nodo, ast.Global | ast.Nonlocal):
            nombres.update(nodo.names)
    return nombres


def _textos_de_prosa(fuente: str, arbol: ast.AST) -> list[str]:
    textos = [
        t.string
        for t in tokenize.generate_tokens(io.StringIO(fuente).readline)
        if t.type == tokenize.COMMENT
    ]
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.Module | ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef):
            doc = ast.get_docstring(nodo, clean=False)
            if doc:
                textos.append(doc)
    return textos


def test_los_archivos_de_la_base_de_la_api_se_llaman_como_dice_el_glosario() -> None:
    """los archivos de la base de la API se llaman como dice el glosario @ENG-01-S1"""
    faltan = [str(p.relative_to(APP)) for p in NUEVOS if not p.exists()]
    sobran = [str(p.relative_to(APP)) for p in VIEJOS if p.exists()]

    assert not faltan, faltan
    assert not sobran, sobran


def test_los_nombres_comentarios_y_docstrings_de_la_base_de_la_api_estan_en_ingles() -> None:
    """los nombres, comentarios y docstrings de la base de la API están en inglés @ENG-01-S2 @assumption:ENG-01-ASM-04"""
    castellano = _castellano()
    problemas: list[str] = []
    for ruta in NUEVOS:
        if not ruta.exists():
            problemas.append(f"{ruta.name}: no existe")
            continue
        fuente = ruta.read_text(encoding="utf-8")
        arbol = ast.parse(fuente)
        for nombre in sorted(_nombres_definidos(arbol)):
            if castellano & set(_palabras(nombre)):
                problemas.append(f"{ruta.name}: nombre {nombre}")
        for texto in _textos_de_prosa(fuente, arbol):
            if PALABRAS_COMUNES.search(texto):
                problemas.append(f"{ruta.name}: {texto.strip().splitlines()[0][:60]}")

    assert not problemas, problemas


def test_el_contrato_la_salud_y_la_ruta_de_pruebas_responden_igual_que_en_main(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el contrato, la salud y la ruta de pruebas responden igual que en main @ENG-01-S3 @assumption:ENG-01-ASM-05"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr("app.shared.config.config.e2e_testing", True)
    from app.main import create_app

    app = create_app()
    esperado = json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n"
    publicado = (RAIZ_API / "openapi.json").read_text(encoding="utf-8")
    rutas = {getattr(r, "path", "") for r in app.routes}
    salud = TestClient(app).get("/health")

    assert esperado == publicado
    assert salud.json() == {"estado": "vivo", "version": salud.json()["version"]}
    assert any(r.startswith("/_pruebas/") for r in rutas)


def _app_con_errores() -> FastAPI:
    from app.shared import errors, http_errors, input_validation
    from app.shared.body_limit import BodyLimit

    app = FastAPI()
    app.add_middleware(BodyLimit)
    input_validation.install(app)
    http_errors.install(app)

    @app.post("/eco")
    def eco(dato: dict[str, int]) -> dict[str, int]:
        return dato

    @app.get("/invalido")
    def invalido() -> None:
        raise errors.InvalidData({"nombre": "Falta"})

    @app.get("/prohibido")
    def prohibido() -> None:
        raise errors.Forbidden()

    @app.get("/ausente")
    def ausente() -> None:
        raise errors.NotFound()

    return app


def test_los_cuerpos_de_error_413_422_403_y_404_son_los_de_main() -> None:
    """los cuerpos de error 413, 422, 403 y 404 son los de main @ENG-01-S3"""
    cliente = TestClient(_app_con_errores())

    grande = cliente.post("/eco", content=b"x", headers={"content-length": str(1024 * 1024 + 1)})
    forma = cliente.post("/eco", json={"a": "no"})
    invalido = cliente.get("/invalido")
    prohibido = cliente.get("/prohibido")
    ausente = cliente.get("/ausente")

    assert (grande.status_code, grande.content) == (413, b"")
    assert forma.status_code == 422
    assert forma.json() == {"errores": {"a": "El dato no es válido"}}
    assert (invalido.status_code, invalido.json()) == (422, {"errores": {"nombre": "Falta"}})
    assert (prohibido.status_code, prohibido.content) == (403, b"")
    assert (ausente.status_code, ausente.content) == (404, b"")


def test_ningun_test_importa_un_modulo_de_la_base_con_su_nombre_en_castellano() -> None:
    """ningún test importa un módulo de la base con su nombre en castellano @assumption:ENG-01-ASM-03"""
    assert _importes_viejos(RAIZ_API / "tests") == []


def test_ningun_archivo_de_la_api_importa_un_modulo_de_la_base_con_su_nombre_en_castellano() -> (
    None
):
    """ningún archivo de la API importa un módulo de la base con su nombre en castellano @assumption:ENG-01-ASM-06"""
    asunto = [*_importes_viejos(APP), *_importes_viejos(RAIZ_API / "migraciones")]

    assert asunto == []


def _importes_viejos(carpeta: Path) -> list[str]:
    viejos = re.compile(
        r"\bapp\.(salud|pruebas)\b"
        r"|\bapp\.shared\.(credencial_firebase|cuerpo|entradas|errores_http|errores|identidad|respuestas|zona)\b"
        r"|\bfrom app import [^\n]*\b(salud|pruebas)\b"
        r"|\bfrom app\.shared import [^\n]*\b(credencial_firebase|cuerpo|entradas|errores_http|errores|identidad|respuestas|zona)\b"
    )
    yo = Path(__file__).resolve()
    return [
        str(p.relative_to(RAIZ_API))
        for p in carpeta.rglob("*.py")
        if p.resolve() != yo
        and ".venv" not in p.parts
        and viejos.search(p.read_text(encoding="utf-8"))
    ]
