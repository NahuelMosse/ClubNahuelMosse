from pathlib import Path

APP = Path(__file__).resolve().parents[2] / "app"


def test_health_does_not_import_the_database() -> None:
    """the API health does not import the infrastructure @INT-01-S2"""
    text = (APP / "health.py").read_text(encoding="utf-8")

    assert "app.modules" not in text
    assert "app.shared.db" not in text
