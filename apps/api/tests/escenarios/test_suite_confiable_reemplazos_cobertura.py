"""Reemplazos de dos pruebas de la suite confiable que fallan igual en main (ver `replaces:` en el Log de la card ENG-14)."""

import ast
import re
from pathlib import Path

from fastapi.testclient import TestClient

RAIZ_API = Path(__file__).resolve().parents[2]
UNITARIOS = RAIZ_API / "tests" / "unit" / "test_casos_de_uso_reservas.py"
CASOS_DE_USO = RAIZ_API / "app" / "modules" / "bookings" / "use_cases.py"
PRUEBA_RNF = RAIZ_API / "tests" / "escenarios" / "test_requisitos_no_funcionales.py"


def _casos_de_uso() -> list[str]:
    return re.findall(r"^def ([a-z]\w*)\(", CASOS_DE_USO.read_text(encoding="utf-8"), re.M)


def _cuerpo_de(fuente: str, nombre: str) -> str:
    for nodo in ast.parse(fuente).body:
        if isinstance(nodo, ast.FunctionDef) and nodo.name == nombre:
            return ast.get_source_segment(fuente, nodo) or ""
    return ""


def test_cada_funcion_publica_de_reservas_tiene_su_unitario() -> None:
    """cada función pública de aplicacion/reservas.py tiene su unitario
    @REV-08-S7 @assumption:REV-08-ASM-09
    """
    codigo = UNITARIOS.read_text(encoding="utf-8") if UNITARIOS.exists() else ""

    assert len(_casos_de_uso()) >= 7
    assert [c for c in _casos_de_uso() if not re.search(rf"\b{c}\(", codigo)] == []


def test_rnf_01_h04_01_se_prueba_contra_el_contrato_publicado(api: TestClient) -> None:
    """RNF-01-H04-01 se prueba contra el contrato publicado y no leyendo el README
    @REV-08-S4 @assumption:REV-08-ASM-08
    """
    contrato = api.get("/openapi.json")
    fuente = PRUEBA_RNF.read_text(encoding="utf-8")
    prueba = _cuerpo_de(fuente, "test_la_api_publica_openapi_con_todos_los_endpoints_que_usa_la_app")

    assert contrato.status_code == 200
    assert len(contrato.json()["paths"]) >= 20
    assert "swagger" in api.get("/docs").text.lower()
    assert "_operaciones(api)" in prueba
    assert "README" not in prueba
    assert "README" not in _cuerpo_de(fuente, "_endpoints_que_usa_la_app")
