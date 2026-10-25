"""Arma sitio-docs/docs/codigo/ con los docstrings de la API, una página por capa.

Lee el código con `ast`, sin importarlo: no hace falta instalar la API ni tener sus variables.
"""

import ast
import json
import sys
from pathlib import Path

SITIO = Path(__file__).resolve().parent.parent
APP = SITIO.parent / "apps" / "api" / "app"
DESTINO = SITIO / "docs" / "codigo"
GITHUB = "https://github.com/NahuelMosse/ClubNahuelMosse/blob/main/apps/api/app/"

CAPAS = [
    ("interfaz", "Interfaz", "Las rutas HTTP, los middleware y los comandos de consola."),
    ("aplicacion", "Aplicación", "Los casos de uso: orquestan las reglas y los repositorios."),
    ("dominio", "Dominio", "Las reglas del negocio, sin base de datos ni red."),
    ("infraestructura", "Infraestructura", "El SQL, Firebase, el correo y las notificaciones."),
    ("", "Raíz", "El armado de la aplicación, la configuración y las dependencias."),
]


def texto(docstring: str | None) -> str:
    if not docstring:
        return ""
    # Markdown común: un `<` suelto se leería como HTML.
    return docstring.strip().replace("<", "&lt;") + "\n\n"


def firma(nodo: ast.FunctionDef | ast.AsyncFunctionDef) -> str:
    previo = "async def" if isinstance(nodo, ast.AsyncFunctionDef) else "def"
    devuelve = f" -> {ast.unparse(nodo.returns)}" if nodo.returns else ""
    return f"{previo} {nodo.name}({ast.unparse(nodo.args)}){devuelve}"


def publico(nombre: str) -> bool:
    return not nombre.startswith("_") or nombre == "__init__"


def modulo(ruta: Path) -> str:
    arbol = ast.parse(ruta.read_text(encoding="utf-8"))
    relativa = ruta.relative_to(APP).as_posix()
    nombre = "app." + relativa.removesuffix(".py").replace("/", ".")
    salida = [f"## `{nombre}`\n\n", f"[Ver el código]({GITHUB}{relativa})\n\n", texto(ast.get_docstring(arbol))]
    for nodo in arbol.body:
        if isinstance(nodo, (ast.FunctionDef, ast.AsyncFunctionDef)) and publico(nodo.name):
            salida += [f"### `{nodo.name}`\n\n", f"```python\n{firma(nodo)}\n```\n\n", texto(ast.get_docstring(nodo))]
        elif isinstance(nodo, ast.ClassDef) and publico(nodo.name):
            bases = ", ".join(ast.unparse(b) for b in nodo.bases)
            salida += [
                f"### `{nodo.name}`\n\n",
                f"```python\nclass {nodo.name}({bases})\n```\n\n" if bases else "",
                texto(ast.get_docstring(nodo)),
            ]
            for metodo in nodo.body:
                if isinstance(metodo, (ast.FunctionDef, ast.AsyncFunctionDef)) and publico(metodo.name):
                    doc = ast.get_docstring(metodo)
                    if doc:
                        salida += [f"- **`{metodo.name}`**: {texto(doc).strip()}\n"]
            salida.append("\n")
    return "".join(salida)


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    DESTINO.mkdir(parents=True, exist_ok=True)
    for posicion, (carpeta, titulo, resumen) in enumerate(CAPAS, start=1):
        base = APP / carpeta
        archivos = sorted(base.glob("*.py")) if carpeta else sorted(APP.glob("*.py"))
        archivos = [a for a in archivos if a.name != "__init__.py"]
        cuerpo = "".join(modulo(a) for a in archivos)
        nombre = carpeta or "raiz"
        (DESTINO / f"{nombre}.md").write_text(
            f"---\nsidebar_position: {posicion}\nsidebar_label: {json.dumps(titulo)}\n---\n\n"
            f"# {titulo}\n\n{resumen} Generado de los docstrings de `apps/api/app/{carpeta}`.\n\n{cuerpo}",
            encoding="utf-8",
        )
    (DESTINO / "_category_.json").write_text(
        json.dumps({"label": "Referencia del código (API)", "position": 6}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"{len(CAPAS)} páginas en {DESTINO.relative_to(SITIO.parent)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
