"""Production documentation: what each assumption of the REV-07 card demands of the documents."""

import re
import subprocess
from pathlib import Path

from tests.scenarios.test_documentation_current import (
    _requirements,
    _section,
    _text,
)

ROOT = Path(__file__).resolve().parents[4]
API = ROOT / "apps" / "api"
MOBILE = ROOT / "apps" / "mobile"
DESIGN = ROOT / "docs" / "technical" / "system-design.md"
ASVS = ROOT / "specs" / "asvs.md"
COSTS = ROOT / "docs" / "technical" / "infra-cost.md"
RUNBOOK = ROOT / "docs" / "technical" / "runbook.md"
ACCESSIBILITY = ROOT / "docs" / "business" / "accessibility.md"
ASVS_ROW = re.compile(r"^\| \*\*(V\d+\.\d+\.\d+)\*\* .*\| *([^|]*?) *\| *([^|]*?) *\|$", re.M)
TYPES = (
    r"bigint|text|integer|boolean|date|timestamptz|time|smallint|numeric|jsonb|integer\[\]|int\[\]"
)
DOCUMENTS = (
    ASVS,
    DESIGN,
    ROOT / "docs" / "adr" / "0001-stack.md",
    ROOT / "docs" / "adr" / "0002-hosting-on-render.md",
    COSTS,
    RUNBOOK,
    ACCESSIBILITY,
    ROOT / "README.md",
    API / "README.md",
    MOBILE / "README.md",
)


def _registered_ids() -> set[str]:
    texts = "".join(_text(a) for a in (ROOT / "specs").rglob("*.md"))
    return set(re.findall(r"\b[A-Z]+-[\d.]+[a-z]?-(?:SUP|ASM)-\d+\b", texts))


def _assumptions(text: str) -> list[str]:
    return re.findall(r"^- ([A-Z]+-[\d.]+[a-z]?-(?:SUP|ASM)-\d+)", text, re.M)


def test_the_system_design_says_what_is_missing_today_and_writes_it_as_an_unmeasured_goal() -> None:
    """the system design says what is missing today and writes it as an unmeasured goal
    @REV-07-S2 @assumption:REV-07-ASM-01
    """
    design = _text(DESIGN)

    assert re.search(r"unmeasured", _section(design, "Performance and capacity budget"))
    assert re.search(r"no automatic backups|no backups", design, re.I)
    assert re.search(r"SLO[^\n]*(unmeasured|target|objective)", design, re.I)


def test_the_system_design_covers_the_six_stride_categories() -> None:
    """the system design covers the six STRIDE categories
    @REV-07-S2 @assumption:REV-07-ASM-09
    """
    threats = _section(_text(DESIGN), "Threat model")
    categories = ("Spoofing", "Tampering", "Repudiation", "Information disclosure",
                  "Denial of service", "Elevation of privilege")  # fmt: skip

    for category in categories:
        rows = [f for f in threats.splitlines() if f.startswith("| T-") and category in f]
        assert rows, category
        assert all(re.search(r"mitigate|eliminate|transfer|accept", f) for f in rows), category


def test_the_system_design_brings_the_personal_data_inventory() -> None:
    """the system design brings the personal data inventory
    @REV-07-S2 @assumption:REV-07-ASM-15
    """
    personal = _section(_text(DESIGN), "Personal data")

    for item in ("national ID", "email", "birth date", "device token"):
        assert item in personal, item
    for column in ("Retention", "How it is deleted", "Legal basis"):
        assert column in personal, column


def test_each_adr_compares_two_or_more_alternatives() -> None:
    """each ADR compares two or more alternatives @REV-07-S3 @assumption:REV-07-ASM-15"""
    records = sorted((ROOT / "docs" / "adr").glob("[0-9][0-9][0-9][0-9]-*.md"))

    assert records
    for record in records:
        assert len(re.findall(r"^### Alternative \w", _text(record), re.M)) >= 2, record.name
        assert _section(_text(record), "Decision and why").strip(), record.name


def test_the_production_grade_documents_exist_even_if_the_docs_module_is_off() -> None:
    """the production grade documents exist even if the docs module is off
    @REV-07-S1 @assumption:REV-07-ASM-04
    """
    for document in DOCUMENTS:
        assert document.is_file(), document
        assert len(_text(document).split()) > 100, document


def test_the_documents_say_they_describe_the_kit_3_branch() -> None:
    """the documents say they describe the kit-3 branch @REV-07-S1 @assumption:REV-07-ASM-05"""
    for document in (ASVS, DESIGN, RUNBOOK, COSTS, ACCESSIBILITY):
        assert "kit-3" in _text(document), document


def test_the_failing_asvs_rows_stay_fails_with_their_finding_and_their_card() -> None:
    """the failing ASVS rows stay fails with their finding and their card, and V15.1.1 stays fails
    until a person decides @REV-07-S1 @assumption:REV-07-ASM-06
    """
    rows = {m.group(1): m.group(0) for m in ASVS_ROW.finditer(_text(ASVS))}
    failing = [f for f in rows.values() if "| `fails` |" in f]

    assert failing
    for row in failing:
        assert re.search(r"hallazgo \d+|sin card|no figura en la revisión", row), row[:60]
        assert re.search(r"REV-0\d|sin card|persona", row), row[:60]
    assert "| `fails` |" in rows["V15.1.1"]
    assert "persona" in rows["V15.1.1"]


def test_each_evidence_path_of_the_asvs_matrix_exists_in_the_repo() -> None:
    """each evidence path of the ASVS matrix exists in the repo
    @REV-07-S1 @assumption:REV-07-ASM-11
    """
    tracked = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout.splitlines()
    paths = set()
    for row in ASVS_ROW.finditer(_text(ASVS)):
        paths |= set(
            re.findall(r"`([\w.\-]+(?:/[\w.\-]+)+\.[a-z]{2,5})(?::[\d,:\-]+)?`", row.group(3))
        )

    assert paths
    missing = [r for r in sorted(paths) if not any(v == r or v.endswith("/" + r) for v in tracked)]
    assert missing == []


