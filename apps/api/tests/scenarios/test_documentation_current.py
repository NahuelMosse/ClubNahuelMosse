"""Documentación de producción: lo que necesita quien opera, audita o mantiene la app."""

import re
import tomllib
from pathlib import Path

import yaml

from tests.current_schema import current
from tests.unit.test_documentation_model import _sql as _subida

RAIZ = Path(__file__).resolve().parents[4]
API = RAIZ / "apps" / "api"
MOVIL = RAIZ / "apps" / "mobile"
DESIGN = RAIZ / "docs" / "technical" / "system-design.md"
ESTADOS = {"meets", "fails", "not verified", "not applicable"}
FILA_ASVS = re.compile(r"^\| \*\*(V\d+\.\d+\.\d+)\*\* .*\| *([^|]*?) *\| *([^|]*?) *\|$", re.M)
TIPOS = (
    r"bigint|text|integer|boolean|date|timestamptz|time|smallint|numeric|jsonb|integer\[\]|int\[\]"
)


def _text(ruta: Path) -> str:
    return ruta.read_text(encoding="utf-8")


def _section(texto: str, titulo: str) -> str:
    """El cuerpo de la sección `## <titulo>` de un markdown, hasta la sección siguiente."""
    partes = re.split(r"^## ", texto, flags=re.M)
    return next((p for p in partes if p.startswith(titulo)), "")


def _requirements(plantilla: str) -> set[str]:
    return set(
        re.findall(r"\*\*(V\d+\.\d+\.\d+)\*\*", _text(RAIZ / ".claude" / "templates" / plantilla))
    )


def test_la_matriz_asvs_de_nivel_2_responde_cada_requisito() -> None:
    """la matriz ASVS de nivel 2 cubre cada requisito con su estado y evidencia @REV-07-S1"""
    matriz = _text(RAIZ / "specs" / "asvs.md")
    filas = {m.group(1): (m.group(2).strip("`"), m.group(3)) for m in FILA_ASVS.finditer(matriz)}

    assert re.search(r"\blevel\s*2\b|\bL2\b", matriz, re.I)
    assert set(filas) >= _requirements("asvs-level-1.md") | _requirements("asvs-level-2.md")
    assert {estado for estado, _ in filas.values()} <= ESTADOS
    assert all(len(evidencia) > 3 for _, evidencia in filas.values())
    assert sum(estado == "meets" for estado, _ in filas.values()) >= 20
    assert sum(estado == "fails" for estado, _ in filas.values()) >= 1


def test_el_diseno_del_sistema_tiene_amenazas_dependencias_entornos_y_objetivos() -> None:
    """el diseño del sistema describe amenazas, dependencias, entornos y objetivos de servicio
    @REV-07-S2
    """
    diseno = _text(DESIGN)
    dependencias = _section(diseno, "External dependencies")
    amenazas = _section(diseno, "Threat model")

    for externa in ("PostgreSQL", "Firebase Authentication", "Firebase Cloud Messaging", "SMTP"):
        assert externa in dependencias, externa
    for categoria in ("Spoofing", "Tampering", "Repudiation", "Information disclosure",
                      "Denial of service", "Elevation of privilege"):  # fmt: skip
        assert categoria in amenazas, categoria
    for superficie in ("API", "app", "base"):
        assert superficie in amenazas, superficie
    assert re.search(r"\blocal\b", _section(diseno, "Infrastructure"), re.I)
    assert "Render" in _section(diseno, "Infrastructure")
    assert re.search(r"SLO[^\n]*\d+(?:[.,]\d+)? ?%", diseno)


def test_las_decisiones_de_stack_y_hosting_estan_registradas() -> None:
    """las decisiones de arquitectura de stack y hosting están registradas @REV-07-S3"""
    registros = sorted((RAIZ / "docs" / "adr").glob("[0-9][0-9][0-9][0-9]-*.md"))
    textos = [_text(r) for r in registros]

    assert len(registros) >= 2
    assert all(
        _section(t, "Status").strip() and "accepted" in _section(t, "Status") for t in textos
    )
    assert any("FastAPI" in t and "Flutter" in t for t in textos)
    assert any("Render" in t for t in textos)


def _dependencias_directas() -> list[str]:
    proyecto = tomllib.loads(_text(API / "pyproject.toml"))["project"]["dependencies"]
    pubspec = yaml.safe_load(_text(MOVIL / "pubspec.yaml"))["dependencies"]
    python = [re.split(r"[\[<>=~! ;]", d, maxsplit=1)[0] for d in proyecto]
    dart = [nombre for nombre, origen in pubspec.items() if not isinstance(origen, dict)]
    return python + dart


def test_el_costo_de_operar_la_app_esta_calculado() -> None:
    """el costo de operar la app está calculado @REV-07-S5"""
    costos = _text(RAIZ / "docs" / "technical" / "infra-cost.md")

    assert _section(costos, "Volume assumptions").strip()
    assert "Render" in costos
    assert re.search(r"USD ?[1-9]", costos)
    assert "render.com/pricing" in costos


