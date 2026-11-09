import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
README = (RAIZ / "README.md").read_text(encoding="utf-8")
CAPTURAS = RAIZ / "docs" / "screenshots"
MAXIMO_DE_CAPTURAS = 4


def test_el_readme_muestra_a_lo_sumo_4_capturas_en_una_fila_sin_contar_el_logo() -> None:
    """el README muestra a lo sumo 4 capturas en una fila y no quedan capturas sin usar,
    sin contar el logo @DOC-06-S1"""
    rutas = [r for r in re.findall(r'src="([^"]+)"', README) if r.startswith("docs/screenshots/")]
    filas = re.findall(r"<p align=\"center\">(.*?)</p>", README, flags=re.S)

    assert 1 <= len(rutas) <= MAXIMO_DE_CAPTURAS
    assert len([f for f in filas if "docs/screenshots/" in f]) == 1
    for ruta in rutas:
        assert (RAIZ / ruta).is_file(), ruta
    assert README.index("docs/screenshots/") < README.index("## What it does")
    assert not {p.name for p in CAPTURAS.iterdir()} - {Path(r).name for r in rutas}
