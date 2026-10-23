import ast
import io
import tokenize
from pathlib import Path

API = Path(__file__).resolve().parents[2]


def _comentarios(archivo: Path) -> list[str]:
    fuente = archivo.read_text(encoding="utf-8")
    return [
        t.string
        for t in tokenize.generate_tokens(io.StringIO(fuente).readline)
        if t.type == tokenize.COMMENT
    ]


def test_no_queda_una_supresion_de_tipos() -> None:
    """ningún comentario suprime tipos en la API ni en sus tests @REV-06-S7 @assumption:REV-06-ASM-06"""
    aguja = "type" + ":"
    for carpeta in (API / "app", API / "tests"):
        for archivo in carpeta.rglob("*.py"):
            if "__pycache__" in archivo.parts:
                continue
            ast.parse(archivo.read_text(encoding="utf-8"))
            for comentario in _comentarios(archivo):
                assert not comentario.lstrip("# ").startswith(aguja + " ignore"), (
                    f"{archivo.name}: {comentario}"
                )
