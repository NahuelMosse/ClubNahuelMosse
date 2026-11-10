import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DOC = ROOT / "docs" / "technical" / "integrations.md"
SERVICES = [
    "Firebase Authentication",
    "Firebase Cloud Messaging",
    "Brevo",
    "PostgreSQL on Render",
    "Render",
    "Monitor that keeps the API awake",
]
CODE = ("apps/api/app", "apps/mobile/lib", "apps/mobile/android")
OTHERS = ("render.yaml", "firebase.json", "package.json", "apps/mobile/definiciones.example.json")
VARIABLE_NAME = re.compile(r"^[A-Z][A-Z0-9_]{3,}$")
SECRET_SHAPES = [
    r"xkeysib-",
    r"rnd_",
    r"postgres(ql)?(\+\w+)?://[^\s:/`]+:[^\s@`]+@",
    r'"private_key"',
]


def _sections() -> dict[str, str]:
    text = DOC.read_text(encoding="utf-8")
    parts = re.split(r"^## ", text, flags=re.M)[1:]
    return {p.split("\n", 1)[0].strip(): p for p in parts}


def _quotes(text: str) -> list[str]:
    return re.findall(r"`([^`\n]+)`", text)


def _corpus() -> str:
    files = [ROOT / o for o in OTHERS]
    for folder in CODE:
        files += [f for f in (ROOT / folder).rglob("*") if f.suffix in {".py", ".dart", ".xml"}]
    return "\n".join(f.read_text(encoding="utf-8", errors="ignore") for f in files)


def test_integrations_md_has_one_section_per_service_with_what_it_is_used_for() -> None:
    """integrations.md has one section per service with what it is used for
    @DOC-03-S1 @assumption:DOC-03-ASM-02"""
    sections = _sections()
    for service in SERVICES:
        assert service in sections, service
        assert "**What it is used for.**" in sections[service], service
    for neighbor in ("architecture.md", "system-design.md"):
        page = ROOT / "docs" / "technical" / neighbor
        assert "integrations.md" in page.read_text(encoding="utf-8")


def test_each_section_names_its_files_and_its_variables() -> None:
    """each section names its files and its variables @DOC-03-S2 @assumption:DOC-03-ASM-04"""
    for service, body in _sections().items():
        if service not in SERVICES:
            continue
        assert "**Files.**" in body, service
        assert "**Variables.**" in body, service
        files = body.split("**Files.**", 1)[1].split("**Variables.**", 1)[0]
        assert any("/" in c or "." in c for c in _quotes(files)), service


def test_every_file_and_variable_cited_by_integrations_md_exists_in_the_repo() -> None:
    """every file and variable cited by integrations.md exists in the repo
    @assumption:DOC-03-ASM-01"""
    corpus = _corpus()
    for quote in _quotes(DOC.read_text(encoding="utf-8")):
        if VARIABLE_NAME.match(quote):
            assert quote in corpus, f"missing variable: {quote}"
        elif "/" in quote and not quote.startswith(("/", "http")) and " " not in quote:
            assert (ROOT / quote).exists(), f"missing file: {quote}"


def test_integrations_md_has_no_keys_service_accounts_or_urls_with_a_password() -> None:
    """integrations.md has no keys, service accounts or URLs with a password
    @assumption:DOC-03-ASM-03"""
    text = DOC.read_text(encoding="utf-8")
    for shape in SECRET_SHAPES:
        assert not re.search(shape, text), shape
