"""Production documentation: what whoever operates, audits or maintains the app needs."""

import re
import tomllib
from pathlib import Path

import yaml

from tests.current_schema import current
from tests.unit.test_documentation_model import _sql as _upgrade

ROOT = Path(__file__).resolve().parents[4]
API = ROOT / "apps" / "api"
MOBILE = ROOT / "apps" / "mobile"
DESIGN = ROOT / "docs" / "technical" / "system-design.md"
STATES = {"meets", "fails", "not verified", "not applicable"}
ASVS_ROW = re.compile(r"^\| \*\*(V\d+\.\d+\.\d+)\*\* .*\| *([^|]*?) *\| *([^|]*?) *\|$", re.M)
TYPES = (
    r"bigint|text|integer|boolean|date|timestamptz|time|smallint|numeric|jsonb|integer\[\]|int\[\]"
)


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _section(text: str, title: str) -> str:
    """The body of the `## <title>` section of a markdown, up to the next section."""
    parts = re.split(r"^## ", text, flags=re.M)
    return next((p for p in parts if p.startswith(title)), "")


def _requirements(template: str) -> set[str]:
    return set(
        re.findall(r"\*\*(V\d+\.\d+\.\d+)\*\*", _text(ROOT / ".claude" / "templates" / template))
    )


def test_the_level_2_asvs_matrix_answers_every_requirement() -> None:
    """the level 2 ASVS matrix covers every requirement with its status and evidence @REV-07-S1"""
    matrix = _text(ROOT / "specs" / "asvs.md")
    rows = {m.group(1): (m.group(2).strip("`"), m.group(3)) for m in ASVS_ROW.finditer(matrix)}

    assert re.search(r"\blevel\s*2\b|\bL2\b", matrix, re.I)
    assert set(rows) >= _requirements("asvs-level-1.md") | _requirements("asvs-level-2.md")
    assert {status for status, _ in rows.values()} <= STATES
    assert all(len(evidence) > 3 for _, evidence in rows.values())
    assert sum(status == "meets" for status, _ in rows.values()) >= 20
    assert sum(status == "fails" for status, _ in rows.values()) >= 1


def test_the_system_design_has_threats_dependencies_environments_and_objectives() -> None:
    """the system design describes threats, dependencies, environments and service objectives
    @REV-07-S2
    """
    design = _text(DESIGN)
    dependencies = _section(design, "External dependencies")
    threats = _section(design, "Threat model")

    for external in ("PostgreSQL", "Firebase Authentication", "Firebase Cloud Messaging", "SMTP"):
        assert external in dependencies, external
    for category in ("Spoofing", "Tampering", "Repudiation", "Information disclosure",
                     "Denial of service", "Elevation of privilege"):  # fmt: skip
        assert category in threats, category
    for surface in ("API", "app", "base"):
        assert surface in threats, surface
    assert re.search(r"\blocal\b", _section(design, "Infrastructure"), re.I)
    assert "Render" in _section(design, "Infrastructure")
    assert re.search(r"SLO[^\n]*\d+(?:[.,]\d+)? ?%", design)


def test_the_stack_and_hosting_decisions_are_recorded() -> None:
    """the stack and hosting architecture decisions are recorded @REV-07-S3"""
    records = sorted((ROOT / "docs" / "adr").glob("[0-9][0-9][0-9][0-9]-*.md"))
    texts = [_text(r) for r in records]

    assert len(records) >= 2
    assert all(_section(t, "Status").strip() and "accepted" in _section(t, "Status") for t in texts)
    assert any("FastAPI" in t and "Flutter" in t for t in texts)
    assert any("Render" in t for t in texts)


def _direct_dependencies() -> list[str]:
    project = tomllib.loads(_text(API / "pyproject.toml"))["project"]["dependencies"]
    pubspec = yaml.safe_load(_text(MOBILE / "pubspec.yaml"))["dependencies"]
    python = [re.split(r"[\[<>=~! ;]", d, maxsplit=1)[0] for d in project]
    dart = [name for name, source in pubspec.items() if not isinstance(source, dict)]
    return python + dart


def test_the_cost_of_running_the_app_is_calculated() -> None:
    """the cost of running the app is calculated @REV-07-S5"""
    costs = _text(ROOT / "docs" / "technical" / "infra-cost.md")

    assert _section(costs, "Volume assumptions").strip()
    assert "Render" in costs
    assert re.search(r"USD ?[1-9]", costs)
    assert "render.com/pricing" in costs


