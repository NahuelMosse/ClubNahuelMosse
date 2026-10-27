"""Los módulos de espacios y horarios de la API están en inglés."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast
import hashlib
import json
from pathlib import Path
from typing import Any

import pytest

from tests.unit.test_base_en_ingles import (
    PALABRAS_COMUNES,
    _castellano,
    _nombres_definidos,
    _palabras,
    _textos_de_prosa,
)

RAIZ_API = Path(__file__).resolve().parents[2]
MODULOS = RAIZ_API / "app" / "modules"

NUEVOS = [
    MODULOS / "spaces" / n
    for n in ("__init__.py", "use_cases.py", "rules.py", "repository.py", "routes.py")
] + [
    MODULOS / "availability" / n
    for n in ("__init__.py", "use_cases.py", "slots.py", "rules.py", "repository.py", "routes.py")
]
VIEJOS = [MODULOS / "espacios", MODULOS / "horarios"]

# Palabras del dominio que hoy son castellano y el glosario no lista como palabra suelta.
EXTRA_CASTELLANO = {
    "agenda", "franja", "franjas", "grilla", "disponibilidad", "horarios", "espacios",
    "tipo", "tipos", "clave", "deporte", "deportes", "apertura", "cierre", "dias",
    "altura", "calle", "sede", "espacio", "rango", "libres", "ocupadas", "alta", "baja",
    "catalogo", "sugerencia", "sugerido", "pedido", "cambio", "lista", "errores",
}  # fmt: skip

# Los campos de las clases Pydantic son claves JSON: se quedan en castellano (ASM-05).
BASE_PYDANTIC = {"BaseModel"}

# operationId y huella del contrato de cada operación en main (ASM-07, ASM-09).
OPERACIONES = {
    "GET /espacios/catalogo": ("ver_catalogo_espacios_catalogo_get", "85ad774a64ec0a63"),
    "GET /espacios": ("listar_espacios_espacios_get", "72ae8f6b2ff23811"),
    "POST /espacios": ("alta_de_espacio_espacios_post", "c121f2c39c32dad8"),
    "GET /espacios/nombre": ("sugerir_nombre_espacios_nombre_get", "c55a9cfe03da7b74"),
    "PUT /espacios/{espacio_id}": ("edicion_de_espacio_espacios__espacio_id__put", "497144da1b22dac8"),
    "DELETE /espacios/{espacio_id}": ("baja_de_espacio_espacios__espacio_id__delete", "0a0a581c2daa9a3c"),
    "GET /espacios/{espacio_id}/horarios": (
        "ver_horarios_espacios__espacio_id__horarios_get",
        "184cb629ae4992c9",
    ),
    "GET /espacios/disponibles": ("ver_disponibles_espacios_disponibles_get", "fac4791ddd9510f6"),
}  # fmt: skip


def _sin_nombres_de_esquema(nodo: Any, esquemas: dict[str, Any]) -> Any:
    if isinstance(nodo, dict):
        if "$ref" in nodo:
            esquema = esquemas[nodo["$ref"].rsplit("/", 1)[-1]]
            return _sin_nombres_de_esquema(esquema, esquemas)
        return {
            k: _sin_nombres_de_esquema(v, esquemas)
            for k, v in nodo.items()
            if k not in ("title", "description", "operationId")
        }
    if isinstance(nodo, list):
        return [_sin_nombres_de_esquema(x, esquemas) for x in nodo]
    return nodo


def huella(contrato: dict[str, Any], ruta: str, metodo: str) -> str:
    operacion = contrato["paths"][ruta][metodo.lower()]
    normal = _sin_nombres_de_esquema(operacion, contrato["components"]["schemas"])
    return hashlib.sha256(json.dumps(normal, sort_keys=True).encode()).hexdigest()[:16]


def test_los_modulos_de_espacios_y_horarios_se_llaman_como_dice_el_glosario() -> None:
    """los módulos de espacios y horarios se llaman como dice el glosario @ENG-03-S1 @assumption:ENG-03-ASM-02 @assumption:ENG-03-ASM-03"""
    faltan = [str(p.relative_to(MODULOS)) for p in NUEVOS if not p.exists()]
    sobran = [str(p.relative_to(MODULOS)) for p in VIEJOS if p.exists()]
    importes = [
        str(p.relative_to(RAIZ_API))
        for carpeta in (RAIZ_API / "app", RAIZ_API / "tests", RAIZ_API / "scripts")
        for p in carpeta.rglob("*")
        if p.suffix in {".py", ".sh"}
        and ".venv" not in p.parts
        and p.resolve() != Path(__file__).resolve()
        and any(
            v in p.read_text(encoding="utf-8")
            for v in (
                "modules.espacios",
                "modules.horarios",
                "modules/espacios",
                "modules/horarios",
            )
        )
    ]

    assert not faltan, faltan
    assert not sobran, sobran
    assert not importes, importes


def _campos_pydantic(arbol: ast.AST) -> set[str]:
    campos: set[str] = set()
    for nodo in ast.walk(arbol):
        bases = {b.id for b in getattr(nodo, "bases", []) if isinstance(b, ast.Name)}
        if isinstance(nodo, ast.ClassDef) and bases & BASE_PYDANTIC:
            campos |= {
                s.target.id
                for s in nodo.body
                if isinstance(s, ast.AnnAssign) and isinstance(s.target, ast.Name)
            }
    return campos


def test_los_nombres_comentarios_y_docstrings_de_espacios_y_horarios_estan_en_ingles() -> None:
    """los nombres, comentarios y docstrings de espacios y horarios están en inglés @ENG-03-S2 @assumption:ENG-03-ASM-04 @assumption:ENG-03-ASM-05"""
    castellano = _castellano() | EXTRA_CASTELLANO
    problemas: list[str] = []
    for ruta in NUEVOS:
        if not ruta.exists():
            problemas.append(f"{ruta.name}: no existe")
            continue
        fuente = ruta.read_text(encoding="utf-8")
        arbol = ast.parse(fuente)
        propios = _campos_pydantic(arbol)
        for nombre in sorted(_nombres_definidos(arbol) - propios):
            if castellano & set(_palabras(nombre)):
                problemas.append(f"{ruta.parent.name}/{ruta.name}: nombre {nombre}")
        for texto in _textos_de_prosa(fuente, arbol):
            if PALABRAS_COMUNES.search(texto):
                problemas.append(
                    f"{ruta.parent.name}/{ruta.name}: {texto.strip().splitlines()[0][:60]}"
                )

    assert not problemas, problemas


def test_el_contrato_de_espacios_y_horarios_tiene_lo_mismo_que_main(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el contrato de espacios y horarios tiene las mismas rutas, métodos, códigos, campos y operationId que main @ENG-03-S3 @assumption:ENG-03-ASM-01 @assumption:ENG-03-ASM-07 @assumption:ENG-03-ASM-09"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    from app.main import create_app

    contrato = create_app().openapi()
    publicado = (RAIZ_API / "openapi.json").read_text(encoding="utf-8")
    actual = {}
    for clave in OPERACIONES:
        metodo, ruta = clave.split(" ", 1)
        operacion = contrato["paths"][ruta][metodo.lower()]
        actual[clave] = (operacion["operationId"], huella(contrato, ruta, metodo))

    assert actual == OPERACIONES
    assert json.dumps(contrato, indent=2, ensure_ascii=False) + "\n" == publicado
