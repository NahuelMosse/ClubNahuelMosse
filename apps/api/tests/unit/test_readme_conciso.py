import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
README = (RAIZ / "README.md").read_text(encoding="utf-8")
CAPTURAS = RAIZ / "docs" / "capturas"
SECCIONES = ["Qué hace", "Con qué está hecha", "Cómo correrla", "Documentación"]
ENLACES_QUE_LEEN_LOS_TESTS = [
    "apps/api/README.md",
    "apps/mobile/README.md",
    "docs/guia-basica.md",
    "docs/technical/arquitectura.md",
    "docs/technical/runbook.md",
    "specs/asvs.md",
]
COMANDOS_QUE_LEEN_LOS_TESTS = ("sh scripts/test.sh", "npm run emuladores", "npm run build")
FORMAS_DE_SECRETO = [r"Test1234", r"xkeysib-", r"rnd_", r"contraseña:"]
MAXIMO_DE_CAPTURAS = 4
MAXIMO_DE_LINEAS = 70
MAXIMO_DE_VINETAS_DE_QUE_HACE = 6


def _imagenes() -> list[str]:
    encontradas = re.findall(r'src="([^"]+)"|!\[[^\]]*\]\(([^)\s]+)\)', README)
    return [a or b for a, b in encontradas]


def _seccion(titulo: str) -> str:
    return re.search(rf"^## {titulo}$(.*?)(?=^## |\Z)", README, flags=re.M | re.S).group(1)


def test_el_readme_muestra_a_lo_sumo_4_capturas_en_una_fila_y_no_quedan_capturas_sin_usar() -> None:
    """el README muestra a lo sumo 4 capturas en una fila y no quedan capturas sin usar
    @DOC-06-S1"""
    rutas = _imagenes()
    filas = re.findall(r"<p align=\"center\">(.*?)</p>", README, flags=re.S)
    filas_con_capturas = [f for f in filas if "docs/capturas/" in f]

    assert 1 <= len(rutas) <= MAXIMO_DE_CAPTURAS
    assert len(filas_con_capturas) == 1
    for ruta in rutas:
        assert (RAIZ / ruta).is_file(), ruta
    assert README.index("docs/capturas/") < README.index("## Qué hace")
    sobrantes = {p.name for p in CAPTURAS.iterdir()} - {Path(r).name for r in rutas}
    assert not sobrantes, sobrantes


def test_el_readme_entra_en_unas_60_lineas_con_que_es_que_hace_en_6_vinetas_con_que_esta_hecha_como_correrla_y_la_documentacion() -> (  # noqa: E501
    None
):
    """el README entra en unas 60 líneas con qué es, qué hace en 6 viñetas, con qué está hecha,
    cómo correrla y la documentación @DOC-06-S2"""
    titulos = re.findall(r"^## (.+)$", README, flags=re.M)
    vinetas = re.findall(r"^- .+$", _seccion("Qué hace"), flags=re.M)

    assert len(README.splitlines()) <= MAXIMO_DE_LINEAS
    for seccion in SECCIONES:
        assert seccion in titulos, seccion
    assert 1 <= len(vinetas) <= MAXIMO_DE_VINETAS_DE_QUE_HACE
    assert "docs/technical/integraciones.md" in _seccion("Con qué está hecha")
    for tecnologia in ("Flutter", "FastAPI", "PostgreSQL", "Firebase", "Brevo", "Render"):
        assert tecnologia in README, tecnologia


def test_lo_que_los_tests_de_documentacion_leen_del_readme_sigue_estando() -> None:
    """lo que los tests de documentación leen del README sigue estando
    @assumption:DOC-06-ASM-01"""
    for enlace in ENLACES_QUE_LEEN_LOS_TESTS:
        assert enlace in README, enlace
    for comando in COMANDOS_QUE_LEEN_LOS_TESTS:
        assert comando in README, comando
    enlaces_a_docs = re.findall(r"\]\((docs/[^)#\s]+\.md)\)", README)
    assert any(
        re.search(r"^- REV-07-ASM-01", (RAIZ / e).read_text(encoding="utf-8"), flags=re.M)
        for e in enlaces_a_docs
    )


def test_el_readme_no_publica_contrasenas_ni_claves() -> None:
    """el README no publica contraseñas ni claves @assumption:DOC-06-ASM-02"""
    for forma in FORMAS_DE_SECRETO:
        assert not re.search(forma, README, flags=re.I), forma