def test_the_runbook_says_how_to_roll_back_rotate_secrets_and_handle_incidents() -> None:
    """the runbook says how to roll back, rotate secrets and handle an incident @REV-07-S6"""
    runbook = _text(ROOT / "docs" / "technical" / "runbook.md")

    for title in ("Deploy", "Roll back", "Incidents", "Secret rotation and revocation"):
        section = _section(runbook, title)
        assert len(section.split()) > 30, title
        assert "TODO" not in section, title
    assert "render.yaml" in runbook
    for secret in ("FIREBASE_CREDENTIALS_JSON", "SMTP_PASSWORD"):
        assert secret in _section(runbook, "Secret rotation and revocation"), secret


def test_the_accessibility_statement_and_the_per_screen_register_are_published() -> None:
    """the accessibility statement and the per-screen register are published @REV-07-S7"""
    statement = _text(ROOT / "docs" / "business" / "accessibility.md")
    screens = sorted(p.stem for p in (MOBILE / "lib").rglob("pantalla_*.dart"))
    term = re.compile(r"Supports|Partially Supports|Does Not Support|Not Applicable")

    assert term.search(_section(statement, "Conformance status"))
    without_register = [
        p
        for p in screens
        if not any(re.search(rf"\b{p}\b", f) and term.search(f) for f in statement.splitlines())
    ]
    assert without_register == []


def _columns_by_table() -> dict[str, set[str]]:
    migrations = "".join(_text(m) for m in sorted((API / "migrations" / "versions").glob("*.py")))
    tables: dict[str, set[str]] = {}
    for table, body in re.findall(r"CREATE TABLE (\w+) \((.*?)\n\s*\)", migrations, re.S):
        tables[table] = set(re.findall(rf"^\s*(\w+) (?:{TYPES})\b", body, re.M))
    for table, column in re.findall(
        rf"ALTER TABLE (\w+)\s+ADD COLUMN (\w+) (?:{TYPES})", migrations
    ):
        tables.setdefault(table, set()).add(column)
    for migration in sorted((API / "migrations" / "versions").glob("*.py")):
        for table, old, new in re.findall(
            r"ALTER TABLE (\w+) RENAME COLUMN (\w+) TO (\w+)", _upgrade(migration)
        ):
            tables.setdefault(table, set()).discard(old)
            tables[table].add(new)
    return current(tables)


def test_the_performance_and_capacity_budget_is_written() -> None:
    """the performance and capacity budget is written @REV-07-S9"""
    design = _text(DESIGN)

    assert re.search(r"p95[^\n]*\d+ ?ms", design)
    assert re.search(r"capacity[^\n]*\d+", design, re.I)


def _registered_ids() -> set[str]:
    texts = "".join(_text(a) for a in (ROOT / "specs").rglob("*.md"))
    return set(re.findall(r"\b[A-Z]+-[\d.]+[a-z]?-(?:SUP|ASM)-\d+\b", texts))


def test_whoever_operates_the_app_finds_the_assumptions_in_the_readmes() -> None:
    """whoever operates the app finds the assumptions that limit it in the READMEs @REV-07-S10"""
    root = _text(ROOT / "README.md")
    api = _text(API / "README.md")
    mobile = _text(MOBILE / "README.md")
    assumption = re.compile(r"^- ([A-Z]+-[\d.]+[a-z]?-(?:SUP|ASM)-\d+)", re.M)
    listed = assumption.findall(api) + assumption.findall(mobile)

    assert "apps/api/README.md" in root
    assert "apps/mobile/README.md" in root
    assert len(assumption.findall(api)) >= 5
    assert len(assumption.findall(mobile)) >= 3
    assert set(listed) <= _registered_ids()
    for idea in ("4 hours", "7 days", "payments", "admin", "catalog"):
        assert idea in api + mobile, idea


def test_the_mpl_lgpl_and_ofl_licenses_have_their_exception_or_their_text() -> None:
    """the MPL, LGPL and OFL licenses have their exception or their text @REV-07-S11"""
    ofl = _text(MOBILE / "assets" / "fuentes" / "OFL.txt")

    assert sorted((MOBILE / "assets" / "fuentes").glob("Inter-*.ttf"))
    assert "SIL OPEN FONT LICENSE VERSION 1.1" in ofl.upper()
    assert re.search(r"Copyright .*Inter", ofl)
