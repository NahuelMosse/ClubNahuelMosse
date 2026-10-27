"""Documentación de producción: lo que cada supuesto de la card REV-07 exige de los documentos."""

import re
import subprocess
from pathlib import Path

from tests.escenarios.test_documentacion_vigente import (
    _columnas_por_tabla,
    _requisitos,
    _seccion,
    _texto,
)

RAIZ = Path(__file__).resolve().parents[4]
API = RAIZ / "apps" / "api"
MOVIL = RAIZ / "apps" / "mobile"
DISENO = RAIZ / "docs" / "technical" / "system-design.md"
ASVS = RAIZ / "specs" / "asvs.md"
COSTOS = RAIZ / "docs" / "technical" / "infra-cost.md"
RUNBOOK = RAIZ / "docs" / "technical" / "runbook.md"
ACCESIBILIDAD = RAIZ / "docs" / "business" / "accessibility.md"
FILA_ASVS = re.compile(r"^\| \*\*(V\d+\.\d+\.\d+)\*\* .*\| *([^|]*?) *\| *([^|]*?) *\|$", re.M)
TIPOS = (
    r"bigint|text|integer|boolean|date|timestamptz|time|smallint|numeric|jsonb|integer\[\]|int\[\]"
)
DOCUMENTOS = (
    ASVS,
    DISENO,
    RAIZ / "docs" / "adr" / "0001-stack.md",
    RAIZ / "docs" / "adr" / "0002-hosting-en-render.md",
    COSTOS,
    RUNBOOK,
    ACCESIBILIDAD,
    RAIZ / "README.md",
    API / "README.md",
    MOVIL / "README.md",
)


def _ids_registrados() -> set[str]:
    textos = "".join(_texto(a) for a in (RAIZ / "specs").rglob("*.md"))
    return set(re.findall(r"\b[A-Z]+-[\d.]+[a-z]?-(?:SUP|ASM)-\d+\b", textos))


def _supuestos(texto: str) -> list[str]:
    return re.findall(r"^- ([A-Z]+-[\d.]+[a-z]?-(?:SUP|ASM)-\d+)", texto, re.M)


def test_el_diseno_del_sistema_dice_lo_que_hoy_falta_y_lo_escribe_como_meta_sin_medir() -> None:
    """el diseño del sistema dice lo que hoy falta y lo escribe como meta sin medir
    @REV-07-S2 @assumption:REV-07-ASM-01
    """
    diseno = _texto(DISENO)

    assert re.search(r"sin medir", _seccion(diseno, "Performance and capacity budget"))
    assert re.search(r"no hay backups|sin backups", diseno, re.I)
    assert re.search(r"SLO[^\n]*(sin medir|meta|objetivo)", diseno, re.I)


def test_el_modelo_de_datos_lleva_columnas_claves_indices_y_triggers_de_cada_tabla() -> None:
    """el modelo de datos lleva columnas, claves, índices y triggers de cada tabla
    @REV-07-S8 @assumption:REV-07-ASM-03
    """
    datos = _seccion(_texto(DISENO), "Data")

    assert re.search(r"PRIMARY KEY|clave primaria", datos, re.I)
    assert re.search(r"FOREIGN KEY|clave foránea|REFERENCES", datos, re.I)
    assert re.search(r"índice|INDEX", datos, re.I)
    assert re.search(r"trigger", datos, re.I)
    for tabla in _columnas_por_tabla():
        assert f"`{tabla}`" in datos, tabla


def test_el_diseno_del_sistema_trata_las_seis_categorias_stride() -> None:
    """el diseño del sistema trata las seis categorías STRIDE
    @REV-07-S2 @assumption:REV-07-ASM-09
    """
    amenazas = _seccion(_texto(DISENO), "Threat model")
    categorias = ("Spoofing", "Tampering", "Repudiation", "Information disclosure",
                  "Denial of service", "Elevation of privilege")  # fmt: skip

    for categoria in categorias:
        filas = [f for f in amenazas.splitlines() if f.startswith("| T-") and categoria in f]
        assert filas, categoria
        assert all(re.search(r"mitigate|eliminate|transfer|accept", f) for f in filas), categoria


def test_cada_tabla_del_esquema_migrado_figura_en_el_modelo_de_datos_con_sus_columnas() -> None:
    """cada tabla del esquema migrado figura en el modelo de datos con sus columnas
    @REV-07-S8 @assumption:REV-07-ASM-10
    """
    datos = _seccion(_texto(DISENO), "Data")
    tablas = _columnas_por_tabla()

    assert len(tablas) == 9
    for tabla, columnas in tablas.items():
        trozos = re.split(rf"^#+ .*`{tabla}`.*$", datos, flags=re.M)
        assert len(trozos) > 1, tabla
        seccion = re.split(r"^#+ ", trozos[1], flags=re.M)[0]
        assert [c for c in sorted(columnas) if f"`{c}`" not in seccion] == [], tabla


