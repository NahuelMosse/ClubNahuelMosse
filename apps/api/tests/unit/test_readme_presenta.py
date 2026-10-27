import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
README = (RAIZ / "README.md").read_text(encoding="utf-8")
RECORRIDO = [
    "00-carga",
    "01-login",
    "02-inicio",
    "03-sedes",
    "04-sede",
    "05-horarios",
    "06-confirmar",
    "07-listo",
    "08-reservas",
    "09-avisos",
    "10-perfil",
    "11-inicio-claro",
    "12-admin-reservas",
]
SECCIONES = ["Qué hace", "Cómo está hecha", "Cómo correrla", "Documentación"]
ENLACES_QUE_LEEN_LOS_TESTS = [
    "apps/api/README.md",
    "apps/mobile/README.md",
    "docs/guia-basica.md",
    "docs/technical/arquitectura.md",
    "docs/technical/runbook.md",
    "specs/asvs.md",
]
FORMAS_DE_SECRETO = [r"Test1234", r"xkeysib-", r"rnd_", r"contraseña:"]


def test_el_readme_muestra_capturas_reales_de_cada_paso_del_recorrido_y_del_panel_de_administracion_y_cada_imagen_existe() -> (  # noqa: E501
    None
):
    """el README muestra capturas reales de cada paso del recorrido y del panel de administración,
    y cada imagen existe @DOC-05-S1 @assumption:DOC-05-ASM-02"""
    imagenes = re.findall(r'src="([^"]+)"|!\[[^\]]*\]\(([^)\s]+)\)', README)
    rutas = [a or b for a, b in imagenes]

    for ruta in rutas:
        assert (RAIZ / ruta).is_file(), ruta
    for paso in RECORRIDO:
        assert any(f"docs/capturas/{paso}." in ruta for ruta in rutas), paso
    assert "datos de prueba" in README


def test_el_readme_presenta_que_es_que_hace_como_esta_hecha_con_enlace_a_integraciones_como_correrla_y_la_documentacion() -> (  # noqa: E501
    None
):
    """el README presenta qué es, qué hace, cómo está hecha con enlace a integraciones, cómo
    correrla y la documentación @DOC-05-S2"""
    titulos = re.findall(r"^## (.+)$", README, flags=re.M)

    for seccion in SECCIONES:
        assert seccion in titulos, seccion
    assert "docs/technical/integraciones.md" in README
    for tecnologia in ("Flutter", "FastAPI", "PostgreSQL", "Firebase", "Brevo", "Render"):
        assert tecnologia in README, tecnologia


def test_lo_que_los_tests_de_documentacion_leen_del_readme_sigue_estando() -> None:
    """lo que los tests de documentación leen del README sigue estando @assumption:DOC-05-ASM-01"""
    for enlace in ENLACES_QUE_LEEN_LOS_TESTS:
        assert enlace in README, enlace
    for comando in ("sh scripts/test.sh", "npm run emuladores", "npm run build"):
        assert comando in README, comando
    assert re.search(r"^- REV-07-ASM-01", README, flags=re.M)


def test_el_readme_no_publica_contrasenas_ni_claves() -> None:
    """el README no publica contraseñas ni claves @assumption:DOC-05-ASM-03"""
    for forma in FORMAS_DE_SECRETO:
        assert not re.search(forma, README, flags=re.I), forma
