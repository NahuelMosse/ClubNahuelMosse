"""El módulo de reservas de la API está en inglés."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast
import io
import json
import re
import tokenize
from pathlib import Path
from typing import Any

import pytest

from tests.unit.test_base_en_ingles import (
    PALABRAS_COMUNES,
    _castellano,
    _nombres_definidos,
    _palabras,
)

RAIZ_API = Path(__file__).resolve().parents[2]
MODULO = RAIZ_API / "app" / "modules" / "bookings"
ARCHIVOS = ["__init__.py", "use_cases.py", "rules.py", "store.py", "repository.py", "routes.py"]
VIEJOS = ["almacen.py", "casos_de_uso.py", "reglas.py", "repositorio.py", "rutas.py"]
CONTRATO_DE_MAIN = Path(__file__).with_name("contrato_reservas_main.json")
# Términos de reservas que el glosario no lista como palabra suelta (ENG-05-ASM-04).
EXTRA_CASTELLANO = {
    "reservar", "cancelar", "modificar", "anular", "historial", "cuando", "proximas",
    "agenda", "cuenta", "alta", "baja", "limpio", "detalle", "pedido", "vista", "lista",
    "cualquiera", "movible", "repetida", "vigente", "mover", "insertar", "bloquear",
    "contar", "comunes", "condiciones", "filtros", "orden", "filas", "fila", "previa",
    "mismo", "pagina", "maximo", "intentos", "exigir", "misma", "propia", "antes",
    "ocupado", "campos", "usuario", "motivo", "estado", "precio", "inicio", "fin",
    "fecha", "desde", "hasta", "horas", "duracion", "futuras", "tipo", "deporte",
}  # fmt: skip


def _es_modelo_pydantic(clase: ast.ClassDef) -> bool:
    return any(
        isinstance(b, ast.Name) and b.id.startswith(("BaseModel", "_Booking")) for b in clase.bases
    ) or any(isinstance(b, ast.Name) and b.id.endswith("Fields") for b in clase.bases)


def _nombres_exentos(arbol: ast.AST) -> set[str]:
    """Campos de los modelos Pydantic y parámetros de los manejadores de ruta (ENG-05-ASM-05)."""
    exentos: set[str] = set()
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.ClassDef) and _es_modelo_pydantic(nodo):
            exentos |= {
                c.target.id
                for c in nodo.body
                if isinstance(c, ast.AnnAssign) and isinstance(c.target, ast.Name)
            }
        if isinstance(nodo, ast.FunctionDef) and any(
            isinstance(d, ast.Call)
            and isinstance(d.func, ast.Attribute)
            and isinstance(d.func.value, ast.Name)
            and d.func.value.id == "router"
            for d in nodo.decorator_list
        ):
            exentos |= {a.arg for a in nodo.args.args}
    return exentos


def _prosa(fuente: str, arbol: ast.AST) -> list[str]:
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


def test_el_modulo_de_reservas_se_llama_como_dice_el_glosario() -> None:
    """el módulo de reservas se llama como dice el glosario @ENG-05-S1 @assumption:ENG-05-ASM-02 @assumption:ENG-05-ASM-03"""
    faltan = [a for a in ARCHIVOS if not (MODULO / a).exists()]
    sobran = [p for p in (MODULO.parent / "reservas").glob("*") if p.name != "__pycache__"]
    viejos = [a for a in VIEJOS if (MODULO / a).exists()]
    importes = [
        str(p.relative_to(RAIZ_API))
        for carpeta in ("app", "tests", "migraciones")
        for p in (RAIZ_API / carpeta).rglob("*.py")
        if p.resolve() != Path(__file__).resolve()
        and ".venv" not in p.parts
        and re.search(
            r"app\.modules\.reservas|modules import [^\n]*\breservas\b",
            p.read_text(encoding="utf-8"),
        )
    ]

    assert not faltan, faltan
    assert not sobran, sobran
    assert not viejos, viejos
    assert importes == [], importes


def test_los_nombres_comentarios_y_docstrings_de_reservas_estan_en_ingles() -> None:
    """los nombres, comentarios y docstrings de reservas están en inglés @ENG-05-S2 @assumption:ENG-05-ASM-04"""
    castellano = _castellano() | EXTRA_CASTELLANO
    problemas: list[str] = []
    for nombre_archivo in ARCHIVOS:
        ruta = MODULO / nombre_archivo
        if not ruta.exists():
            problemas.append(f"{nombre_archivo}: no existe")
            continue
        fuente = ruta.read_text(encoding="utf-8")
        arbol = ast.parse(fuente)
        for nombre in sorted(_nombres_definidos(arbol) - _nombres_exentos(arbol)):
            if castellano & set(_palabras(nombre)):
                problemas.append(f"{nombre_archivo}: nombre {nombre}")
        for texto in _prosa(fuente, arbol):
            if PALABRAS_COMUNES.search(texto):
                problemas.append(f"{nombre_archivo}: {texto.strip().splitlines()[0][:60]}")

    assert not problemas, problemas


def _resolver(nodo: Any, esquemas: dict[str, Any]) -> Any:
    """Cambia cada `$ref` por la forma del esquema: el nombre del esquema no cuenta."""
    if isinstance(nodo, dict):
        if "$ref" in nodo:
            return _resolver(esquemas[nodo["$ref"].rsplit("/", 1)[1]], esquemas)
        return {
            k: _resolver(v, esquemas)
            for k, v in nodo.items()
            if k not in {"title", "description", "summary"}
        }
    if isinstance(nodo, list):
        return [_resolver(v, esquemas) for v in nodo]
    return nodo


def forma_del_contrato(contrato: dict[str, Any]) -> dict[str, Any]:
    """Por operación de reservas: operationId, parámetros, seguridad, cuerpo y respuestas."""
    esquemas = contrato["components"]["schemas"]
    forma: dict[str, Any] = {}
    for ruta, metodos in contrato["paths"].items():
        if not ruta.startswith("/reservas"):
            continue
        for metodo, op in metodos.items():
            forma[f"{metodo.upper()} {ruta}"] = _resolver(
                {
                    "operationId": op["operationId"],
                    "tags": op.get("tags"),
                    "parameters": op.get("parameters", []),
                    "security": op.get("security"),
                    "requestBody": op.get("requestBody"),
                    "responses": op["responses"],
                },
                esquemas,
            )
    return forma


def test_el_contrato_de_reservas_tiene_las_mismas_rutas_metodos_codigos_campos_y_operation_id_que_main(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el contrato de reservas tiene las mismas rutas, métodos, códigos, campos y operationId que main @ENG-05-S3 @assumption:ENG-05-ASM-01"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    from app.main import create_app

    publicado = json.loads((RAIZ_API / "openapi.json").read_text(encoding="utf-8"))
    de_main = json.loads(CONTRATO_DE_MAIN.read_text(encoding="utf-8"))

    assert forma_del_contrato(create_app().openapi()) == de_main
    assert forma_del_contrato(publicado) == de_main
