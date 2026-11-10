"""SIM-02: the API reads easily and does the same."""

import ast
import re
import subprocess
import sys
import tomllib
from pathlib import Path

API = Path(__file__).resolve().parents[2]
APP = API / "app"
RULES = "E,F,I,B,UP,SIM,C90,PLR,RET,N,ERA,FBT"
LINE_LIMIT = 40


def _sources() -> list[Path]:
    return [p for p in sorted(APP.rglob("*.py")) if "__pycache__" not in p.parts]


def test_the_api_passes_ruff_with_the_readable_code_rules() -> None:
    """the API passes ruff with the readable code rules @SIM-02-S2 @assumption:SIM-02-ASM-01 @assumption:SIM-02-ASM-02 @assumption:SIM-02-ASM-05"""
    ruff = tomllib.loads((API / "pyproject.toml").read_text(encoding="utf-8"))["tool"]["ruff"]
    lint = ruff["lint"]
    assert set(RULES.split(",")) <= set(lint["select"])
    assert lint["mccabe"]["max-complexity"] == 10
    assert lint["pylint"]["max-args"] == 4
    assert "N818" in lint["ignore"]
    assert set(lint["per-file-ignores"]["app/modules/*/*routes.py"]) >= {"PLR0913", "PLR0917"}

    run = subprocess.run(
        [sys.executable, "-m", "ruff", "check", "app", "--select", RULES, "--no-cache"],
        cwd=API,
        capture_output=True,
        text=True,
        check=False,
    )
    assert run.returncode == 0, run.stdout + run.stderr


def test_no_function_of_the_api_goes_over_40_lines() -> None:
    """no function of the API goes over 40 lines @SIM-02-S2 @assumption:SIM-02-ASM-05"""
    long = []
    for file in _sources():
        for node in ast.walk(ast.parse(file.read_text(encoding="utf-8"))):
            if isinstance(node, ast.FunctionDef | ast.AsyncFunctionDef):
                length = (node.end_lineno or node.lineno) - node.lineno + 1
                if length > LINE_LIMIT:
                    long.append(f"{file.relative_to(API)}:{node.name} {length}")
    assert not long, long


def test_no_dead_code_is_left_nor_rule_values_without_a_name() -> None:
    """no dead code is left nor rule values without a name @SIM-02-S3"""
    problems = []
    for file in _sources():
        tree = ast.parse(file.read_text(encoding="utf-8"))
        named = {
            id(n.value)
            for n in tree.body
            if isinstance(n, ast.Assign | ast.AnnAssign)
            and n.value is not None
            and all(isinstance(t, ast.Name) and t.id.isupper() for t in _targets(n))
        }
        for node in ast.walk(tree):
            if isinstance(node, ast.Attribute) and node.attr == "usuario_id":
                if isinstance(node.value, ast.Attribute) and node.value.attr == "state":
                    problems.append(f"{file.name}: request.state.usuario_id")
            if isinstance(node, ast.Name) and node.id == "reemplaza":
                problems.append(f"{file.name}: reemplaza")
            if isinstance(node, ast.Constant) and node.value in (3600, "23P01"):
                if id(node) not in named:
                    problems.append(f"{file.name}:{node.lineno}: {node.value!r}")
    assert not problems, problems


def _targets(node: ast.Assign | ast.AnnAssign) -> list[ast.expr]:
    return node.targets if isinstance(node, ast.Assign) else [node.target]


def _signatures(source: str) -> dict[str, list[str]]:
    signatures: dict[str, list[str]] = {}

    def walk(body: list[ast.stmt], prefix: str) -> None:
        for node in body:
            if isinstance(node, ast.ClassDef):
                walk(node.body, f"{prefix}{node.name}.")
            elif isinstance(node, ast.FunctionDef | ast.AsyncFunctionDef):
                if node.name.startswith("_") and not node.name.startswith("__"):
                    continue
                a = node.args
                names = [x.arg for x in (*a.posonlyargs, *a.args, *a.kwonlyargs)]
                signatures[f"{prefix}{node.name}"] = names

    walk(ast.parse(source).body, "")
    return signatures


