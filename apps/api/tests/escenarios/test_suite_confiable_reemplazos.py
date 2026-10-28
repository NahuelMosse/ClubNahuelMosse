"""Reemplazos de tests congelados de test_suite_confiable.py (ver `replaces:` en el Log de la card)."""

import os
import subprocess
import sys
from pathlib import Path

RAIZ_API = Path(__file__).resolve().parents[2]
ESCENARIO = "tests/escenarios/test_registro_de_errores.py"


def _correr(*argumentos: str, entorno: dict[str, str]) -> "subprocess.CompletedProcess[str]":
    return subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", *argumentos],
        cwd=RAIZ_API, env=entorno, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip


def _entorno(quitar: tuple[str, ...] = (), poner: dict[str, str] | None = None) -> dict[str, str]:
    return {k: v for k, v in os.environ.items() if k not in quitar} | (poner or {})


def _falla_por_falta_de_emulador(corrida: "subprocess.CompletedProcess[str]") -> None:
    salida = corrida.stdout + corrida.stderr
    assert corrida.returncode != 0
    assert "hace falta el emulador de Firebase Auth" in salida
    assert "error" in salida.lower()


def test_con_la_variable_del_emulador_ausente_la_corrida_falla_con_el_mensaje_del_emulador() -> (
    None
):
    """con la variable del emulador ausente la corrida sale distinta de cero y dice que hace falta el emulador
    @REV-08-S5 @assumption:REV-08-ASM-10
    """
    corrida = _correr(ESCENARIO, entorno=_entorno(quitar=("FIREBASE_AUTH_EMULATOR_HOST",)))

    _falla_por_falta_de_emulador(corrida)


def test_con_el_emulador_apagado_la_corrida_falla_con_el_mensaje_del_emulador() -> None:
    """con el emulador apagado la corrida sale distinta de cero y dice que hace falta el emulador
    @REV-08-S5 @assumption:REV-08-ASM-10
    """
    corrida = _correr(
        ESCENARIO, entorno=_entorno(poner={"FIREBASE_AUTH_EMULATOR_HOST": "127.0.0.1:9"})
    )

    _falla_por_falta_de_emulador(corrida)
