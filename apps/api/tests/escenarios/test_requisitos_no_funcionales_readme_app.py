"""El README de la app alcanza para configurarla y ejecutarla, con la configuración en `lib/comun/`."""

import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[4]
APP = RAIZ / "apps" / "mobile"


def _leer(ruta: Path) -> str:
    return ruta.read_text(encoding="utf-8")


def _comandos(readme: str) -> list[str]:
    bloques = re.findall(r"```[a-z]*\n(.*?)```", readme, re.S)
    return [linea.strip() for b in bloques for linea in b.splitlines() if linea.strip()]


def _secciones(readme: str) -> str:
    return " ".join(re.findall(r"^#+ (.+)$", readme, re.M)).lower()


def test_el_readme_de_la_app_alcanza_para_configurar_y_ejecutarla() -> None:
    """siguiendo sólo el README de la app se configura y ejecuta la app @RNF-01-H07-01 @supuesto:RNF-01-SUP-05"""
    readme = _leer(APP / "README.md")
    definidas = set(
        re.findall(
            r"String\.fromEnvironment\(\s*'([A-Z_]+)'",
            _leer(APP / "lib" / "comun" / "configuracion.dart"),
        )
    )

    for seccion in ("configurar", "ejecutar", "probar"):
        assert seccion in _secciones(readme), seccion
    assert {"API_URL", "AUTH_EMULADOR", "FIREBASE_API_KEY"} <= definidas
    assert not {v for v in definidas if v not in readme}, "variables sin documentar"
    for comando in _comandos(readme):
        for guion in re.findall(r"scripts/[\w.]+", comando):
            assert (RAIZ / guion).is_file(), comando
    assert "flutter pub get" in readme
    assert "flutter run" in readme
    assert "flutter build apk" in readme
