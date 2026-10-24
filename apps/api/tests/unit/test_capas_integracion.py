from pathlib import Path

INTERFAZ = Path(__file__).resolve().parents[2] / "app" / "interfaz"


def _codigo(nombre: str) -> str:
    return (INTERFAZ / nombre).read_text(encoding="utf-8")


def test_salud_y_metricas_no_importan_infraestructura() -> None:
    """la salud y las métricas de la API no importan la infraestructura @INT-01-S2"""
    for nombre in ("salud.py", "metricas.py"):
        assert "app.infraestructura" not in _codigo(nombre), nombre


def test_registro_de_errores_y_metricas_no_suprimen_tipos() -> None:
    """el registro de errores y las métricas no suprimen tipos @INT-01-S2"""
    aguja = "type" + ":" + " ignore"
    for nombre in ("registro_errores.py", "metricas.py"):
        assert aguja not in _codigo(nombre), nombre
