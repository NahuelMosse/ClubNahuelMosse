from pathlib import Path

INTERFAZ = Path(__file__).resolve().parents[2] / "app" / "interfaz"


def test_salud_no_importa_infraestructura() -> None:
    """la salud de la API no importa la infraestructura @INT-01-S2"""
    texto = (INTERFAZ / "salud.py").read_text(encoding="utf-8")

    assert "app.infraestructura" not in texto