def test_the_asvs_matrix_declares_the_chosen_level_2() -> None:
    """the ASVS matrix declares the chosen level 2 @REV-07-S1 @assumption:REV-07-ASM-15"""
    header = _text(ASVS)[:2500]

    assert "nivel 2" in header
    assert "elige" in header


def test_the_matrix_is_asvs_5_with_the_253_requirements_of_levels_1_and_2() -> None:
    """the matrix is ASVS 5.0 with the 253 requirements of levels 1 and 2, like V15.1.1
    @REV-07-S1 @assumption:REV-07-ASM-16
    """
    expected = _requirements("asvs-level-1.md") | _requirements("asvs-level-2.md")
    rows = {m.group(1) for m in ASVS_ROW.finditer(_text(ASVS))}

    assert "ASVS 5.0" in _text(ASVS)[:200]
    assert len(expected) == 253
    assert rows == expected
    assert "V15.1.1" in rows


def test_the_prices_cite_the_render_page_and_that_it_does_not_say_if_the_free_database_has_backups() -> (
    None
):
    """the prices cite https://render.com/pricing.md consulted on 2026-10-20 and that it does not say
    whether the free database has backups @REV-07-S5 @assumption:REV-07-ASM-08
    """
    costs = _text(COSTS)

    assert "https://render.com/pricing.md" in costs
    assert "2026-10-20" in costs
    assert "does not say whether the free database has backups" in costs


def test_the_accessibility_register_names_each_screen_with_reader_browser_and_result() -> None:
    """the accessibility register names each screen with reader, browser and result, or it could not
    be run @REV-07-S7 @assumption:REV-07-ASM-12
    """
    register = _section(_text(ACCESSIBILITY), "Per-screen register").splitlines()
    screens = sorted(p.stem for p in (MOBILE / "lib").rglob("*_screen.dart"))

    assert screens
    for screen in screens:
        row = next((f for f in register if f"`{screen}`" in f), "")
        assert row, screen
        assert re.search(r"Supports|Does Not Support|Not Applicable", row), screen
        assert re.search(r"TalkBack", row), screen
        assert re.search(r"not verified|no se pudo correr|capturas", row), screen


def test_no_document_carries_secrets_connection_strings_with_password_tokens_or_emails() -> None:
    """no document carries secrets, connection strings with password, tokens or personal
    emails @REV-07-S6 @assumption:REV-07-ASM-14
    """
    patterns = {
        "connection with password": r"\b[\w+]+://[^\s:/@<`]+:[^\s@/<`]+@",
        "API key": r"AIza[0-9A-Za-z_\-]{30,}",
        "token": r"\beyJ[0-9A-Za-z_\-]{20,}\.[0-9A-Za-z_\-]{10,}",
        "private key": r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
        "GitHub token": r"\bgh[pousr]_[0-9A-Za-z]{30,}",
        "personal email": r"[\w.+-]+@(?:gmail|hotmail|outlook|yahoo|live)\.\w+",
    }

    for document in DOCUMENTS:
        for name, pattern in patterns.items():
            assert not re.search(pattern, _text(document)), (document.name, name)


def test_the_runbook_names_each_secret_without_its_value() -> None:
    """the runbook names each secret without its value @REV-07-S6 @assumption:REV-07-ASM-14"""
    rotation = _section(_text(RUNBOOK), "Secret rotation and revocation")
    inventory = _section(_text(DESIGN), "Secrets inventory")
    secrets = re.findall(r"^\| `([A-Z][A-Z_]+)`", inventory, re.M)

    assert {"DATABASE_URL", "FIREBASE_CREDENTIALS_JSON", "SMTP_PASSWORD"} <= set(secrets)
    for secret in ("DATABASE_URL", "FIREBASE_CREDENTIALS_JSON", "SMTP_PASSWORD",
                   "ADMIN_PASSWORD"):  # fmt: skip
        assert f"`{secret}`" in rotation, secret
        assert not re.search(rf"{secret}`?\s*=\s*\S{{6,}}", rotation), secret


def test_the_readmes_list_with_their_id_the_assumptions_that_change_what_is_seen_or_operated() -> (
    None
):
    """the READMEs list with their ID the assumptions that change what is seen or operated, not all 545
    @REV-07-S10 @assumption:REV-07-ASM-02
    """
    api = _assumptions(_text(API / "README.md"))
    mobile = _assumptions(_text(MOBILE / "README.md"))

    assert 5 <= len(api) <= 60
    assert 3 <= len(mobile) <= 60
    assert set(api + mobile) <= _registered_ids()
    assert len(api) == len(set(api))
    assert len(mobile) == len(set(mobile))


def test_the_readmes_list_the_assumptions_of_1_to_4_h_and_7_days_admin_does_not_book_catalog_and_payments() -> (
    None
):
    """the READMEs list the assumptions of 1 to 4 h and up to 7 days ahead, the admin does not
    book, fixed catalog and no payments @REV-07-S10 @assumption:REV-07-ASM-17
    """
    api = _text(API / "README.md")
    mobile = _text(MOBILE / "README.md")

    assert re.search(r"1 to 4 hours", api)
    assert re.search(r"up to 7 days ahead", api)
    assert "the admin does not book" in api
    assert "the admin does not book" in mobile
    assert re.search(r"catalog[^\n]*fixed", api)
    assert re.search(r"catalog[^\n]*fixed", mobile)
    assert re.search(r"no payments", mobile)