def test_the_public_signatures_of_the_use_cases_and_repositories_are_main_s() -> None:
    """the public signatures of the use cases and repositories of each module are main's @assumption:SIM-02-ASM-03"""
    different = []
    compared = 0
    for file in _sources():
        if file.name == "__init__.py" or file.name.startswith("routes"):
            continue
        path = file.relative_to(API).as_posix()
        in_main = subprocess.run(
            ["git", "show", f"main:./{path}"],
            cwd=API,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
        )
        if in_main.returncode != 0:
            continue
        compared += 1
        before = _signatures(in_main.stdout)
        now = _signatures(file.read_text(encoding="utf-8"))
        for name, parameters in before.items():
            if name in now and now[name] != parameters:
                different.append(f"{path}:{name} {parameters} -> {now.get(name)}")
    # The files renamed to English no longer have a path in main: only those that keep the name are compared, and of them the functions that keep it.
    assert compared > 2
    assert not different, different


def test_the_sql_that_was_repeated_in_bookings_lives_in_a_single_place() -> None:
    """the SQL that was repeated in bookings lives in a single place: the total per hour and the 23P01 overlap @SIM-02-S3"""
    text = "\n".join(
        p.read_text(encoding="utf-8") for p in sorted((APP / "modules" / "bookings").glob("*.py"))
    )
    assert len(re.findall(r"/ 3600", text)) == 1
    assert text.count("3600") == 1
    assert text.count("23P01") == 1


_LOCK = re.compile(r"\bFOR (?:SHARE|NO KEY UPDATE|UPDATE)\b")
_TABLE = re.compile(r"\bFROM\s+(\w+)")
_ORDER = {"app_user": 0, "venue": 1, "space": 2, "booking": 3}


def _locks(repository: Path, method: str) -> list[str]:
    """The tables that `method` locks, in the order its statements run, following
    the calls to functions and methods of the same file and their text constants."""
    tree = ast.parse(repository.read_text(encoding="utf-8"))
    functions: dict[str, ast.FunctionDef] = {}
    constants: dict[str, str] = {}
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            functions[node.name] = node
    for node in tree.body:
        if isinstance(node, ast.Assign) and isinstance(node.value, ast.Constant):
            for t in node.targets:
                if isinstance(t, ast.Name) and isinstance(node.value.value, str):
                    constants[t.id] = node.value.value
    seen: list[str] = []

    def text(node: ast.AST) -> None:
        sql = None
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            sql = node.value
        elif isinstance(node, ast.Name) and node.id in constants:
            sql = constants[node.id]
        if sql and _LOCK.search(sql) and (table := _TABLE.search(sql)):
            seen.append(table.group(1))

    def follow(node: ast.AST, visited: frozenset[str]) -> None:
        text(node)
        if isinstance(node, ast.Call):
            f = node.func
            name = f.attr if isinstance(f, ast.Attribute) else getattr(f, "id", None)
            for child in (node.func, *node.args, *(k.value for k in node.keywords)):
                follow(child, visited)
            if name in functions and name not in visited:
                for statement in functions[name].body:
                    follow(statement, visited | {name})
            return
        for child in ast.iter_child_nodes(node):
            follow(child, visited)

    for statement in functions[method].body:
        follow(statement, frozenset({method}))
    return seen


def test_a_booking_takes_its_locks_in_the_same_order() -> None:
    """a booking takes its locks in the same order @assumption:SIM-02-ASM-04"""
    repository = APP / "modules" / "bookings" / "repository.py"
    assert _locks(repository, "insert") == ["app_user", "venue", "space"]
    assert _locks(repository, "move") == ["venue", "space", "booking"]
    for method in ("insert", "move"):
        ranks = [_ORDER[t] for t in _locks(repository, method)]
        assert ranks == sorted(ranks)
