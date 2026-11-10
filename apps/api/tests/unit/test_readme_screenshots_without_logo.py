import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
README = (ROOT / "README.md").read_text(encoding="utf-8")
SCREENSHOTS = ROOT / "docs" / "screenshots"
MAX_SCREENSHOTS = 4


def test_the_readme_shows_at_most_4_screenshots_in_one_row_not_counting_the_logo() -> None:
    """the README shows at most 4 screenshots in one row and no screenshots are left unused,
    not counting the logo @DOC-06-S1"""
    paths = [r for r in re.findall(r'src="([^"]+)"', README) if r.startswith("docs/screenshots/")]
    rows = re.findall(r"<p align=\"center\">(.*?)</p>", README, flags=re.S)

    assert 1 <= len(paths) <= MAX_SCREENSHOTS
    assert len([f for f in rows if "docs/screenshots/" in f]) == 1
    for path in paths:
        assert (ROOT / path).is_file(), path
    assert README.index("docs/screenshots/") < README.index("## What it does")
    assert not {p.name for p in SCREENSHOTS.iterdir()} - {Path(r).name for r in paths}
