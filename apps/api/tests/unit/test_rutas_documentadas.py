"""La página de navegación dice en qué archivos viven las rutas y la redirección de la app."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
NAVEGACION = RAIZ / "docs" / "technical" / "navegacion-de-la-app.md"
RUTAS = "apps/mobile/lib/rutas.dart"
REDIRECCION = "apps/mobile/lib/redireccion.dart"


def test_la_pagina_de_navegacion_nombra_rutas_y_redireccion() -> None:
    """la página de navegación nombra rutas.dart y redireccion.dart, donde viven las rutas y la redirección @SIM-04-S1"""
    pagina = NAVEGACION.read_text(encoding="utf-8")

    assert (RAIZ / RUTAS).exists() and (RAIZ / REDIRECCION).exists()
    assert f"`{RUTAS}`" in pagina
    assert f"`{REDIRECCION}`" in pagina
    assert "todas las rutas están en `apps/mobile/lib/app.dart`" not in pagina
