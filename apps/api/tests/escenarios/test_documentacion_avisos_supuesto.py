"""Avisos de terceros: cubren cada dependencia de producción que el script lee."""

import importlib.util
from pathlib import Path
from types import ModuleType

RAIZ = Path(__file__).resolve().parents[4]
AVISOS = RAIZ / "THIRD_PARTY_NOTICES.md"


def _script() -> ModuleType:
    ruta = RAIZ / "scripts" / "avisos_de_terceros.py"
    spec = importlib.util.spec_from_file_location("avisos_de_terceros", ruta)
    assert spec is not None and spec.loader is not None
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


def _faltantes(texto: str, python: set[str], dart: set[str], modulo: ModuleType) -> list[str]:
    en_python = {f[0] for f in modulo._filas_de(texto, "Python")}
    en_dart = {f[0] for f in modulo._filas_de(texto, "Dart")}
    return [f"python {n}" for n in sorted(python - en_python)] + [
        f"dart {n}" for n in sorted(dart - en_dart)
    ]


def test_los_avisos_de_terceros_nombran_cada_dependencia_de_produccion() -> None:
    """los avisos de terceros nombran cada dependencia de producción, directa y transitiva @REV-07-S4 @assumption:REV-07-ASM-07"""
    modulo = _script()
    texto = AVISOS.read_text(encoding="utf-8").replace("\r\n", "\n")
    python = {f[0] for f in modulo.filas_python()}
    dart_lock = modulo.paquetes_dart()
    dart = {p[0] for p in dart_lock}

    assert {"fastapi", "starlette", "pydantic-core"} <= python
    assert any(p[3] == "direct main" for p in dart_lock)
    assert any(p[3] == "transitive" for p in dart_lock)
    assert not any(p[3] == "direct dev" for p in dart_lock)
    assert _faltantes(texto, python, dart, modulo) == []

    sin_python = texto.replace(
        next(ln for ln in texto.splitlines() if ln.startswith("| starlette |")) + "\n", ""
    )
    transitivo = next(p[0] for p in dart_lock if p[3] == "transitive")
    sin_dart = texto.replace(
        next(ln for ln in texto.splitlines() if ln.startswith(f"| {transitivo} |")) + "\n", ""
    )
    assert _faltantes(sin_python, python, dart, modulo) == ["python starlette"]
    assert _faltantes(sin_dart, python, dart, modulo) == [f"dart {transitivo}"]
