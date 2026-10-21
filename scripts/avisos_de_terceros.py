"""Arma THIRD_PARTY_NOTICES.md: licencias y atribución de las dependencias de producción.

Python: los metadatos de los paquetes instalados (`importlib.metadata`), siguiendo los
requisitos de las dependencias de `apps/api/pyproject.toml` sin las de desarrollo.
Dart: `apps/mobile/pubspec.lock` más el LICENSE de cada paquete en el caché de pub.
Fuentes: la tabla `name` de los TTF de `apps/mobile/assets/fuentes`.

Uso, desde cualquier directorio, con el intérprete del entorno de la API:
    python scripts/avisos_de_terceros.py              escribe THIRD_PARTY_NOTICES.md
    python scripts/avisos_de_terceros.py --comprobar  sale distinto de cero si no coincide
"""

import argparse
import os
import re
import struct
import sys
import tomllib
from email.header import decode_header, make_header
from email.utils import getaddresses
from importlib.metadata import Distribution, PackageNotFoundError
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
API = RAIZ / "apps" / "api"
MOVIL = RAIZ / "apps" / "mobile"
AVISOS = RAIZ / "THIRD_PARTY_NOTICES.md"
SIN_DATO = "not verified"

Fila = tuple[str, str, str, str]

REQUISITO = re.compile(r"^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\s*(?:\[([^\]]*)\])?")
EXTRA = re.compile(r"""extra\s*==\s*["']([^"']+)["']""")
DERECHOS = re.compile(r"^[/#*\s]*copyright\s*(\(c\)\s*)?\d{4}", re.I)
ARCHIVO_LICENCIA = re.compile(r"(^|/)(licen[cs]e|copying)[^/]*$", re.I)


def normalizar(nombre: str) -> str:
    return re.sub(r"[-_.]+", "-", nombre).lower()


def celda(texto: str) -> str:
    return " ".join(texto.replace("|", "/").split())


def detectar(texto: str) -> list[str]:
    """Los identificadores SPDX que reconoce el texto de una licencia, en orden fijo."""
    t = " ".join(texto.lower().split())
    if "mozilla public license" in t:
        return ["MPL-2.0"]
    encontradas: list[str] = []
    if "gnu lesser general public license" in t:
        encontradas.append("LGPL-3.0" if "version 3" in t else "LGPL-2.1")
    if re.search(r"apache license|apache[ -]2\.0|apache software", t):
        encontradas.append("Apache-2.0")
    if "redistribution and use in source and binary forms" in t or re.search(r"\bbsd\b", t):
        tres = re.search(r"neither the name|endorse or promote|3[- ]clause|bsd[- ]3", t)
        encontradas.append("BSD-3-Clause" if tres else "BSD-2-Clause")
    if "permission to use, copy, modify, and/or distribute" in t or "isc license" in t:
        encontradas.append("ISC")
    if "unlicense" in t or "free and unencumbered software" in t:
        encontradas.append("Unlicense")
    if "permission is hereby granted, free of charge" in t or re.search(r"\bmit\b", t):
        encontradas.append("MIT")
    if "python software foundation" in t:
        encontradas.append("PSF-2.0")
    return encontradas


def _nombres(valor: str) -> list[str]:
    texto = str(make_header(decode_header(valor)))
    return [n.strip().strip("\"'") for n in re.split(r",(?![^<]*>)", texto) if n.strip()]


def _autores(dist: Distribution) -> str:
    md = dist.metadata
    crudo = md.get("Author") or md.get("Maintainer")
    if crudo:
        nombres = _nombres(crudo)
    else:
        correos = md.get_all("Author-email") or md.get_all("Maintainer-email") or []
        nombres = [
            n for n, _ in getaddresses([str(make_header(decode_header(c))) for c in correos])
        ]
    nombres = [re.sub(r"\s*<[^>]*>", "", n).strip("\"' ") for n in nombres if n]
    if not nombres:
        return "autores del proyecto (sin nombre en los metadatos)"
    return ", ".join(nombres[:3]) + (" y otros" if len(nombres) > 3 else "")


def _origen(dist: Distribution) -> str:
    md = dist.metadata
    if md.get("Home-page"):
        return str(md["Home-page"])
    for entrada in md.get_all("Project-URL") or []:
        etiqueta, _, url = str(entrada).partition(",")
        if etiqueta.strip().lower() in ("homepage", "home", "source", "repository", "source code"):
            return url.strip()
    return ""


