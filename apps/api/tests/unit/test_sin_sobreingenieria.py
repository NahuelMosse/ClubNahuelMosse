"""SIM-01: la API sin lo que el grado production agregó y un TP no pide."""

import importlib.util
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import config
from app.main import crear_app

RAIZ_API = Path(__file__).resolve().parents[2]
RAIZ_REPO = RAIZ_API.parents[1]
_RETIRADOS = ("limites", "metricas", "protecciones", "registro_errores", "marcador")


def test_la_api_no_publica_metricas_ni_limita_pedidos_ni_agrega_encabezados() -> None:
    """la API no publica métricas, no limita pedidos ni agrega encabezados de seguridad, id de pedido ni /ready @SIM-01-S1"""
    with TestClient(crear_app()) as cliente:
        assert cliente.get("/metrics").status_code == 404
        assert cliente.get("/ready").status_code == 404
        salud = cliente.get("/health")
        assert salud.status_code == 200
        assert "content-security-policy" not in salud.headers
        assert "x-request-id" not in salud.headers
        estados = {cliente.post("/registro", json={}).status_code for _ in range(120)}
    assert 429 not in estados


def test_un_error_no_previsto_responde_500_sin_cuerpo_propio() -> None:
    """un error no previsto responde 500 sin cuerpo propio @SIM-01-S1 @assumption:SIM-01-ASM-03"""
    app = crear_app()

    @app.get("/_explota")
    def explota() -> None:
        raise RuntimeError("falla")

    with TestClient(app, raise_server_exceptions=False) as cliente:
        r = cliente.get("/_explota")
    assert r.status_code == 500
    assert r.text == "Internal Server Error"
    assert "x-request-id" not in r.headers


def test_prometheus_client_deja_de_ser_dependencia() -> None:
    """prometheus-client deja de ser dependencia @SIM-01-S2"""
    for archivo in ("pyproject.toml", "uv.lock"):
        assert "prometheus" not in (RAIZ_API / archivo).read_text(encoding="utf-8").lower()


def test_no_hay_tiempos_de_espera_chequeo_de_emulador_host_ni_logs_json(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """la API no tiene tiempos de espera de la base, chequeo del emulador, filtro de Host ni logs en JSON @SIM-01-S1"""
    from app.infraestructura import db

    for nombre in ("base_disponible", "esquema_al_dia", "uso_del_pool", "POOL_MAXIMO"):
        assert not hasattr(db, nombre)
    for opcion in ("database_url_app", "metricas_token", "detras_de_proxy", "hosts_permitidos"):
        assert not hasattr(config, opcion)
    for modulo in _RETIRADOS:
        assert importlib.util.find_spec(f"app.interfaz.{modulo}") is None
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr(config, "firebase_credenciales_json", "{}")
    monkeypatch.setattr(config, "firebase_project_id", "proyecto-real")
    crear_app()
    with TestClient(crear_app()) as cliente:
        assert cliente.get("/health", headers={"Host": "ajeno.example"}).status_code == 200


def test_el_contrato_no_anuncia_el_429_del_limite_ni_el_503() -> None:
    """el contrato no anuncia el 429 del límite de pedidos ni el 503, y sigue el 429 de Firebase al iniciar sesión @SIM-01-S1"""
    esquema = crear_app().openapi()
    assert "/metrics" not in esquema["paths"] and "/ready" not in esquema["paths"]
    assert "Frenado" not in esquema["components"]["schemas"]
    for ruta, operaciones in esquema["paths"].items():
        for metodo, operacion in operaciones.items():
            respuestas = operacion["responses"]
            assert "503" not in respuestas, (metodo, ruta)
            if (metodo, ruta) != ("put", "/yo/contrasena"):
                assert "429" not in respuestas, (metodo, ruta)
    assert "429" in esquema["paths"]["/yo/contrasena"]["put"]["responses"]


def test_docs_y_openapi_responden_con_la_configuracion_de_render() -> None:
    """/docs y /openapi.json responden también con la configuración de render.yaml, sin opción para apagarlos @SIM-01-S3"""
    render = (RAIZ_REPO / "render.yaml").read_text(encoding="utf-8")
    assert "DOCUMENTACION_INTERACTIVA" not in render
    assert "healthCheckPath: /health" in render
    for retirada in ("DATABASE_URL_APP", "METRICAS_TOKEN", "DETRAS_DE_PROXY"):
        assert retirada not in render
    assert not hasattr(config, "documentacion_interactiva")
    with TestClient(crear_app()) as cliente:
        assert cliente.get("/docs").status_code == 200
        assert cliente.get("/openapi.json").status_code == 200


def test_un_texto_largo_o_con_control_ya_no_se_rechaza_y_las_horas_siguen_de_1_a_4() -> None:
    """un texto largo o con caracteres de control ya no se rechaza y las horas siguen siendo de 1 a 4 @SIM-01-S1 @assumption:SIM-01-ASM-05"""
    from app.dominio.horarios import error_de_duracion
    from app.interfaz.entradas import leer_hora
    from app.interfaz.sedes import PedidoDeSede

    pedido = PedidoDeSede(nombre="x" * 500 + "\x00", direccion="y" * 500, apertura="08:00")
    assert len(pedido.nombre) == 501
    assert "maxLength" not in str(crear_app().openapi())
    assert leer_hora("08:00") is not None and leer_hora("8:00") is None
    assert error_de_duracion(0) and error_de_duracion(5)
    assert error_de_duracion(1) is None and error_de_duracion(4) is None


def test_no_quedan_scripts_avisos_de_terceros_ni_documentacion_de_lo_que_se_sacó() -> None:
    """no quedan scripts, avisos de terceros ni documentación de lo que se sacó @SIM-01-S2"""
    for ruta in (
        "apps/api/scripts/respaldo.py",
        "apps/api/scripts/usuario_de_la_app.py",
        "apps/api/scripts/avisos_de_terceros.py",
        "THIRD_PARTY_NOTICES.md",
    ):
        assert not (RAIZ_REPO / ruta).exists(), ruta
    docs = (
        "README.md",
        "apps/api/README.md",
        "docs/technical/runbook.md",
        "docs/technical/system-design.md",
        "docs/technical/arquitectura.md",
        "docs/technical/mapa-del-codigo.md",
    )
    retirado = ("/metrics", "METRICAS_TOKEN", "DATABASE_URL_APP", "DETRAS_DE_PROXY", "/ready")
    for doc in docs:
        texto = (RAIZ_REPO / doc).read_text(encoding="utf-8")
        for palabra in retirado:
            assert palabra not in texto, (doc, palabra)
