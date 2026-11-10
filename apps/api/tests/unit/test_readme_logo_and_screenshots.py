import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
README = (ROOT / "README.md").read_text(encoding="utf-8")
SCREENSHOTS = ROOT / "docs" / "screenshots"
LOGO = "docs/logo.png"
APP_ICON = ROOT / "apps" / "mobile" / "assets" / "icono" / "icono.png"
CHOSEN_SCREENSHOTS = [
    "docs/screenshots/01-login.png",
    "docs/screenshots/03-venues.png",
    "docs/screenshots/05-availability.png",
    "docs/screenshots/07-done.png",
]


def _images() -> list[str]:
    return re.findall(r'src="([^"]+)"', README)


def test_the_readme_opens_with_the_app_logo_above_the_name() -> None:
    """the README opens with the app logo above the name
    @DOC-09-S1 @assumption:DOC-09-ASM-02"""
    assert _images()[0] == LOGO
    assert (ROOT / LOGO).read_bytes() == APP_ICON.read_bytes()
    assert README.index(LOGO) < README.index("ClubNahuelMosse</h1>")
    assert re.search(r'<p align="center">\s*<img src="docs/logo.png"', README)


def test_the_readme_shows_in_one_row_sign_in_venues_availability_and_confirmed_booking() -> None:
    """the README shows in one row sign-in, venues, availability and confirmed booking,
    with no unused screenshots @DOC-09-S2 @assumption:DOC-09-ASM-01"""
    screenshots = [r for r in _images() if r.startswith("docs/screenshots/")]
    rows = re.findall(r'<p align="center">(.*?)</p>', README, flags=re.S)

    assert screenshots == CHOSEN_SCREENSHOTS
    assert len([f for f in rows if "docs/screenshots/" in f]) == 1
    assert {p.name for p in SCREENSHOTS.iterdir()} == {Path(r).name for r in screenshots}
