"""La documentación del modelo y de la navegación, con los analizadores corregidos."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import re
from pathlib import Path

from tests.unit.test_documentacion_del_modelo import (
    APP_DART,
    MIGRACIONES,
    MODELO,
    NAVEGACION,
    NO_COLUMNA,
    _diagrama_er,
    _entidades,
    _partes,
    _rutas_documentadas,
    _secciones,
    _subir,
    _texto,
)


def _sql(migracion: Path) -> str:
    """El `upgrade()` con las cadenas contiguas de Python unidas en una sola."""
    return re.sub(r'"\s*\n\s*"', "", _subir(migracion))


def _palabras_de_las_migraciones() -> set[str]:
    """Todo nombre que aparece en las migraciones, también los de las constantes de módulo."""
    return set(re.findall(r"[a-z_][a-z_0-9]*", "\n".join(_texto(m) for m in MIGRACIONES)))


def _tablas() -> dict[str, set[str]]:
    """Las columnas de cada tabla tal como las dejan las migraciones aplicadas en orden."""
    tablas: dict[str, set[str]] = {}
    for migracion in MIGRACIONES:
        sql = _sql(migracion)
        for nombre, cuerpo in re.findall(r"CREATE TABLE (\w+) \((.*?)\n\s*\)", sql, re.S):
            sin_comentarios = re.sub(r"--[^\n]*", "", cuerpo)
            primeras = (p.split()[0].lower() for p in _partes(sin_comentarios) if p.strip())
            tablas[nombre] = {c for c in primeras if c not in NO_COLUMNA}
        for tabla, cambios in re.findall(
            r"ALTER TABLE (\w+)\s+((?:ADD|DROP) COLUMN.*?)\"", sql, re.S
        ):
            for accion, columna in re.findall(
                r"(ADD|DROP) COLUMN (?:IF (?:NOT )?EXISTS )?(\w+)", cambios
            ):
                (tablas[tabla].add if accion == "ADD" else tablas[tabla].discard)(columna)
    return tablas


def _rutas_de_app_dart() -> set[str]:
    """Cada ruta de GoRouter con su camino completo, anidando por la sangría."""
    pila: list[tuple[int, str]] = []
    rutas = set()
    for linea in _texto(APP_DART).splitlines():
        coincide = re.match(r"^(\s+)path: '([^']*)',", linea)
        if not coincide:
            continue
        sangria = len(coincide.group(1))
        while pila and pila[-1][0] >= sangria:
            pila.pop()
        padre = pila[-1][1].rstrip("/") if pila else ""
        ruta = (
            coincide.group(2)
            if coincide.group(2).startswith("/")
            else f"{padre}/{coincide.group(2)}"
        )
        pila.append((sangria, ruta))
        rutas.add(ruta)
    return rutas


def test_cada_tabla_y_columna_que_nombra_la_pagina_del_modelo_de_datos_existe_en_las_migraciones() -> (
    None
):
    """cada tabla y columna que nombra la página del modelo de datos existe en las migraciones @DOC-01-S1"""
    tablas = _tablas()
    texto = _texto(MODELO)
    conocidas = _palabras_de_las_migraciones()

    assert len(tablas) == 9
    diagrama = _diagrama_er(texto)
    assert diagrama.keys() <= tablas.keys()
    for tabla, columnas in diagrama.items():
        assert columnas <= tablas[tabla], (tabla, columnas - tablas[tabla])
    for tabla, cuerpo in _entidades().items():
        assert tabla in tablas, tabla
        for nombre in re.findall(r"`([a-z_][a-z_0-9]*)`", cuerpo):
            assert nombre in conocidas, (tabla, nombre)
    for nombre in re.findall(r"`([a-z_][a-z_0-9]*)`", texto):
        assert nombre in conocidas, nombre


def test_los_estados_de_reserva_y_de_aviso_de_la_pagina_son_los_que_admiten_las_migraciones_todos() -> (
    None
):
    """los estados de reserva y de aviso de la página son los que admiten las migraciones, todos @DOC-01-S1"""
    sql = "\n".join(_sql(m) for m in MIGRACIONES)
    por_estado = re.search(r"estado IN \(([^)]*)\)", sql)
    assert por_estado is not None
    reserva = set(re.findall(r"'(\w+)'", por_estado.group(1)))
    envio = set(re.findall(r"'(\w+)'", re.findall(r"envio IN\s*\(([^)]*)\)", sql)[-1]))
    estados = _secciones(_texto(MODELO), "##")["Estados"]
    por_diagrama = _secciones(estados, "###")

    def en_diagrama(titulo: str) -> set[str]:
        bloque = por_diagrama[titulo].split("```mermaid", 1)[1].split("```", 1)[0]
        return set(re.findall(r"(?:\[\*\]|\w+) --> (\w+)", bloque))

    assert reserva == {"activa", "cancelada", "anulada"}
    assert envio >= {"pendiente", "enviando", "enviada", "fallida", "sin_permiso", "sin_canal"}
    assert en_diagrama("reserva") == reserva | {"completada"}
    assert en_diagrama("notificacion.envio") == envio


def test_cada_ruta_que_nombra_la_pagina_de_navegacion_existe_en_app_dart() -> None:
    """cada ruta que nombra la página de navegación existe en app.dart @DOC-01-S2"""
    reales = _rutas_de_app_dart()
    texto = _texto(NAVEGACION)

    assert _rutas_documentadas() <= reales, _rutas_documentadas() - reales
    for ruta in re.findall(r'\["(/[^"\s?]*)', texto.split("```mermaid", 1)[1].split("```", 1)[0]):
        assert any(r.startswith(ruta.rstrip("/")) or ruta.startswith(r) for r in reales), ruta


def test_la_pagina_de_navegacion_lista_cada_ruta_de_app_dart() -> None:
    """la página de navegación lista cada ruta de app.dart @DOC-01-S2"""
    reales = _rutas_de_app_dart()

    assert len(reales) >= 30
    assert reales <= _rutas_documentadas(), reales - _rutas_documentadas()
