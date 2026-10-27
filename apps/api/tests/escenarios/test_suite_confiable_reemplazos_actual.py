"""Reemplazos de los unitarios de reservas tras renombrar el módulo a bookings (ver `replaces:` en el Log de la card ENG-14)."""

import ast
import os
import re
import subprocess
import sys
from pathlib import Path

RAIZ_API = Path(__file__).resolve().parents[2]
UNITARIOS = RAIZ_API / "tests" / "unit" / "test_casos_de_uso_reservas.py"
CASOS_DE_USO = RAIZ_API / "app" / "modules" / "bookings" / "use_cases.py"


def _entorno_sin_servicios() -> dict[str, str]:
    base = {k: v for k, v in os.environ.items() if k != "FIREBASE_AUTH_EMULATOR_HOST"}
    return base | {
        "DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
        "TEST_DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
    }


def _casos_de_uso() -> list[str]:
    fuente = CASOS_DE_USO.read_text(encoding="utf-8")
    return [
        n.name
        for n in ast.parse(fuente).body
        if isinstance(n, ast.FunctionDef) and not n.name.startswith("_")
    ]


def _sin_unitario(codigo: str) -> list[str]:
    return [c for c in _casos_de_uso() if not re.search(rf"\b{c}\(", codigo)]


def test_cada_funcion_publica_de_reservas_tiene_su_unitario_con_la_llamada_en_el_codigo() -> None:
    """cada función pública de bookings/use_cases.py se llama por su nombre en los unitarios
    @REV-08-S7 @assumption:REV-08-ASM-09
    """
    codigo = UNITARIOS.read_text(encoding="utf-8") if UNITARIOS.exists() else ""

    assert len(_casos_de_uso()) >= 7
    assert _sin_unitario(codigo) == []


def test_los_unitarios_de_reservas_pasan_sin_base_ni_emulador_y_cubren_cada_caso_de_uso() -> None:
    """los unitarios de los casos de uso de reservas pasan sin base ni emulador y llaman a cada caso de uso
    @REV-08-S7
    """
    corrida = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", str(UNITARIOS)],
        cwd=RAIZ_API, env=_entorno_sin_servicios(), capture_output=True, text=True,
        timeout=300, check=False,
    )  # fmt: skip

    assert corrida.returncode == 0, corrida.stdout[-2000:]
    assert _sin_unitario(UNITARIOS.read_text(encoding="utf-8")) == []