def _licencia_python(dist: Distribution) -> str:
    md = dist.metadata
    if md.get("License-Expression"):
        return str(md["License-Expression"])
    for archivo in sorted(dist.files or [], key=str):
        if ARCHIVO_LICENCIA.search(archivo.as_posix()):
            contenido = Path(str(archivo.locate())).read_bytes().decode("utf-8", errors="replace")
            encontradas = detectar(contenido)
            if encontradas:
                return " AND ".join(encontradas)
    if md.get("License"):
        encontradas = detectar(str(md["License"]))
        if encontradas:
            return " AND ".join(encontradas)
    for clasificador in md.get_all("Classifier") or []:
        if str(clasificador).startswith("License ::"):
            encontradas = detectar(str(clasificador))
            return " AND ".join(encontradas) or (
                str(clasificador).rsplit("::", 1)[-1].strip() + " (variante sin precisar)"
            )
    return SIN_DATO


def _raices_python() -> list[tuple[str, frozenset[str]]]:
    proyecto = tomllib.loads((API / "pyproject.toml").read_text(encoding="utf-8"))["project"]
    raices: list[tuple[str, frozenset[str]]] = []
    for requisito in proyecto["dependencies"]:
        coincide = REQUISITO.match(requisito)
        if coincide:
            raices.append((normalizar(coincide.group(1)), _extras(coincide.group(2))))
    return raices


def _extras(texto: str | None) -> frozenset[str]:
    return frozenset(normalizar(e) for e in (texto or "").split(",") if e.strip())


def _requisitos_activos(
    dist: Distribution, extras: frozenset[str]
) -> list[tuple[str, frozenset[str]]]:
    activos: list[tuple[str, frozenset[str]]] = []
    for requisito in dist.requires or []:
        cuerpo, _, marcador = requisito.partition(";")
        pedidos = {normalizar(e) for e in EXTRA.findall(marcador)}
        coincide = REQUISITO.match(cuerpo)
        if coincide and (not pedidos or pedidos & extras):
            activos.append((normalizar(coincide.group(1)), _extras(coincide.group(2))))
    return activos


def filas_python() -> list[Fila]:
    """Una fila por paquete instalado alcanzable desde las dependencias de producción."""
    pendientes = _raices_python()
    visitados: set[tuple[str, frozenset[str]]] = set()
    distribuciones: dict[str, Distribution] = {}
    while pendientes:
        nombre, extras = pendientes.pop()
        if (nombre, extras) in visitados:
            continue
        visitados.add((nombre, extras))
        try:
            dist = Distribution.from_name(nombre)
        except PackageNotFoundError:
            continue
        distribuciones[nombre] = dist
        pendientes.extend(_requisitos_activos(dist, extras))
    filas = []
    for nombre, dist in sorted(distribuciones.items()):
        origen = _origen(dist)
        atribucion = _autores(dist) + (f" ({origen})" if origen else "")
        filas.append((nombre, dist.version, _licencia_python(dist), celda(atribucion)))
    return filas


def _cache_pub() -> Path:
    if os.environ.get("PUB_CACHE"):
        return Path(os.environ["PUB_CACHE"])
    if os.environ.get("LOCALAPPDATA"):
        return Path(os.environ["LOCALAPPDATA"]) / "Pub" / "Cache"
    return Path.home() / ".pub-cache"


def paquetes_dart() -> list[tuple[str, str, str, str]]:
    """(nombre, versión, origen, dependencia) de cada paquete de pubspec.lock."""
    paquetes: list[tuple[str, str, str, str]] = []
    actual: dict[str, str] = {}
    nombre = ""

    def cerrar() -> None:
        if nombre:
            paquetes.append(
                (
                    nombre,
                    actual.get("version", ""),
                    actual.get("source", ""),
                    actual.get("dependency", ""),
                )
            )

    en_paquetes = False
    for linea in (MOVIL / "pubspec.lock").read_text(encoding="utf-8").splitlines():
        if linea == "packages:":
            en_paquetes = True
        elif not en_paquetes:
            continue
        elif re.match(r"^\S", linea):
            break
        elif encabezado := re.match(r"^  ([^\s:]+):$", linea):
            cerrar()
            nombre, actual = encabezado.group(1), {}
        elif campo := re.match(r'^    (dependency|source|version): "?([^"]*)"?$', linea):
            actual[campo.group(1)] = campo.group(2)
    cerrar()
    return [p for p in paquetes if p[3] != "direct dev"]


def _licencia_dart(nombre: str, version: str) -> tuple[str, str]:
    archivo = _cache_pub() / "hosted" / "pub.dev" / f"{nombre}-{version}" / "LICENSE"
    if not archivo.is_file():
        return SIN_DATO, "ver el LICENSE del paquete en pub.dev"
    texto = archivo.read_text(encoding="utf-8", errors="replace")
    derechos = next((ln for ln in texto.splitlines() if DERECHOS.match(ln)), "")
    derechos = re.sub(r"^[/#*\s]+", "", derechos)
    return " AND ".join(detectar(texto)) or SIN_DATO, celda(derechos[:140]) or "ver el LICENSE"


