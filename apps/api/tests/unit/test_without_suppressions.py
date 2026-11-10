import ast
import io
import tokenize
from pathlib import Path

API = Path(__file__).resolve().parents[2]


def _comments(file: Path) -> list[str]:
    source = file.read_text(encoding="utf-8")
    return [
        t.string
        for t in tokenize.generate_tokens(io.StringIO(source).readline)
        if t.type == tokenize.COMMENT
    ]


def test_no_type_suppression_is_left() -> None:
    """no comment suppresses types in the API or in its tests @REV-06-S7 @assumption:REV-06-ASM-06"""
    needle = "type" + ":"
    for folder in (API / "app", API / "tests"):
        for file in folder.rglob("*.py"):
            if "__pycache__" in file.parts:
                continue
            ast.parse(file.read_text(encoding="utf-8"))
            for comment in _comments(file):
                assert not comment.lstrip("# ").startswith(needle + " ignore"), (
                    f"{file.name}: {comment}"
                )
