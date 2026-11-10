"""The API's spaces and availability modules are in English."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
import ast
import json
from pathlib import Path

import pytest

from tests.unit.test_api_in_english_contract_current import operations_differing_in
from tests.unit.test_base_in_english import (
    COMMON_WORDS,
    _defined_names,
    _prose_texts,
    _spanish,
    _words,
)

API_ROOT = Path(__file__).resolve().parents[2]
MODULES = API_ROOT / "app" / "modules"

NEW_FILES = [
    MODULES / "spaces" / n
    for n in ("__init__.py", "use_cases.py", "rules.py", "repository.py", "routes.py")
] + [
    MODULES / "availability" / n
    for n in ("__init__.py", "use_cases.py", "slots.py", "rules.py", "repository.py", "routes.py")
]
OLD_FOLDERS = [MODULES / "espacios", MODULES / "horarios"]

# Domain words that are Spanish today and that the glossary does not list as a standalone word.
EXTRA_SPANISH = {
    "agenda", "franja", "franjas", "grilla", "disponibilidad", "horarios", "espacios",
    "tipo", "tipos", "clave", "deporte", "deportes", "apertura", "cierre", "dias",
    "altura", "calle", "sede", "espacio", "rango", "libres", "ocupadas", "alta", "baja",
    "catalogo", "sugerencia", "sugerido", "pedido", "cambio", "lista", "errores",
}  # fmt: skip

# The fields of the Pydantic classes are JSON keys: they stay in Spanish (ASM-05).
PYDANTIC_BASE = {"BaseModel"}


def test_the_spaces_and_availability_modules_are_named_as_the_glossary_says() -> None:
    """the spaces and availability modules are named as the glossary says @ENG-03-S1 @assumption:ENG-03-ASM-02 @assumption:ENG-03-ASM-03"""
    missing = [str(p.relative_to(MODULES)) for p in NEW_FILES if not p.exists()]
    left_over = [str(p.relative_to(MODULES)) for p in OLD_FOLDERS if p.exists()]
    imports = [
        str(p.relative_to(API_ROOT))
        for folder in (API_ROOT / "app", API_ROOT / "tests", API_ROOT / "scripts")
        for p in folder.rglob("*")
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

    assert not missing, missing
    assert not left_over, left_over
    assert not imports, imports


def _pydantic_fields(tree: ast.AST) -> set[str]:
    fields: set[str] = set()
    for node in ast.walk(tree):
        bases = {b.id for b in getattr(node, "bases", []) if isinstance(b, ast.Name)}
        if isinstance(node, ast.ClassDef) and bases & PYDANTIC_BASE:
            fields |= {
                s.target.id
                for s in node.body
                if isinstance(s, ast.AnnAssign) and isinstance(s.target, ast.Name)
            }
    return fields


def test_the_names_comments_and_docstrings_of_spaces_and_availability_are_in_english() -> None:
    """the names, comments and docstrings of spaces and availability are in English @ENG-03-S2 @assumption:ENG-03-ASM-04 @assumption:ENG-03-ASM-05"""
    spanish = _spanish() | EXTRA_SPANISH
    problems: list[str] = []
    for path in NEW_FILES:
        if not path.exists():
            problems.append(f"{path.name}: does not exist")
            continue
        source = path.read_text(encoding="utf-8")
        tree = ast.parse(source)
        own = _pydantic_fields(tree)
        for name in sorted(_defined_names(tree) - own):
            if spanish & set(_words(name)):
                problems.append(f"{path.parent.name}/{path.name}: name {name}")
        for text in _prose_texts(source, tree):
            if COMMON_WORDS.search(text):
                problems.append(
                    f"{path.parent.name}/{path.name}: {text.strip().splitlines()[0][:60]}"
                )

    assert not problems, problems


def test_the_spaces_and_availability_contract_has_the_same_as_main(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the spaces and availability contract has the same routes, methods, codes, fields and operationId as main @ENG-03-S3 @assumption:ENG-03-ASM-01 @assumption:ENG-03-ASM-07 @assumption:ENG-03-ASM-09"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    from app.main import create_app

    contract = create_app().openapi()
    published = (API_ROOT / "openapi.json").read_text(encoding="utf-8")

    assert operations_differing_in("/spaces") == []
    assert json.dumps(contract, indent=2, ensure_ascii=False) + "\n" == published
