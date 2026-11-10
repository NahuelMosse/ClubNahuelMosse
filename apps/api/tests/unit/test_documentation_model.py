"""The data model and navigation documentation says what is in the code."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import ast
import re
from pathlib import Path

from tests.current_schema import current, names, value

ROOT = Path(__file__).resolve().parents[4]
MIGRATIONS = sorted((ROOT / "apps" / "api" / "migrations" / "versions").glob("0*.py"))
APP_DART = ROOT / "apps" / "mobile" / "lib" / "router.dart"
MODEL = ROOT / "docs" / "technical" / "data-model.md"
NAVIGATION = ROOT / "docs" / "technical" / "app-navigation.md"
DESIGN = ROOT / "docs" / "technical" / "system-design.md"
COPY = ROOT / "docs-site" / "scripts" / "copy-docs.mjs"
NOT_COLUMN = {"constraint", "check", "primary", "unique", "exclude", "foreign"}


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _sql(migration: Path) -> str:
    """The body of `upgrade()` and of the module functions it calls, with the contiguous Python
    strings joined into one."""
    source = _text(migration)
    functions = {
        n.name: ast.get_source_segment(source, n) or ""
        for n in ast.parse(source).body
        if isinstance(n, ast.FunctionDef)
    }
    upgrade = functions.get("upgrade", "")
    calls = re.findall(r"\b(_\w+)\(\)", upgrade)
    body = "\n".join([upgrade, *(functions.get(name, "") for name in calls)])
    return re.sub(r'"\s*\n\s*"', "", body)


def _split(body: str) -> list[str]:
    """Splits `body` at the commas that are not inside parentheses."""
    parts, depth, current_part = [], 0, ""
    for char in body:
        depth += char == "("
        depth -= char == ")"
        if char == "," and depth == 0:
            parts.append(current_part)
            current_part = ""
        else:
            current_part += char
    return [*parts, current_part]


def _tables() -> dict[str, set[str]]:
    """The columns of each table as the migrations applied in order leave them."""
    tables: dict[str, set[str]] = {}
    for migration in MIGRATIONS:
        sql = _sql(migration)
        for name, body in re.findall(r"CREATE TABLE (\w+) \((.*?)\n\s*\)", sql, re.S):
            without_comments = re.sub(r"--[^\n]*", "", body)
            firsts = (p.split()[0].lower() for p in _split(without_comments) if p.strip())
            tables[name] = {c for c in firsts if c not in NOT_COLUMN}
        for table, changes in re.findall(
            r"ALTER TABLE (\w+)\s+((?:ADD|DROP) COLUMN.*?)\"", sql, re.S
        ):
            for action, column in re.findall(
                r"(ADD|DROP) COLUMN (?:IF (?:NOT )?EXISTS )?(\w+)", changes
            ):
                (tables[table].add if action == "ADD" else tables[table].discard)(column)
        for table, old, new in re.findall(r"ALTER TABLE (\w+) RENAME COLUMN (\w+) TO (\w+)", sql):
            tables[table].discard(old)
            tables[table].add(new)
    # 0010 adds the audit with a loop over the tables (`f"ALTER TABLE {table} …"`), which
    # this text reader does not resolve; that all nine have it is checked against the database by
    # tests/integration/test_uuid_and_audit.py.
    for columns in tables.values():
        columns |= {"creado_en", "modificado_en"}
    return current(tables)


def _words_of_the_migrations() -> set[str]:
    """Every name that appears in the migrations, also those of the module constants."""
    written = set(re.findall(r"[a-z_][a-z_0-9]*", "\n".join(_text(m) for m in MIGRATIONS)))
    modules = {c.name for c in (ROOT / "apps" / "api" / "app" / "modules").iterdir() if c.is_dir()}
    return written | names() | modules


def _sections(text: str, level: str) -> dict[str, str]:
    """The bodies of the headings of that level (`##`, `###`), by title."""
    parts = re.split(rf"^{level} (.+)$", text, flags=re.M)
    return {parts[i].strip(): parts[i + 1] for i in range(1, len(parts) - 1, 2)}


def _entities() -> dict[str, str]:
    model = _text(MODEL)
    return _sections(_sections(model, "##")["Entities"], "###")


def _er_diagram(text: str) -> dict[str, set[str]]:
    block = text.split("```mermaid", 1)[1].split("```", 1)[0]
    columns = {}
    for table, body in re.findall(r"^\s+(\w+) \{\n(.*?)\n\s+\}", block, re.S | re.M):
        columns[table] = {line.split()[1] for line in body.splitlines() if line.strip()}
    return columns


def test_each_table_and_column_the_data_model_page_names_exists_in_the_migrations() -> None:
    """each table and column the data model page names exists in the migrations @DOC-01-S1"""
    tables = _tables()
    text = _text(MODEL)
    known = _words_of_the_migrations()

    assert len(tables) == 9
    diagram = _er_diagram(text)
    assert diagram.keys() <= tables.keys()
    for table, columns in diagram.items():
        assert columns <= tables[table], (table, columns - tables[table])
    for table, body in _entities().items():
        assert table in tables, table
        for name in re.findall(r"`([a-z_][a-z_0-9]*)`", body):
            assert name in known, (table, name)
    for name in re.findall(r"`([a-z_][a-z_0-9]*)`", text):
        assert name in known, name


def test_the_data_model_page_explains_each_table_of_the_migrations() -> None:
    """the data model page explains each table of the migrations @DOC-01-S1"""
    tables = _tables()
    entities = _entities()
    text = _text(MODEL)

    assert entities.keys() == tables.keys()
    assert "booking_with_status" in text
    assert "erDiagram" in text and set(_er_diagram(text)) == set(tables)
    for table, columns in tables.items():
        body = entities[table]
        assert len(body.split()) > 15, table
        assert "firebase_uid" in body or table != "app_user"
        named = set(re.findall(r"`([a-z_][a-z_0-9]*)`", body))
        assert columns - {"id", "created_at", "updated_at"} <= named, (
            table,
            sorted(columns - named),
        )


def test_the_booking_and_notice_states_of_the_page_are_all_those_the_migrations_admit() -> None:
    """the booking and notice states of the page are all those the migrations admit @DOC-01-S1"""
    sql = "\n".join(_sql(m) for m in MIGRATIONS)
    by_state = re.search(r"estado IN \(([^)]*)\)", sql)
    assert by_state is not None
    booking = {value(v) for v in re.findall(r"'(\w+)'", by_state.group(1))}
    delivery = {
        value(v) for v in re.findall(r"'(\w+)'", re.findall(r"envio IN\s*\(([^)]*)\)", sql)[-1])
    }
    states = _sections(_text(MODEL), "##")["States"]
    by_diagram = _sections(states, "###")

    def in_diagram(title: str) -> set[str]:
        block = by_diagram[title].split("```mermaid", 1)[1].split("```", 1)[0]
        return set(re.findall(r"(?:\[\*\]|\w+) --> (\w+)", block))

    assert booking == {"active", "canceled", "voided"}
    assert delivery >= {"pending", "sending", "sent", "failed", "no_permission", "no_channel"}
    assert in_diagram("booking") == booking | {"completed"}
    assert in_diagram("notification.delivery") == delivery


def test_the_data_section_of_system_design_refers_to_the_data_model_page_without_repeating_its_columns() -> (
    None
):
    """the Data section of system-design refers to the data model page without repeating its columns @DOC-01-S3 @assumption:DOC-01-ASM-01"""
    data = _sections(_text(DESIGN), "##")["Data"]

    assert "data-model.md" in data
    assert "firebase_uid" not in data
    assert "|" not in data
    assert len(data.split()) < 120


def _app_dart_routes() -> set[str]:
    """Each GoRouter route with its full path, nesting by indentation. A route that a separate
    method builds (`GoRoute _x() => GoRoute(`) hangs from the route where `_x(),` is called."""
    stack: list[tuple[int, str]] = []
    routes = set()
    method_parents: dict[str, str] = {}
    for line in _text(APP_DART).splitlines():
        method = re.match(r"^\s*(GoRoute|List<RouteBase>) (_\w+)\(\) =>", line)
        if method:
            stack = [(-1, method_parents[method.group(2)])] if method.group(1) == "GoRoute" else []
            continue
        call = re.match(r"^(\s+)(_\w+)\(\),$", line)
        if call:
            while stack and stack[-1][0] >= len(call.group(1)):
                stack.pop()
            method_parents[call.group(2)] = stack[-1][1] if stack else ""
            continue
        matches = re.match(r"^(\s+)path: '([^']*)',", line)
        if not matches:
            continue
        indent = len(matches.group(1))
        while stack and stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1].rstrip("/") if stack else ""
        route = (
            matches.group(2) if matches.group(2).startswith("/") else f"{parent}/{matches.group(2)}"
        )
        stack.append((indent, route))
        routes.add(route)
    return routes


def _documented_routes() -> set[str]:
    table = _sections(_text(NAVIGATION), "##")["Routes"]
    rows = re.findall(r"^\| `([^`]+)` \|", table, re.M)
    return {row.split("?")[0] for row in rows}


def test_each_route_the_navigation_page_names_exists_in_app_dart() -> None:
    """each route the navigation page names exists in app.dart @DOC-01-S2"""
    real = _app_dart_routes()
    text = _text(NAVIGATION)

    assert _documented_routes() <= real, _documented_routes() - real
    for route in re.findall(r'\["(/[^"\s?]*)', text.split("```mermaid", 1)[1].split("```", 1)[0]):
        assert any(r.startswith(route.rstrip("/")) or route.startswith(r) for r in real), route


def test_the_navigation_page_lists_each_route_of_app_dart() -> None:
    """the navigation page lists each route of app.dart @DOC-01-S2"""
    real = _app_dart_routes()

    assert len(real) >= 30
    assert real <= _documented_routes(), real - _documented_routes()


def test_the_documentation_site_includes_the_data_model_and_the_navigation_under_technical() -> (
    None
):
    """the documentation site includes the data model and the navigation under Technical @DOC-01-S3"""
    copy = _text(COPY)
    pages = re.findall(r"\['([^']+)', '(technical/[^']+)', (\d+)\]", copy)
    by_source = {source: (target, int(pos)) for source, target, pos in pages}

    assert by_source["docs/technical/data-model.md"] == ("technical/data-model.md", 2)
    assert by_source["docs/technical/app-navigation.md"] == (
        "technical/app-navigation.md",
        3,
    )
    positions = [pos for _, pos in by_source.values()]
    assert sorted(positions) == list(range(1, len(positions) + 1))
    assert (ROOT / "docs" / "technical" / "data-model.md").exists() or "existsSync" in copy
    assert "existsSync(join(repo, source))" in copy
