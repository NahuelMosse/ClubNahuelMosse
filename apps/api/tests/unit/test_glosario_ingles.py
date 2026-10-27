"""El glosario del código traduce cada concepto de hoy al inglés, una sola vez."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import json
import re
from collections import defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
GLOSARIO = RAIZ / "docs" / "technical" / "glosario-ingles.md"
MODULOS = RAIZ / "apps" / "api" / "app" / "modules"
CONTRATO = RAIZ / "apps" / "api" / "openapi.json"
TABLAS = (
    "usuario",
    "sede",
    "espacio",
    "reserva",
    "enlace_recuperacion",
    "correo_saliente",
    "dispositivo",
    "notificacion",
    "notificacion_reserva",
)


def _traducciones(texto: str) -> dict[str, set[str]]:
    """Cada `castellano`→`inglés` del glosario, agrupado por el término castellano."""
    pares: dict[str, set[str]] = defaultdict(set)
    for origen, destino in re.findall(r"`([^`]+)`→`([^`]+)`", texto):
        pares[origen].add(destino)
    return pares


def _por_seccion(texto: str) -> dict[str, dict[str, set[str]]]:
    """Las traducciones de cada sección: un término puede cambiar según sea tabla, columna, rol o campo."""
    partes = re.split(r"^## (.+)$", texto, flags=re.M)
    return {partes[i]: _traducciones(partes[i + 1]) for i in range(1, len(partes) - 1, 2)}


def _por_renglon(texto: str) -> dict[tuple[str, str], dict[str, set[str]]]:
    """Las traducciones de cada sección y cada renglón `- <tabla>:`: una columna se traduce según su tabla."""
    grupos: dict[tuple[str, str], dict[str, set[str]]] = {}
    for seccion, cuerpo in _secciones(texto).items():
        for renglon in re.split(r"^- ", cuerpo, flags=re.M):
            etiqueta = renglon.split(":", 1)[0].strip() if renglon.strip() else ""
            grupos[(seccion, etiqueta)] = _traducciones(renglon)
    return grupos


def _secciones(texto: str) -> dict[str, str]:
    partes = re.split(r"^## (.+)$", texto, flags=re.M)
    return {partes[i]: partes[i + 1] for i in range(1, len(partes) - 1, 2)}


def test_el_glosario_traduce_cada_modulo_tabla_y_ruta_una_sola_vez() -> None:
    """el glosario traduce cada módulo, tabla y ruta de la API de hoy, una sola vez @ENG-00-S1"""
    texto = GLOSARIO.read_text(encoding="utf-8")
    pares = _traducciones(texto)

    modulos = sorted(p.name for p in MODULOS.iterdir() if p.is_dir() and not p.name.startswith("_"))
    for modulo in modulos:
        assert modulo in texto, modulo
    for tabla in TABLAS:
        assert tabla in pares, tabla
    rutas = json.loads(CONTRATO.read_text(encoding="utf-8"))["paths"]
    for ruta in rutas:
        primer_tramo = ruta.strip("/").split("/")[0]
        assert primer_tramo in texto, ruta
    repetidos = {
        (grupo, origen): destinos
        for grupo, traducciones in _por_renglon(texto).items()
        for origen, destinos in traducciones.items()
        if len(destinos) > 1
    }
    assert repetidos == {}


def test_el_glosario_fija_los_nombres_del_dominio_y_lo_que_queda_en_castellano() -> None:
    """el glosario fija booking, venue, space, kind y app_user, deja en castellano los títulos de test y lo que ve el usuario @assumption:ENG-00-ASM-01 @assumption:ENG-00-ASM-02 @assumption:ENG-00-ASM-03"""
    texto = GLOSARIO.read_text(encoding="utf-8")
    tablas = _por_seccion(texto)["Tablas, vista, funciones, disparadores"]

    assert tablas["reserva"] == {"booking"}
    assert tablas["sede"] == {"venue"}
    assert tablas["espacio"] == {"space"}
    assert tablas["usuario"] == {"app_user"}
    assert "`tipo`→`kind`" in texto
    queda = texto.split("## Queda en castellano", 1)[1]
    for tema in (
        "texto que ve el usuario",
        "títulos y archivos de test",
        "dni",
        "migraciones 0001–0010",
    ):
        assert tema in queda, tema
