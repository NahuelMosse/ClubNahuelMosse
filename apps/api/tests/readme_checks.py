"""What the README tests share: the commands and headings of a README, and the app README check."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "apps" / "mobile"


def commands(readme: str) -> list[str]:
    blocks = re.findall(r"```[a-z]*\n(.*?)```", readme, re.S)
    return [line.strip() for b in blocks for line in b.splitlines() if line.strip()]


def headings(readme: str) -> str:
    return " ".join(re.findall(r"^#+ (.+)$", readme, re.M)).lower()


def assert_scripts_exist(readme: str) -> None:
    for command in commands(readme):
        for script in re.findall(r"scripts/[\w.]+", command):
            assert (ROOT / script).is_file(), command


def assert_app_readme_covers_setup_and_run(config_file: Path) -> None:
    readme = (APP / "README.md").read_text(encoding="utf-8")
    config = config_file.read_text(encoding="utf-8")
    defined = set(re.findall(r"String\.fromEnvironment\(\s*'([A-Z_]+)'", config))

    for section in ("configure", "run", "test"):
        assert section in headings(readme), section
    assert {"API_URL", "AUTH_EMULATOR", "FIREBASE_API_KEY"} <= defined
    assert not {v for v in defined if v not in readme}, "undocumented variables"
    assert_scripts_exist(readme)
    assert "flutter pub get" in readme
    assert "flutter run" in readme
    assert "flutter build apk" in readme