def hay_cache_pub(paquetes: list[tuple[str, str, str, str]]) -> bool:
    return all(
        (_cache_pub() / "hosted" / "pub.dev" / f"{n}-{v}" / "LICENSE").is_file()
        for n, v, origen, _ in paquetes
        if origen == "hosted"
    )


def filas_dart(paquetes: list[tuple[str, str, str, str]]) -> list[Fila]:
    filas: list[Fila] = []
    for nombre, version, origen, _ in sorted(paquetes):
        if origen == "sdk":
            filas.append((nombre, version, "BSD-3-Clause", "The Flutter Authors (Flutter SDK)"))
        else:
            licencia, atribucion = _licencia_dart(nombre, version)
            filas.append((nombre, version, licencia, atribucion))
    return filas


def _tabla_name(datos: bytes) -> dict[int, str]:
    cantidad = struct.unpack(">H", datos[4:6])[0]
    for i in range(cantidad):
        etiqueta, _, inicio, largo = struct.unpack(">4sIII", datos[12 + 16 * i : 28 + 16 * i])
        if etiqueta == b"name":
            return _registros_name(datos[inicio : inicio + largo])
    return {}


def _registros_name(tabla: bytes) -> dict[int, str]:
    cantidad, base = struct.unpack(">HH", tabla[2:6])
    nombres: dict[int, str] = {}
    for i in range(cantidad):
        plataforma, _, idioma, id_nombre, largo, inicio = struct.unpack(
            ">6H", tabla[6 + 12 * i : 18 + 12 * i]
        )
        crudo = tabla[base + inicio : base + inicio + largo]
        if plataforma == 3 and id_nombre not in nombres:
            nombres[id_nombre] = crudo.decode("utf-16-be")
        elif plataforma == 1 and id_nombre not in nombres:
            nombres[id_nombre] = crudo.decode("mac-roman")
    return nombres


def filas_fuentes() -> list[Fila]:
    familias: dict[str, tuple[set[str], str]] = {}
    for ttf in sorted((MOVIL / "assets" / "fuentes").glob("*.ttf")):
        nombres = _tabla_name(ttf.read_bytes())
        familia = nombres.get(16) or nombres.get(1, ttf.stem)
        versiones, derechos = familias.get(familia, (set(), nombres.get(0, SIN_DATO)))
        versiones.add(nombres.get(5, SIN_DATO).removeprefix("Version ").split(";")[0].strip())
        familias[familia] = (versiones, derechos)
    return [
        (familia, ", ".join(sorted(versiones)), "OFL-1.1", celda(derechos))
        for familia, (versiones, derechos) in sorted(familias.items())
    ]


def _tabla(filas: list[Fila], columnas: str) -> list[str]:
    lineas = [f"| {columnas} |", "|---|---|---|---|"]
    lineas += [f"| {n} | {v} | {lic} | {a} |" for n, v, lic, a in filas]
    return lineas


def _seccion_mpl(filas: list[Fila]) -> list[str]:
    paquetes = [f"`{n}` {v}" for n, v, lic, _ in filas if "MPL-2.0" in lic]
    if not paquetes:
        return []
    return [
        "",
        "## MPL-2.0",
        "",
        f"Paquetes con licencia MPL-2.0: {', '.join(paquetes)}.",
        "Se usan sin modificar: se instalan tal como los publica su registro y el repositorio no"
        " incluye parches ni copias de su código. El código fuente de cada uno está en el"
        " repositorio de su columna de atribución, y el texto de la licencia en"
        " https://www.mozilla.org/MPL/2.0/.",
    ]


def _seccion_lgpl(filas: list[Fila]) -> list[str]:
    paquetes = [f"`{n}` {v}" for n, v, lic, _ in filas if "LGPL-3.0" in lic]
    if not paquetes:
        return []
    return [
        "",
        "## LGPL-3.0",
        "",
        f"Paquetes con licencia LGPL-3.0: {', '.join(paquetes)}.",
        "La API los usa como biblioteca: Python la enlaza dinámicamente al importarla"
        " (`import psycopg`), su código no se copia en el proyecto y no se modificó. Quien"
        " despliega puede reemplazarla por otra versión, modificada o no, cambiando la versión"
        " en `apps/api/pyproject.toml` y regenerando el entorno con `uv sync`, sin recompilar la"
        " API. Texto de la licencia: https://www.gnu.org/licenses/lgpl-3.0.html.",
        "`psycopg-binary` trae empaquetadas bibliotecas nativas (libpq y sus dependencias)"
        " cuyas licencias propias no se verificaron: not verified.",
    ]