def test_el_diseno_del_sistema_trae_el_inventario_de_datos_personales() -> None:
    """el diseño del sistema trae el inventario de datos personales
    @REV-07-S2 @assumption:REV-07-ASM-15
    """
    personales = _seccion(_texto(DISENO), "Personal data")

    for dato in ("DNI", "correo", "fecha de nacimiento", "token de dispositivo"):
        assert dato in personales, dato
    for columna in ("Retention", "How it is deleted", "Legal basis"):
        assert columna in personales, columna


def test_cada_adr_compara_dos_alternativas_o_mas() -> None:
    """cada ADR compara dos alternativas o más @REV-07-S3 @assumption:REV-07-ASM-15"""
    registros = sorted((RAIZ / "docs" / "adr").glob("[0-9][0-9][0-9][0-9]-*.md"))

    assert registros
    for registro in registros:
        assert len(re.findall(r"^### Alternative \w", _texto(registro), re.M)) >= 2, registro.name
        assert _seccion(_texto(registro), "Decision and why").strip(), registro.name


def test_los_documentos_del_grado_production_existen_aunque_el_modulo_docs_este_apagado() -> None:
    """los documentos del grado production existen aunque el módulo docs esté apagado
    @REV-07-S1 @assumption:REV-07-ASM-04
    """
    for documento in DOCUMENTOS:
        assert documento.is_file(), documento
        assert len(_texto(documento).split()) > 100, documento


def test_los_documentos_dicen_que_describen_la_rama_kit_3() -> None:
    """los documentos dicen que describen la rama kit-3 @REV-07-S1 @assumption:REV-07-ASM-05"""
    for documento in (ASVS, DISENO, RUNBOOK, COSTOS, ACCESIBILIDAD):
        assert "kit-3" in _texto(documento), documento


def test_las_filas_asvs_que_fallan_quedan_fails_con_su_hallazgo_y_su_card() -> None:
    """las filas ASVS que fallan quedan fails con su hallazgo y su card, y V15.1.1 queda fails
    hasta que decida una persona @REV-07-S1 @assumption:REV-07-ASM-06
    """
    filas = {m.group(1): m.group(0) for m in FILA_ASVS.finditer(_texto(ASVS))}
    fallan = [f for f in filas.values() if "| `fails` |" in f]

    assert fallan
    for fila in fallan:
        assert re.search(r"hallazgo \d+|sin card|no figura en la revisión", fila), fila[:60]
        assert re.search(r"REV-0\d|sin card|persona", fila), fila[:60]
    assert "| `fails` |" in filas["V15.1.1"]
    assert "persona" in filas["V15.1.1"]


def test_cada_ruta_de_evidencia_de_la_matriz_asvs_existe_en_el_repo() -> None:
    """cada ruta de evidencia de la matriz ASVS existe en el repo
    @REV-07-S1 @assumption:REV-07-ASM-11
    """
    versionados = subprocess.run(
        ["git", "ls-files"], cwd=RAIZ, capture_output=True, text=True, check=True
    ).stdout.splitlines()
    rutas = set()
    for fila in FILA_ASVS.finditer(_texto(ASVS)):
        rutas |= set(
            re.findall(r"`([\w.\-]+(?:/[\w.\-]+)+\.[a-z]{2,5})(?::[\d,:\-]+)?`", fila.group(3))
        )

    assert rutas
    inexistentes = [
        r for r in sorted(rutas) if not any(v == r or v.endswith("/" + r) for v in versionados)
    ]
    assert inexistentes == []


def test_la_matriz_asvs_declara_el_nivel_2_elegido() -> None:
    """la matriz ASVS declara el nivel 2 elegido @REV-07-S1 @assumption:REV-07-ASM-15"""
    cabecera = _texto(ASVS)[:2500]

    assert "nivel 2" in cabecera
    assert "elige" in cabecera


def test_la_matriz_es_asvs_5_con_los_253_requisitos_de_los_niveles_1_y_2() -> None:
    """la matriz es ASVS 5.0 con los 253 requisitos de los niveles 1 y 2, como V15.1.1
    @REV-07-S1 @assumption:REV-07-ASM-16
    """
    esperados = _requisitos("asvs-level-1.md") | _requisitos("asvs-level-2.md")
    filas = {m.group(1) for m in FILA_ASVS.finditer(_texto(ASVS))}

    assert "ASVS 5.0" in _texto(ASVS)[:200]
    assert len(esperados) == 253
    assert filas == esperados
    assert "V15.1.1" in filas


