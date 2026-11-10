import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
README = (ROOT / "README.md").read_text(encoding="utf-8")
SECTIONS = ["What it does", "What it is built with", "How to run it", "Documentation"]
LINKS_THE_TESTS_READ = [
    "apps/api/README.md",
    "apps/mobile/README.md",
    "docs/getting-started.md",
    "docs/technical/architecture.md",
    "docs/technical/runbook.md",
    "specs/asvs.md",
]
COMMANDS_THE_TESTS_READ = ("sh scripts/test.sh", "npm run emulators", "npm run build")
SECRET_PATTERNS = [r"Test1234", r"xkeysib-", r"rnd_", r"contraseña:"]
MAX_LINES = 70
MAX_WHAT_IT_DOES_BULLETS = 6


def _section(title: str) -> str:
    return re.search(rf"^## {title}$(.*?)(?=^## |\Z)", README, flags=re.M | re.S).group(1)


def test_the_readme_fits_in_about_60_lines_with_what_it_is_what_it_does_in_6_bullets_what_it_is_built_with_how_to_run_it_and_the_documentation() -> (  # noqa: E501
    None
):
    """the README fits in about 60 lines with what it is, what it does in 6 bullets, what it is
    built with, how to run it and the documentation @DOC-06-S2"""
    titles = re.findall(r"^## (.+)$", README, flags=re.M)
    bullets = re.findall(r"^- .+$", _section("What it does"), flags=re.M)

    assert len(README.splitlines()) <= MAX_LINES
    for section in SECTIONS:
        assert section in titles, section
    assert 1 <= len(bullets) <= MAX_WHAT_IT_DOES_BULLETS
    assert "docs/technical/integrations.md" in _section("What it is built with")
    for technology in ("Flutter", "FastAPI", "PostgreSQL", "Firebase", "Brevo", "Render"):
        assert technology in README, technology


def test_what_the_documentation_tests_read_from_the_readme_is_still_there() -> None:
    """what the documentation tests read from the README is still there
    @assumption:DOC-06-ASM-01"""
    for link in LINKS_THE_TESTS_READ:
        assert link in README, link
    for command in COMMANDS_THE_TESTS_READ:
        assert command in README, command
    links_to_docs = re.findall(r"\]\((docs/[^)#\s]+\.md)\)", README)
    assert any(
        re.search(r"^- REV-07-ASM-01", (ROOT / e).read_text(encoding="utf-8"), flags=re.M)
        for e in links_to_docs
    )


def test_the_readme_publishes_no_passwords_or_keys() -> None:
    """the README publishes no passwords or keys @assumption:DOC-06-ASM-02"""
    for pattern in SECRET_PATTERNS:
        assert not re.search(pattern, README, flags=re.I), pattern