def armar(python: list[Fila], dart: list[Fila], fuentes: list[Fila]) -> str:
    columnas = "Paquete | Versión | Licencia | Atribución"
    lineas = [
        "# Avisos de terceros",
        "",
        "Generado por `python scripts/avisos_de_terceros.py` desde los metadatos de los paquetes"
        " instalados de la API, `apps/mobile/pubspec.lock` y los TTF de la app; no se edita a"
        " mano. Para comprobarlo: `python scripts/avisos_de_terceros.py --comprobar`. La"
        " licencia `not verified` es la que el script no pudo leer.",
        "",
        "## Python (API)",
        "",
        "Dependencias de producción, directas y transitivas, instaladas en el entorno donde se"
        " generó: un paquete que sólo se instala en otra plataforma no figura acá.",
        "",
        *_tabla(python, columnas),
        "",
        "## Dart (app)",
        "",
        "Paquetes de `pubspec.lock` sin las dependencias directas de desarrollo; incluye las"
        " transitivas de las herramientas de desarrollo, que el archivo no distingue. Los del SDK"
        " de Flutter son BSD-3-Clause.",
        "",
        *_tabla(dart, columnas),
        "",
        "## Fuentes",
        "",
        "Archivos de `apps/mobile/assets/fuentes`, bajo la SIL Open Font License 1.1: el texto"
        " completo y los avisos de derechos están en `apps/mobile/assets/fuentes/OFL.txt`.",
        "",
        *_tabla(fuentes, "Familia | Versión | Licencia | Derechos"),
        *_seccion_mpl(python + dart),
        *_seccion_lgpl(python + dart),
    ]
    return "\n".join(lineas) + "\n"


def _filas_de(texto: str, titulo: str) -> list[Fila]:
    cuerpo = next((p for p in re.split(r"^## ", texto, flags=re.M) if p.startswith(titulo)), "")
    filas: list[Fila] = []
    for linea in cuerpo.splitlines():
        celdas = [c.strip() for c in linea.strip("|").split("|")]
        if linea.startswith("| ") and len(celdas) == 4 and celdas[0] not in ("Paquete", "Familia"):
            filas.append((celdas[0], celdas[1], celdas[2], celdas[3]))
    return filas


def diferencias(
    actual: str, python: list[Fila], dart: list[Fila], fuentes: list[Fila]
) -> list[str]:
    """Qué no coincide entre el archivo y lo que el entorno dice hoy."""
    problemas: list[str] = []
    en_archivo = _filas_de(actual, "Python")
    lock = (API / "uv.lock").read_text(encoding="utf-8")
    problemas += [f"python: falta o cambió {f[0]} {f[1]}" for f in python if f not in en_archivo]
    problemas += [
        f"python: {f[0]} no está instalado ni en uv.lock"
        for f in en_archivo
        if f not in python and f'name = "{f[0]}"' not in lock
    ]
    dart_archivo = _filas_de(actual, "Dart")
    if hay_cache_pub(paquetes_dart()):
        problemas += [f"dart: falta o cambió {f[0]} {f[1]}" for f in dart if f not in dart_archivo]
    clave = {(f[0], f[1]) for f in dart}
    problemas += [f"dart: sobra o cambió {f[0]} {f[1]}" for f in dart_archivo if f[:2] not in clave]
    problemas += [f"dart: falta {k[0]} {k[1]}" for k in clave - {f[:2] for f in dart_archivo}]
    problemas += [
        f"fuentes: falta o cambió {f[0]}" for f in fuentes if f not in _filas_de(actual, "Fuentes")
    ]
    return problemas


def main() -> int:
    argumentos = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else "")
    argumentos.add_argument("--comprobar", action="store_true", help="no escribe: compara")
    comprobar = argumentos.parse_args().comprobar

    paquetes = paquetes_dart()
    python, fuentes = filas_python(), filas_fuentes()
    dart = filas_dart(paquetes)
    if comprobar:
        actual = AVISOS.read_text(encoding="utf-8").replace("\r\n", "\n")
        problemas = diferencias(actual, python, dart, fuentes)
        for problema in problemas:
            print(problema)
        print("THIRD_PARTY_NOTICES.md " + ("no coincide" if problemas else "coincide"))
        return 1 if problemas else 0
    if not hay_cache_pub(paquetes):
        print("falta el caché de pub (PUB_CACHE): sin él no se leen las licencias de Dart")
        return 2
    AVISOS.write_text(armar(python, dart, fuentes), encoding="utf-8", newline="\n")
    print(f"escrito {AVISOS.relative_to(RAIZ)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