def test_los_precios_citan_la_pagina_de_render_y_que_no_dice_si_la_base_free_tiene_backups() -> (
    None
):
    """los precios citan https://render.com/pricing.md consultado el 2026-10-20 y que no dice si
    la base free tiene backups @REV-07-S5 @assumption:REV-07-ASM-08
    """
    costos = _texto(COSTOS)

    assert "https://render.com/pricing.md" in costos
    assert "2026-10-20" in costos
    assert "no dice si la base free tiene backups" in costos


def test_el_registro_de_accesibilidad_nombra_cada_pantalla_con_lector_navegador_y_resultado() -> (
    None
):
    """el registro de accesibilidad nombra cada pantalla con lector, navegador y resultado, o no se
    pudo correr @REV-07-S7 @assumption:REV-07-ASM-12
    """
    registro = _seccion(_texto(ACCESIBILIDAD), "Registro por pantalla").splitlines()
    pantallas = sorted(p.stem for p in (MOVIL / "lib").rglob("pantalla_*.dart"))

    assert pantallas
    for pantalla in pantallas:
        fila = next((f for f in registro if f"`{pantalla}`" in f), "")
        assert fila, pantalla
        assert re.search(r"Supports|Does Not Support|Not Applicable", fila), pantalla
        assert re.search(r"TalkBack", fila), pantalla
        assert re.search(r"not verified|no se pudo correr|capturas", fila), pantalla


def test_ningun_documento_lleva_secretos_cadenas_de_conexion_con_contrasena_tokens_ni_correos() -> (
    None
):
    """ningún documento lleva secretos, cadenas de conexión con contraseña, tokens ni correos
    personales @REV-07-S6 @assumption:REV-07-ASM-14
    """
    patrones = {
        "conexión con contraseña": r"\b[\w+]+://[^\s:/@<`]+:[^\s@/<`]+@",
        "clave de API": r"AIza[0-9A-Za-z_\-]{30,}",
        "token": r"\beyJ[0-9A-Za-z_\-]{20,}\.[0-9A-Za-z_\-]{10,}",
        "clave privada": r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
        "token de GitHub": r"\bgh[pousr]_[0-9A-Za-z]{30,}",
        "correo personal": r"[\w.+-]+@(?:gmail|hotmail|outlook|yahoo|live)\.\w+",
    }

    for documento in DOCUMENTOS:
        for nombre, patron in patrones.items():
            assert not re.search(patron, _texto(documento)), (documento.name, nombre)


def test_el_runbook_nombra_cada_secreto_sin_su_valor() -> None:
    """el runbook nombra cada secreto sin su valor @REV-07-S6 @assumption:REV-07-ASM-14"""
    rotacion = _seccion(_texto(RUNBOOK), "Secret rotation and revocation")
    inventario = _seccion(_texto(DISENO), "Secrets inventory")
    secretos = re.findall(r"^\| `([A-Z][A-Z_]+)`", inventario, re.M)

    assert {"DATABASE_URL", "FIREBASE_CREDENCIALES_JSON", "SMTP_CONTRASENA"} <= set(secretos)
    for secreto in ("DATABASE_URL", "FIREBASE_CREDENCIALES_JSON", "SMTP_CONTRASENA",
                    "ADMIN_CONTRASENA"):  # fmt: skip
        assert f"`{secreto}`" in rotacion, secreto
        assert not re.search(rf"{secreto}`?\s*=\s*\S{{6,}}", rotacion), secreto


def test_los_readme_listan_con_su_id_los_supuestos_que_cambian_lo_que_se_ve_u_opera() -> None:
    """los README listan con su ID los supuestos que cambian lo que se ve u opera, no los 545
    @REV-07-S10 @assumption:REV-07-ASM-02
    """
    api = _supuestos(_texto(API / "README.md"))
    movil = _supuestos(_texto(MOVIL / "README.md"))

    assert 5 <= len(api) <= 60
    assert 3 <= len(movil) <= 60
    assert set(api + movil) <= _ids_registrados()
    assert len(api) == len(set(api))
    assert len(movil) == len(set(movil))


def test_los_readme_listan_los_supuestos_de_1_a_4_h_y_7_dias_admin_no_reserva_catalogo_y_pagos() -> (
    None
):
    """los README listan los supuestos de 1 a 4 h y hasta 7 días de anticipación, el admin no
    reserva, catálogo fijo y sin pagos @REV-07-S10 @assumption:REV-07-ASM-17
    """
    api = _texto(API / "README.md")
    movil = _texto(MOVIL / "README.md")

    assert re.search(r"de 1 a 4 horas", api)
    assert re.search(r"hasta 7 días de anticipación", api)
    assert "administrador no reserva" in api
    assert "administrador no reserva" in movil
    assert re.search(r"catálogo[^\n]*fijo", api)
    assert re.search(r"catálogo[^\n]*fijo", movil)
    assert re.search(r"no hay pagos", movil)
