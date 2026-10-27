from pathlib import Path

APP = Path(__file__).resolve().parents[2] / "app"


def test_salud_no_importa_la_base_de_datos() -> None:
    """la salud de la API no importa la infraestructura @INT-01-S2"""
    texto = (APP / "salud.py").read_text(encoding="utf-8")

    assert "app.modules" not in texto
    assert "app.shared.db" not in texto
