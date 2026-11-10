import ast
import re
import tomllib
from pathlib import Path

API = Path(__file__).resolve().parents[2]
APP = API / "app"
MODULES = APP / "modules"
SHARED = APP / "shared"
ROOT = API.parents[1]

# Each data-access file writes only the tables that are its own.
OWN_TABLES = {
    "users/repository.py": {"app_user"},
    "bookings/repository.py": {"booking"},
    "venues/repository.py": {"venue"},
    "notifications/repository.py": {"notification", "notification_booking", "device"},
    "spaces/repository.py": {"space"},
    "password_recovery/repository.py": {"recovery_link"},
    "shared/email.py": {"outgoing_email"},
}
WRITE = re.compile(
    r"(?:INSERT\s+INTO|(?<!FOR\s)(?<!DO\s)UPDATE|DELETE\s+FROM)\s+(\w+)", re.IGNORECASE
)
ZONE_LITERAL = "America/Argentina/Buenos_Aires"


def _modules(file: Path) -> set[str]:
    tree = ast.parse(file.read_text(encoding="utf-8"))
    names: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            names.update(a.name for a in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module and node.level == 0:
            names.add(node.module)
    return names


def _texts(file: Path) -> list[str]:
    tree = ast.parse(file.read_text(encoding="utf-8"))
    return [
        n.value for n in ast.walk(tree) if isinstance(n, ast.Constant) and isinstance(n.value, str)
    ]


def _sources(folder: Path) -> list[Path]:
    return [a for a in folder.rglob("*.py") if "__pycache__" not in a.parts]


def _name(file: Path) -> str:
    return file.relative_to(APP).as_posix().removeprefix("modules/")


def test_no_feature_imports_the_repository_of_another() -> None:
    """a feature's repository is imported only by itself: the others ask for it through its index
    @REV-06-S1 @assumption:REV-06-ASM-01"""
    files = _sources(MODULES)
    assert files
    for file in files:
        own = file.relative_to(MODULES).parts[0]
        for name in _modules(file):
            parts = name.split(".")
            if (
                parts[:2] == ["app", "modules"]
                and len(parts) > 3
                and parts[3] in {"repositorio", "repository"}
            ):
                assert parts[2] == own, f"{_name(file)} imports {name}"


def test_shared_does_not_import_features_or_routes() -> None:
    """shared code does not import features @REV-06-S1 @assumption:REV-06-ASM-01"""
    files = _sources(SHARED)
    assert files
    for file in files:
        for name in _modules(file):
            assert not name.startswith(("app.modules", "app.main")), f"{file.name} imports {name}"


def test_each_repository_writes_only_its_table() -> None:
    """each repository writes only its table @REV-06-S6 @assumption:REV-06-ASM-05"""
    files = [*_sources(SHARED), *_sources(MODULES)]
    assert files
    for file in files:
        own = OWN_TABLES.get(_name(file), set())
        for text in _texts(file):
            for table in WRITE.findall(text):
                assert table.lower() in own, f"{_name(file)} writes the table {table}"


def test_no_type_suppression_is_left() -> None:
    """no type suppression is left in the API or in its tests @REV-06-S7 @assumption:REV-06-ASM-06"""
    needle = "type" + ": ignore"
    for folder in (APP, API / "tests"):
        for file in _sources(folder):
            assert needle not in file.read_text(encoding="utf-8"), f"{file.name} has it"


def test_strict_mypy_covers_app_and_tests() -> None:
    """strict mypy covers app and tests @REV-06-S8"""
    mypy = tomllib.loads((API / "pyproject.toml").read_text(encoding="utf-8"))["tool"]["mypy"]
    assert mypy["strict"] is True
    assert set(mypy["files"]) >= {"app", "tests"}


def test_the_club_timezone_is_defined_once_in_the_api() -> None:
    """the club timezone is defined once in the API @REV-06-S10 @assumption:REV-06-ASM-07"""
    with_zone = sorted(
        a.relative_to(APP).as_posix()
        for a in _sources(APP)
        if any(ZONE_LITERAL in t for t in _texts(a))
    )
    assert with_zone == ["shared/club_timezone.py"]


def test_the_my_bookings_and_cancel_routes_go_through_the_use_cases() -> None:
    """the my-bookings and cancel routes go through the use cases @REV-06-S11 @assumption:REV-06-ASM-09"""
    tree = ast.parse((MODULES / "bookings" / "routes.py").read_text(encoding="utf-8"))
    imported = {
        a.name
        for n in ast.walk(tree)
        if isinstance(n, ast.ImportFrom) and n.module == "app.modules.bookings.use_cases"
        for a in n.names
    }
    assert {"my_bookings", "cancel_booking"} <= imported


def test_each_card_has_its_section_of_changes_to_existing_behavior() -> None:
    """each card.md has its section of changes to existing behavior @REV-06-S12 @assumption:REV-06-ASM-10"""
    cards = sorted((ROOT / "specs").glob("*/card.md"))
    assert cards
    for card in cards:
        lines = card.read_text(encoding="utf-8").splitlines()
        assert "## Changes to existing behavior" in lines, f"{card.parent.name} lacks it"
