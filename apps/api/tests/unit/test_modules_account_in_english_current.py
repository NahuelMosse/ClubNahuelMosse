"""The account modules in English on today's main: the recovery email already lives in `notifications`."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
import ast
from pathlib import Path

from tests.unit import test_modules_account_in_english as previous
from tests.unit.test_api_in_english_contract_current import operations_differing_in
from tests.unit.test_base_in_english import COMMON_WORDS, _spanish, _words

FILES = {module: [a for a in files if a != "email"] for module, files in previous.FILES.items()}
NEW_FILES = [previous.MODULES / m / f"{a}.py" for m, files in FILES.items() for a in files]


def test_the_venues_users_session_and_recovery_modules_are_named_as_the_glossary_says() -> None:
    """the venues, users, session and recovery modules are named as the glossary says @ENG-02-S1 @assumption:ENG-02-ASM-02 @assumption:ENG-02-ASM-03"""
    missing = [str(p.relative_to(previous.APP)) for p in NEW_FILES if not p.exists()]
    left_over = [v for v in previous.OLD_NAMES if (previous.MODULES / v).exists()]
    imports = [
        str(p.relative_to(previous.API_ROOT))
        for folder in (
            previous.APP,
            previous.API_ROOT / "tests",
            previous.API_ROOT / "migrations",
        )
        for p in folder.rglob("*.py")
        if p.resolve() != Path(previous.__file__).resolve()
        and ".venv" not in p.parts
        and previous.OLD_IMPORT.search(p.read_text(encoding="utf-8"))
    ]

    assert not missing, missing
    assert not left_over, left_over
    assert not imports, imports


def test_the_names_comments_and_docstrings_of_those_modules_are_in_english() -> None:
    """the names, comments and docstrings of those modules are in English @ENG-02-S2 @assumption:ENG-02-ASM-04"""
    spanish = _spanish() | {"sede", "sedes", "usuario", "usuarios", "sesion", "recuperacion"}
    problems: list[str] = []
    for path in NEW_FILES:
        if not path.exists():
            problems.append(f"{path.name}: does not exist")
            continue
        source = path.read_text(encoding="utf-8")
        tree = ast.parse(source)
        exempt = previous._route_params(source) | previous._model_fields(tree)
        for name in sorted(previous._defined_names(tree) - exempt):
            if spanish & set(_words(name)):
                problems.append(f"{path.parent.name}/{path.name}: name {name}")
        for text in previous._prose(source, tree):
            if COMMON_WORDS.search(text):
                problems.append(
                    f"{path.parent.name}/{path.name}: {text.strip().splitlines()[0][:60]}"
                )

    assert not problems, problems


def test_the_contract_has_the_same_routes_methods_codes_fields_and_operation_id_as_main() -> None:
    """the contract has the same routes, methods, codes, fields and operationId as main @ENG-02-S3 @assumption:ENG-02-ASM-01"""
    assert (
        operations_differing_in("/register", "/me", "/password-recovery", "/link", "/venues") == []
    )
