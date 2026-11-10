import ast
import re
from pathlib import Path

API = Path(__file__).resolve().parents[2]
ROOT = API.parents[1]
MODULES = API / "app" / "modules"
SHARED = API / "app" / "shared"


def _method(file: str, name: str) -> str:
    tree = ast.parse((MODULES / file).read_text(encoding="utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name == name:
            return ast.unparse(node)
    raise AssertionError(f"{file} has no {name}")


def _code(files: list[Path]) -> dict[str, str]:
    return {a.parent.name + "/" + a.name: a.read_text(encoding="utf-8") for a in files}


def test_the_code_map_is_still_up_to_date() -> None:
    """the code map is still up to date @ARQ-02-S3"""
    code_map = (ROOT / "docs" / "technical" / "code-map.md").read_text(encoding="utf-8")

    assert "`http_errors.py`" in code_map


def test_a_venue_schedule_is_built_in_a_single_function_and_with_the_days_in_a_tuple() -> None:
    """a venue schedule is built in a single function and with the days in a tuple
    @ARQ-02-S2 @assumption:ARQ-02-ASM-06"""
    code = _code([a for a in MODULES.rglob("*.py") if "__pycache__" not in a.parts])
    built = {n: len(re.findall(r"\bOpeningHours\(", t)) for n, t in code.items()}

    assert sum(built.values()) == 1
    (file,) = [n for n, c in built.items() if c]
    assert re.search(r"OpeningHours\([^)]*tuple\(", code[file], flags=re.DOTALL)


def test_the_repositories_commit_with_in_transaction() -> None:
    """the repositories commit with in_transaction and the methods that run inside another
    do not use it @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    db = (SHARED / "db.py").read_text(encoding="utf-8")
    assert "def in_transaction(" in db
    using = [
        a.parent.name
        for a in [*MODULES.glob("*/repositorio.py"), *MODULES.glob("*/repository.py")]
        if "in_transaction(" in a.read_text(encoding="utf-8")
    ]
    assert len(using) >= 6

    for file, method in [
        ("bookings/repository.py", "cancel_future_of"),
        ("spaces/repository.py", "deactivate_venue_spaces"),
        ("notifications/repository.py", "enqueue_user_cancellation"),
    ]:
        body = _method(file, method)
        assert "in_transaction" not in body, method
        assert ".commit()" not in body, method


def test_the_bookings_are_built_with_row_mapping() -> None:
    """the bookings are built with row._mapping @ARQ-02-S1 @assumption:ARQ-02-ASM-06"""
    bookings = (MODULES / "bookings" / "repository.py").read_text(encoding="utf-8")

    assert "Booking(**" in bookings
    assert "._mapping" in bookings
