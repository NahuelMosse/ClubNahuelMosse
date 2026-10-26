import ast
import re
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import config
from app.main import crear_app

API = Path(__file__).resolve().parents[2]
RAIZ = API.parents[1]
INFRA = API / "app" / "infraestructura"


def _metodo(archivo: str, nombre: str) -> str:
    arbol = ast.parse((INFRA / archivo).read_text(encoding="utf-8"))
    for nodo in ast.walk(arbol):
        if isinstance(nodo, ast.FunctionDef) and nodo.name == nombre:
            return ast.unparse(nodo)
    raise AssertionError(f"{archivo} no tiene {nombre}")


def test_las_metricas_no_publican_created_y_el_histograma_conserva_sus_cortes(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """las métricas no publican _created y el histograma conserva sus cortes
    @ARQ-02-S1 @assumption:ARQ-02-ASM-02"""
    monkeypatch.setattr(config, "metricas_token", "secreto")
    app = crear_app()
    app.add_api_route("/otra-cosa", lambda: {"ok": True})
    c = TestClient(app, base_url="http://localhost")
    c.get("/otra-cosa")
    metricas = c.get("/metrics", headers={"Authorization": "Bearer secreto"}).text

    assert "_created" not in metricas
    cortes = set(re.findall(r'solicitud_segundos_bucket\{[^}]*ruta="/otra-cosa"[^}]*\}', metricas))
    les = {re.search(r'le="([^"]+)"', c_).group(1) for c_ in cortes if re.search(r'le="', c_)}
    assert les == {"0.05", "0.1", "0.25", "0.5", "1.0", "2.5", "5.0", "10.0", "+Inf"}
    assert re.search(r'solicitudes_total\{metodo="GET",ruta="/otra-cosa",codigo="200"\}', metricas)


def test_los_avisos_de_terceros_y_el_mapa_del_codigo_siguen_al_dia() -> None:
    """los avisos de terceros y el mapa del código siguen al día @ARQ-02-S3"""
    avisos = (RAIZ / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
    mapa = (RAIZ / "docs" / "technical" / "mapa-del-codigo.md").read_text(encoding="utf-8")

    assert "prometheus-client" in avisos or "prometheus_client" in avisos
    assert "email-validator" not in avisos
    assert "dnspython" not in avisos
    assert "`errores_http.py`" in mapa


def test_la_agenda_de_una_sede_se_arma_en_una_sola_funcion_y_con_los_dias_en_tupla() -> None:
    """la agenda de una sede se arma en una sola función y con los días en tupla
    @ARQ-02-S2 @assumption:ARQ-02-ASM-06"""
    codigo = {a.name: a.read_text(encoding="utf-8") for a in INFRA.glob("*.py")}
    armados = {n: len(re.findall(r"\bAgenda\(", t)) for n, t in codigo.items()}

    assert sum(armados.values()) == 1
    (archivo,) = [n for n, c in armados.items() if c]
    assert re.search(r"Agenda\([^)]*tuple\(", codigo[archivo], flags=re.DOTALL)


def test_los_repositorios_confirman_con_en_transaccion() -> None:
    """los repositorios confirman con en_transaccion y los métodos que corren dentro de otro
    no lo usan @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    db = (INFRA / "db.py").read_text(encoding="utf-8")
    assert "def en_transaccion(" in db
    usan = [
        a.name for a in INFRA.glob("*.py") if "en_transaccion(" in a.read_text(encoding="utf-8")
    ]
    assert len(usan) >= 6

    for archivo, metodo in [
        ("reservas.py", "cancelar_futuras_de"),
        ("espacios.py", "dar_de_baja_de_sede"),
        ("notificaciones.py", "encolar_cancelacion_usuario"),
    ]:
        cuerpo = _metodo(archivo, metodo)
        assert "en_transaccion" not in cuerpo, metodo
        assert ".commit()" not in cuerpo, metodo


def test_las_reservas_se_arman_con_fila_mapping() -> None:
    """las reservas se arman con fila._mapping @ARQ-02-S1 @assumption:ARQ-02-ASM-06"""
    reservas = (INFRA / "reservas.py").read_text(encoding="utf-8")

    assert "Reserva(**" in reservas
    assert "._mapping" in reservas
