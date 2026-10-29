"""El glosario cubre cada nombre del código de main en 9b83c86 y no junta dos términos en un mismo nombre."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
GLOSARIO = RAIZ / "docs" / "technical" / "glosario-ingles.md"
# El punto de partida del pasaje al inglés: lo que el glosario tiene que cubrir.
BASE = "9b83c86"
# Nombres que ya están en inglés o que no se traducen.
SIN_TRADUCIR = {
    "ctx",
    "detail",
    "input",
    "loc",
    "msg",
    "type",
    "dni",
    "id",
    "token",
    "total",
    "cancelable",
    "q",
    "firebase_uid",
    "admin",
    "api",
    "health",
}
TIPOS_SQL = r"(?:bigint|bigserial|uuid|text|integer|smallint|boolean|date|time|timestamptz)"
# Cada cambio de columnas de una migración, en orden: definición en CREATE TABLE (una línea con `:=` es una variable
# de función), ADD, DROP o RENAME.
CAMBIO_DE_COLUMNA = re.compile(
    rf"^\s+(?P<definida>[a-z_]+) {TIPOS_SQL}\b(?!.*:=)"
    r"|ADD COLUMN (?:IF NOT EXISTS )?(?P<agregada>\w+)"
    r"|DROP COLUMN (?:IF EXISTS )?(?P<quitada>\w+)"
    r"|RENAME COLUMN (?P<vieja>\w+) TO (?P<nueva>\w+)",
    re.M,
)


def _git(*argumentos: str) -> str:
    return subprocess.run(
        ["git", *argumentos], cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", check=True
    ).stdout


def _carpetas(ruta: str) -> set[str]:
    return {
        n
        for n in _git("ls-tree", "--name-only", f"{BASE}:{ruta}").split()
        if not n.startswith("_") and "." not in n
    }


def _nombres_del_contrato() -> set[str]:
    contrato = json.loads(_git("show", f"{BASE}:apps/api/openapi.json"))
    nombres = {r.strip("/").split("/")[0] for r in contrato["paths"]}
    for esquema in contrato["components"]["schemas"].values():
        nombres |= set(esquema.get("properties", {}))
    for ruta in contrato["paths"].values():
        for operacion in ruta.values():
            nombres |= {p["name"] for p in operacion.get("parameters", [])}
    return nombres


def _columnas() -> set[str]:
    """Las columnas que existen después de aplicar las migraciones de main, en orden."""
    carpeta = "apps/api/migrations/versions"
    columnas: set[str] = set()
    for archivo in sorted(
        n for n in _git("ls-tree", "--name-only", f"{BASE}:{carpeta}").split() if n.endswith(".py")
    ):
        # Sin `downgrade` ni sus ayudantes `_*_abajo`: lo que hacen no llega a la base de main.
        subida = re.sub(
            r"^def \w*(?:abajo|downgrade)\w*\(.*?(?=^def |\Z)",
            "",
            _git("show", f"{BASE}:{carpeta}/{archivo}"),
            flags=re.M | re.S,
        )
        for cambio in CAMBIO_DE_COLUMNA.finditer(subida):
            columnas |= {cambio["definida"] or cambio["agregada"] or cambio["nueva"]} - {None}
            columnas -= {cambio["quitada"] or cambio["vieja"]}
    return columnas


def _grupos(texto: str) -> dict[tuple[str, str], list[tuple[str, str]]]:
    """Los pares `castellano`→`inglés` de cada sección y cada renglón: una columna se traduce según su tabla."""
    grupos: dict[tuple[str, str], list[tuple[str, str]]] = {}
    partes = re.split(r"^## (.+)$", texto, flags=re.M)
    for i in range(1, len(partes) - 1, 2):
        for renglon in re.split(r"^- ", partes[i + 1], flags=re.M):
            etiqueta = renglon.split(":", 1)[0].strip()
            grupos[(partes[i], etiqueta)] = re.findall(r"`([^`]+)`→`([^`]+)`", renglon)
    return grupos


def test_el_glosario_cubre_cada_nombre_de_main_en_9b83c86() -> None:
    """el glosario nombra cada módulo de la API, carpeta de la app, columna, campo JSON, parámetro y ruta de main en 9b83c86 @ENG-00-S2"""
    texto = GLOSARIO.read_text(encoding="utf-8")
    nombres = (
        _carpetas("apps/api/app/modules")
        | _carpetas("apps/mobile/lib")
        | _nombres_del_contrato()
        | _columnas()
    )

    # Un tramo de ruta vale citado como `/tramo`.
    assert (
        sorted(n for n in nombres - SIN_TRADUCIR if f"`{n}`" not in texto and f"`/{n}" not in texto)
        == []
    )


def test_el_glosario_no_junta_dos_terminos_en_un_mismo_nombre() -> None:
    """dentro de cada renglón del glosario, ningún término tiene dos traducciones ni dos términos comparten traducción @ENG-00-S2"""
    dobles = []
    for grupo, pares in _grupos(GLOSARIO.read_text(encoding="utf-8")).items():
        por_origen: dict[str, set[str]] = defaultdict(set)
        por_destino: dict[str, set[str]] = defaultdict(set)
        for origen, destino in pares:
            por_origen[origen].add(destino)
            # `creado_en` y `creada_en` son la misma palabra en otro género: juntarlas en `created_at` es buscado.
            por_destino[destino].add(re.sub(r"[ao](?=_|$)", "", origen))
        dobles += [(grupo, o, d) for o, d in por_origen.items() if len(d) > 1]
        dobles += [(grupo, o, d) for d, o in por_destino.items() if len(o) > 1]

    assert dobles == []
