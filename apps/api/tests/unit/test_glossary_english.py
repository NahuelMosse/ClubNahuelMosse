"""The code glossary translates every current concept into English, once."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
GLOSSARY = ROOT / "docs" / "technical" / "glossary.md"
MODULES = ROOT / "apps" / "api" / "app" / "modules"
CONTRACT = ROOT / "apps" / "api" / "openapi.json"
TABLES = (
    "usuario",
    "sede",
    "espacio",
    "reserva",
    "enlace_recuperacion",
    "correo_saliente",
    "dispositivo",
    "notificacion",
    "notificacion_reserva",
)


def _translations(text: str) -> dict[str, set[str]]:
    """Each `spanish`→`english` pair of the glossary, grouped by the Spanish term."""
    pairs: dict[str, set[str]] = defaultdict(set)
    for source, target in re.findall(r"`([^`]+)`→`([^`]+)`", text):
        pairs[source].add(target)
    return pairs


def _by_section(text: str) -> dict[str, dict[str, set[str]]]:
    """The translations of each section: a term can change depending on whether it is a table, column, role or field."""
    parts = re.split(r"^## (.+)$", text, flags=re.M)
    return {parts[i]: _translations(parts[i + 1]) for i in range(1, len(parts) - 1, 2)}


def _by_line(text: str) -> dict[tuple[str, str], dict[str, set[str]]]:
    """The translations of each section and each `- {table}:` line: a column is translated according to its table."""
    groups: dict[tuple[str, str], dict[str, set[str]]] = {}
    for section, body in _sections(text).items():
        for line in re.split(r"^- ", body, flags=re.M):
            label = line.split(":", 1)[0].strip() if line.strip() else ""
            groups[(section, label)] = _translations(line)
    return groups


def _sections(text: str) -> dict[str, str]:
    parts = re.split(r"^## (.+)$", text, flags=re.M)
    return {parts[i]: parts[i + 1] for i in range(1, len(parts) - 1, 2)}


def test_the_glossary_translates_every_module_table_and_route_once() -> None:
    """the glossary translates every module, table and route of today's API, once @ENG-00-S1"""
    text = GLOSSARY.read_text(encoding="utf-8")
    pairs = _translations(text)

    modules = sorted(p.name for p in MODULES.iterdir() if p.is_dir() and not p.name.startswith("_"))
    for module in modules:
        assert module in text, module
    for table in TABLES:
        assert table in pairs, table
    routes = json.loads(CONTRACT.read_text(encoding="utf-8"))["paths"]
    for route in routes:
        first_segment = route.strip("/").split("/")[0]
        assert first_segment in text, route
    repeated = {
        (group, source): targets
        for group, translations in _by_line(text).items()
        for source, targets in translations.items()
        if len(targets) > 1
    }
    assert repeated == {}


def test_the_glossary_fixes_the_domain_names_and_what_stays_in_spanish() -> None:
    """the glossary fixes booking, venue, space, kind and app_user, leaves in Spanish the test titles and what the user sees @assumption:ENG-00-ASM-01 @assumption:ENG-00-ASM-02 @assumption:ENG-00-ASM-03"""
    text = GLOSSARY.read_text(encoding="utf-8")
    tables = _by_section(text)["Tables, view, functions, triggers"]

    assert tables["reserva"] == {"booking"}
    assert tables["sede"] == {"venue"}
    assert tables["espacio"] == {"space"}
    assert tables["usuario"] == {"app_user"}
    assert "`tipo`→`kind`" in text
    stays = text.split("## What stays in Spanish", 1)[1]
    for topic in (
        "app texts",
        "test titles and files",
        "dni",
        "migrations 0001–0010",
    ):
        assert topic in stays, topic
