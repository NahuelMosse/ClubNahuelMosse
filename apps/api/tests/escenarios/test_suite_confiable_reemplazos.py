"""Reemplazos de tests congelados de test_suite_confiable.py (ver `replaces:` en el Log de la card)."""

import ast
import os
import re
import subprocess
import sys
from pathlib import Path

RAIZ_API = Path(__file__).resolve().parents[2]
UNITARIOS = RAIZ_API / "tests" / "unit" / "test_casos_de_uso_reservas.py"
ESCENARIO = "tests/escenarios/test_registro_de_errores.py"


def _correr(*argumentos: str, entorno: dict[str, str]) -> "subprocess.CompletedProcess[str]":
    return subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", *argumentos],
        cwd=RAIZ_API, env=entorno, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip


def _entorno(quitar: tuple[str, ...] = (), poner: dict[str, str] | None = None) -> dict[str, str]:
    return {k: v for k, v in os.environ.items() if k not in quitar} | (poner or {})


def _casos_de_uso() -> list[str]:
    fuente = (RAIZ_API / "app" / "aplicacion" / "reservas.py").read_text(encoding="utf-8")
    return [
        n.name
        for n in ast.parse(fuente).body
        if isinstance(n, ast.FunctionDef) and not n.name.startswith("_")
    ]


def _sin_unitario(codigo: str) -> list[str]:
    return [c for c in _casos_de_uso() if not re.search(rf"\b{c}\(", codigo)]


def _falla_por_falta_de_emulador(corrida: "subprocess.CompletedProcess[str]") -> None:
    salida = corrida.stdout + corrida.stderr
    assert corrida.returncode != 0
    assert "hace falta el emulador de Firebase Auth" in salida
    assert "error" in salida.lower()


def test_con_la_variable_del_emulador_ausente_la_corrida_falla_con_el_mensaje_del_emulador() -> None:
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


def test_cada_funcion_publica_de_reservas_tiene_su_unitario_con_la_llamada_en_el_codigo() -> None:
    """cada función pública de aplicacion/reservas.py se llama por su nombre en los unitarios
    @REV-08-S7 @assumption:REV-08-ASM-09
    """
    codigo = UNITARIOS.read_text(encoding="utf-8") if UNITARIOS.exists() else ""

    assert len(_casos_de_uso()) >= 7
    assert _sin_unitario(codigo) == []


def test_los_unitarios_de_reservas_pasan_sin_base_ni_emulador_y_cubren_cada_caso_de_uso() -> None:
    """los unitarios de los casos de uso de reservas pasan sin base ni emulador y llaman a cada caso de uso
    @REV-08-S7
    """
    sin_servicios = _entorno(
        quitar=("FIREBASE_AUTH_EMULATOR_HOST",),
        poner={
            "DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
            "TEST_DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
        },
    )

    corrida = _correr(str(UNITARIOS), entorno=sin_servicios)

    assert corrida.returncode == 0, corrida.stdout[-2000:]
    assert _sin_unitario(UNITARIOS.read_text(encoding="utf-8")) == []
