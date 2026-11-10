"""The glossary covers every code name of main at 9b83c86 and does not merge two terms into one name."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
GLOSSARY = ROOT / "docs" / "technical" / "glossary.md"
# The starting point of the move to English: what the glossary has to cover.
BASE = "9b83c86"
# Names that are already English or are not translated.
UNTRANSLATED = {
    "ctx",
    "detail",
    "input",
    "loc",
    "msg",
    "type",
    "dni",
    "id",
    "token",
    "total",
    "cancelable",
    "q",
    "firebase_uid",
    "admin",
    "api",
    "health",
}
SQL_TYPES = r"(?:bigint|bigserial|uuid|text|integer|smallint|boolean|date|time|timestamptz)"
# Each column change of a migration, in order: definition in CREATE TABLE (a line with `:=` is a function
# variable), ADD, DROP or RENAME.
COLUMN_CHANGE = re.compile(
    rf"^\s+(?P<defined>[a-z_]+) {SQL_TYPES}\b(?!.*:=)"
    r"|ADD COLUMN (?:IF NOT EXISTS )?(?P<added>\w+)"
    r"|DROP COLUMN (?:IF EXISTS )?(?P<dropped>\w+)"
    r"|RENAME COLUMN (?P<old>\w+) TO (?P<new>\w+)",
    re.M,
)


def _git(*arguments: str) -> str:
    return subprocess.run(
        ["git", *arguments], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", check=True
    ).stdout


def _folders(path: str) -> set[str]:
    return {
        n
        for n in _git("ls-tree", "--name-only", f"{BASE}:{path}").split()
        if not n.startswith("_") and "." not in n
    }


def _contract_names() -> set[str]:
    contract = json.loads(_git("show", f"{BASE}:apps/api/openapi.json"))
    names = {r.strip("/").split("/")[0] for r in contract["paths"]}
    for schema in contract["components"]["schemas"].values():
        names |= set(schema.get("properties", {}))
    for route in contract["paths"].values():
        for operation in route.values():
            names |= {p["name"] for p in operation.get("parameters", [])}
    return names


def _columns() -> set[str]:
    """The columns that exist after applying main's migrations, in order."""
    folder = "apps/api/migraciones/versions"
    columns: set[str] = set()
    for file in sorted(
        n for n in _git("ls-tree", "--name-only", f"{BASE}:{folder}").split() if n.endswith(".py")
    ):
        # Without `downgrade` or its `_*_abajo` helpers: what they do does not reach main's database.
        upgrade = re.sub(
            r"^def \w*(?:abajo|downgrade)\w*\(.*?(?=^def |\Z)",
            "",
            _git("show", f"{BASE}:{folder}/{file}"),
            flags=re.M | re.S,
        )
        for change in COLUMN_CHANGE.finditer(upgrade):
            columns |= {change["defined"] or change["added"] or change["new"]} - {None}
            columns -= {change["dropped"] or change["old"]}
    return columns


def _groups(text: str) -> dict[tuple[str, str], list[tuple[str, str]]]:
    """The `spanish`→`english` pairs of each section and each line: a column is translated according to its table."""
    groups: dict[tuple[str, str], list[tuple[str, str]]] = {}
    parts = re.split(r"^## (.+)$", text, flags=re.M)
    for i in range(1, len(parts) - 1, 2):
        for line in re.split(r"^- ", parts[i + 1], flags=re.M):
            label = line.split(":", 1)[0].strip()
            groups[(parts[i], label)] = re.findall(r"`([^`]+)`→`([^`]+)`", line)
    return groups


def test_the_glossary_covers_every_name_of_main_at_9b83c86() -> None:
    """the glossary names every API module, app folder, column, JSON field, parameter and route of main at 9b83c86 @ENG-00-S2"""
    text = GLOSSARY.read_text(encoding="utf-8")
    names = (
        _folders("apps/api/app/modules")
        | _folders("apps/mobile/lib")
        | _contract_names()
        | _columns()
    )

    # A route segment counts when quoted as `/segment`.
    assert (
        sorted(n for n in names - UNTRANSLATED if f"`{n}`" not in text and f"`/{n}" not in text)
        == []
    )


def test_the_glossary_does_not_merge_two_terms_into_one_name() -> None:
    """within each glossary line, no term has two translations and no two terms share a translation @ENG-00-S2"""
    doubles = []
    for group, pairs in _groups(GLOSSARY.read_text(encoding="utf-8")).items():
        by_source: dict[str, set[str]] = defaultdict(set)
        by_target: dict[str, set[str]] = defaultdict(set)
        for source, target in pairs:
            by_source[source].add(target)
            # `creado_en` and `creada_en` are the same word in another gender: merging them into `created_at` is intended.
            by_target[target].add(re.sub(r"[ao](?=_|$)", "", source))
        doubles += [(group, s, t) for s, t in by_source.items() if len(t) > 1]
        doubles += [(group, s, t) for t, s in by_target.items() if len(s) > 1]

    assert doubles == []
