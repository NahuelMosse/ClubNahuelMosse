"""La documentación del modelo de datos y de la navegación dice lo que hay en el código."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import ast
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
MIGRACIONES = sorted((RAIZ / "apps" / "api" / "migraciones" / "versions").glob("0*.py"))
APP_DART = RAIZ / "apps" / "mobile" / "lib" / "rutas.dart"
MODELO = RAIZ / "docs" / "technical" / "modelo-de-datos.md"
NAVEGACION = RAIZ / "docs" / "technical" / "navegacion-de-la-app.md"
DISENO = RAIZ / "docs" / "technical" / "system-design.md"
COPIAR = RAIZ / "sitio-docs" / "scripts" / "copiar.mjs"
NO_COLUMNA = {"constraint", "check", "primary", "unique", "exclude", "foreign"}


def _texto(ruta: Path) -> str:
    return ruta.read_text(encoding="utf-8")


def _sql(migracion: Path) -> str:
    """El cuerpo de `upgrade()` y de las funciones del módulo que llama, con las cadenas contiguas
    de Python unidas en una sola."""
    fuente = _texto(migracion)
    funciones = {
        n.name: ast.get_source_segment(fuente, n) or ""
        for n in ast.parse(fuente).body
        if isinstance(n, ast.FunctionDef)
    }
    subir = funciones.get("upgrade", "")
    llamadas = re.findall(r"\b(_\w+)\(\)", subir)
    cuerpo = "\n".join([subir, *(funciones.get(nombre, "") for nombre in llamadas)])
    return re.sub(r'"\s*\n\s*"', "", cuerpo)


def _partes(cuerpo: str) -> list[str]:
    """Parte `cuerpo` por las comas que no están dentro de paréntesis."""
    partes, profundidad, actual = [], 0, ""
    for caracter in cuerpo:
        profundidad += caracter == "("
        profundidad -= caracter == ")"
        if caracter == "," and profundidad == 0:
            partes.append(actual)
            actual = ""
        else:
            actual += caracter
    return [*partes, actual]


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
        for tabla, vieja, nueva in re.findall(
            r"ALTER TABLE (\w+) RENAME COLUMN (\w+) TO (\w+)", sql
        ):
            tablas[tabla].discard(vieja)
            tablas[tabla].add(nueva)
    return tablas


def _palabras_de_las_migraciones() -> set[str]:
    """Todo nombre que aparece en las migraciones, también los de las constantes de módulo."""
    return set(re.findall(r"[a-z_][a-z_0-9]*", "\n".join(_texto(m) for m in MIGRACIONES)))


def _secciones(texto: str, nivel: str) -> dict[str, str]:
    """Los cuerpos de los encabezados de ese nivel (`##`, `###`), por título."""
    partes = re.split(rf"^{nivel} (.+)$", texto, flags=re.M)
    return {partes[i].strip(): partes[i + 1] for i in range(1, len(partes) - 1, 2)}


def _entidades() -> dict[str, str]:
    modelo = _texto(MODELO)
    return _secciones(_secciones(modelo, "##")["Entidades"], "###")


def _diagrama_er(texto: str) -> dict[str, set[str]]:
    bloque = texto.split("```mermaid", 1)[1].split("```", 1)[0]
    columnas = {}
    for tabla, cuerpo in re.findall(r"^\s+(\w+) \{\n(.*?)\n\s+\}", bloque, re.S | re.M):
        columnas[tabla] = {linea.split()[1] for linea in cuerpo.splitlines() if linea.strip()}
    return columnas


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


def test_la_pagina_del_modelo_de_datos_explica_cada_tabla_de_las_migraciones() -> None:
    """la página del modelo de datos explica cada tabla de las migraciones @DOC-01-S1"""
    tablas = _tablas()
    entidades = _entidades()
    texto = _texto(MODELO)

    assert entidades.keys() == tablas.keys()
    assert "reserva_con_estado" in texto
    assert "erDiagram" in texto and set(_diagrama_er(texto)) == set(tablas)
    for tabla, columnas in tablas.items():
        cuerpo = entidades[tabla]
        assert len(cuerpo.split()) > 15, tabla
        assert "firebase_uid" in cuerpo or tabla != "usuario"
        nombradas = set(re.findall(r"`([a-z_][a-z_0-9]*)`", cuerpo))
        assert columnas - {"id", "creado_en", "modificado_en"} <= nombradas, (
            tabla,
            sorted(columnas - nombradas),
        )


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


def test_la_seccion_data_de_system_design_remite_a_la_pagina_del_modelo_de_datos_sin_repetir_sus_columnas() -> (
    None
):
    """la sección Data de system-design remite a la página del modelo de datos sin repetir sus columnas @DOC-01-S3 @assumption:DOC-01-ASM-01"""
    datos = _secciones(_texto(DISENO), "##")["Data"]

    assert "modelo-de-datos.md" in datos
    assert "firebase_uid" not in datos
    assert "|" not in datos
    assert len(datos.split()) < 120


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


def _rutas_documentadas() -> set[str]:
    tabla = _secciones(_texto(NAVEGACION), "##")["Rutas"]
    filas = re.findall(r"^\| `([^`]+)` \|", tabla, re.M)
    return {fila.split("?")[0] for fila in filas}


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


def test_el_sitio_de_documentacion_incluye_el_modelo_de_datos_y_la_navegacion_en_tecnica() -> None:
    """el sitio de documentación incluye el modelo de datos y la navegación en Técnica @DOC-01-S3"""
    copiar = _texto(COPIAR)
    paginas = re.findall(r"\['([^']+)', '(tecnica/[^']+)', (\d+)\]", copiar)
    por_origen = {origen: (destino, int(pos)) for origen, destino, pos in paginas}

    assert por_origen["docs/technical/modelo-de-datos.md"] == ("tecnica/modelo-de-datos.md", 2)
    assert por_origen["docs/technical/navegacion-de-la-app.md"] == (
        "tecnica/navegacion-de-la-app.md",
        3,
    )
    posiciones = [pos for _, pos in por_origen.values()]
    assert sorted(posiciones) == list(range(1, len(posiciones) + 1))
    assert (RAIZ / "docs" / "technical" / "modelo-de-datos.md").exists() or "existsSync" in copiar
    assert "existsSync(join(repo, origen))" in copiar