def test_el_runbook_dice_como_volver_atras_rotar_secretos_y_atender_incidentes() -> None:
    """el runbook dice cómo volver atrás, rotar secretos y atender un incidente @REV-07-S6"""
    runbook = _text(RAIZ / "docs" / "technical" / "runbook.md")

    for titulo in ("Deploy", "Roll back", "Incidents", "Secret rotation and revocation"):
        seccion = _section(runbook, titulo)
        assert len(seccion.split()) > 30, titulo
        assert "TODO" not in seccion, titulo
    assert "render.yaml" in runbook
    for secreto in ("FIREBASE_CREDENTIALS_JSON", "SMTP_PASSWORD"):
        assert secreto in _section(runbook, "Secret rotation and revocation"), secreto


def test_la_declaracion_de_accesibilidad_y_el_registro_por_pantalla_estan_publicados() -> None:
    """la declaración de accesibilidad y el registro por pantalla están publicados @REV-07-S7"""
    declaracion = _text(RAIZ / "docs" / "business" / "accessibility.md")
    pantallas = sorted(p.stem for p in (MOVIL / "lib").rglob("pantalla_*.dart"))
    termino = re.compile(r"Supports|Partially Supports|Does Not Support|Not Applicable")

    assert termino.search(_section(declaracion, "Conformance status"))
    sin_registro = [
        p
        for p in pantallas
        if not any(
            re.search(rf"\b{p}\b", f) and termino.search(f) for f in declaracion.splitlines()
        )
    ]
    assert sin_registro == []


def _columns_by_table() -> dict[str, set[str]]:
    migraciones = "".join(
        _text(m) for m in sorted((API / "migrations" / "versions").glob("*.py"))
    )
    tablas: dict[str, set[str]] = {}
    for tabla, cuerpo in re.findall(r"CREATE TABLE (\w+) \((.*?)\n\s*\)", migraciones, re.S):
        tablas[tabla] = set(re.findall(rf"^\s*(\w+) (?:{TIPOS})\b", cuerpo, re.M))
    for tabla, columna in re.findall(
        rf"ALTER TABLE (\w+)\s+ADD COLUMN (\w+) (?:{TIPOS})", migraciones
    ):
        tablas.setdefault(tabla, set()).add(columna)
    for migracion in sorted((API / "migrations" / "versions").glob("*.py")):
        for tabla, vieja, nueva in re.findall(
            r"ALTER TABLE (\w+) RENAME COLUMN (\w+) TO (\w+)", _subida(migracion)
        ):
            tablas.setdefault(tabla, set()).discard(vieja)
            tablas[tabla].add(nueva)
    return current(tablas)


def test_el_presupuesto_de_rendimiento_y_capacidad_esta_escrito() -> None:
    """el presupuesto de rendimiento y capacidad está escrito @REV-07-S9"""
    diseno = _text(DESIGN)

    assert re.search(r"p95[^\n]*\d+ ?ms", diseno)
    assert re.search(r"capacity[^\n]*\d+", diseno, re.I)


def _ids_registrados() -> set[str]:
    textos = "".join(_text(a) for a in (RAIZ / "specs").rglob("*.md"))
    return set(re.findall(r"\b[A-Z]+-[\d.]+[a-z]?-(?:SUP|ASM)-\d+\b", textos))


def test_quien_opera_la_app_encuentra_los_supuestos_en_los_readme() -> None:
    """quien opera la app encuentra los supuestos que la limitan en los README @REV-07-S10"""
    raiz = _text(RAIZ / "README.md")
    api = _text(API / "README.md")
    movil = _text(MOVIL / "README.md")
    supuesto = re.compile(r"^- ([A-Z]+-[\d.]+[a-z]?-(?:SUP|ASM)-\d+)", re.M)
    listados = supuesto.findall(api) + supuesto.findall(movil)

    assert "apps/api/README.md" in raiz
    assert "apps/mobile/README.md" in raiz
    assert len(supuesto.findall(api)) >= 5
    assert len(supuesto.findall(movil)) >= 3
    assert set(listados) <= _ids_registrados()
    for idea in ("4 hours", "7 days", "payments", "admin", "catalog"):
        assert idea in api + movil, idea


def test_las_licencias_mpl_lgpl_y_ofl_tienen_su_excepcion_o_su_texto() -> None:
    """las licencias MPL, LGPL y OFL tienen su excepción o su texto @REV-07-S11"""
    ofl = _text(MOVIL / "assets" / "fuentes" / "OFL.txt")

    assert sorted((MOVIL / "assets" / "fuentes").glob("Inter-*.ttf"))
    assert "SIL OPEN FONT LICENSE VERSION 1.1" in ofl.upper()
    assert re.search(r"Copyright .*Inter", ofl)
