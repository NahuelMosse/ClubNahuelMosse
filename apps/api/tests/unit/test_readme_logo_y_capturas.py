import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
README = (RAIZ / "README.md").read_text(encoding="utf-8")
CAPTURAS = RAIZ / "docs" / "capturas"
LOGO = "docs/logo.png"
ICONO_DE_LA_APP = RAIZ / "apps" / "mobile" / "assets" / "icono" / "icono.png"
CAPTURAS_ELEGIDAS = [
    "docs/capturas/01-login.jpg",
    "docs/capturas/03-sedes.jpg",
    "docs/capturas/05-horarios.jpg",
    "docs/capturas/07-listo.jpg",
]


def _imagenes() -> list[str]:
    return re.findall(r'src="([^"]+)"', README)


def test_el_readme_abre_con_el_logo_de_la_app_arriba_del_nombre() -> None:
    """el README abre con el logo de la app arriba del nombre
    @DOC-09-S1 @assumption:DOC-09-ASM-02"""
    assert _imagenes()[0] == LOGO
    assert (RAIZ / LOGO).read_bytes() == ICONO_DE_LA_APP.read_bytes()
    assert README.index(LOGO) < README.index("ClubNahuelMosse</h1>")
    assert re.search(r'<p align="center">\s*<img src="docs/logo.png"', README)


def test_el_readme_muestra_en_una_fila_inicio_de_sesion_sedes_horarios_y_reserva_confirmada() -> (
    None
):
    """el README muestra en una fila inicio de sesión, sedes, horarios y reserva confirmada,
    sin capturas sin usar @DOC-09-S2 @assumption:DOC-09-ASM-01"""
    capturas = [r for r in _imagenes() if r.startswith("docs/capturas/")]
    filas = re.findall(r'<p align="center">(.*?)</p>', README, flags=re.S)

    assert capturas == CAPTURAS_ELEGIDAS
    assert len([f for f in filas if "docs/capturas/" in f]) == 1
    assert {p.name for p in CAPTURAS.iterdir()} == {Path(r).name for r in capturas}
