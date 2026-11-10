"""The navigation page says in which files the app's routes and redirect live."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
NAVIGATION = ROOT / "docs" / "technical" / "app-navigation.md"
ROUTES = "apps/mobile/lib/router.dart"
REDIRECT = "apps/mobile/lib/redirect.dart"


def test_the_navigation_page_names_routes_and_redirect() -> None:
    """the navigation page names «rutas.dart» and «redireccion.dart», where the routes and the redirect live @SIM-04-S1"""
    page = NAVIGATION.read_text(encoding="utf-8")

    assert (ROOT / ROUTES).exists() and (ROOT / REDIRECT).exists()
    assert f"`{ROUTES}`" in page
    assert f"`{REDIRECT}`" in page
    assert "all routes are in `apps/mobile/lib/app.dart`" not in page
