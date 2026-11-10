"""SIM-01: the API without what the production grade added and a TP does not ask for."""

import importlib.util
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.shared.config import config

API_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = API_ROOT.parents[1]
_REMOVED = ("limites", "metricas", "protecciones", "registro_errores", "marcador")


def test_the_api_publishes_no_metrics_nor_limits_requests_nor_adds_headers() -> None:
    """the API publishes no metrics, does not limit requests and adds no security headers, request id or /ready @SIM-01-S1"""
    with TestClient(create_app()) as client:
        assert client.get("/metrics").status_code == 404
        assert client.get("/ready").status_code == 404
        health = client.get("/health")
        assert health.status_code == 200
        assert "content-security-policy" not in health.headers
        assert "x-request-id" not in health.headers
        statuses = {client.post("/registro", json={}).status_code for _ in range(120)}
    assert 429 not in statuses


def test_an_unforeseen_error_answers_500_without_its_own_body() -> None:
    """an unforeseen error answers 500 without its own body @SIM-01-S1 @assumption:SIM-01-ASM-03"""
    app = create_app()

    @app.get("/_explota")
    def explode() -> None:
        raise RuntimeError("fails")

    with TestClient(app, raise_server_exceptions=False) as client:
        r = client.get("/_explota")
    assert r.status_code == 500
    assert r.text == "Internal Server Error"
    assert "x-request-id" not in r.headers


def test_prometheus_client_is_no_longer_a_dependency() -> None:
    """prometheus-client is no longer a dependency @SIM-01-S2"""
    for file in ("pyproject.toml", "uv.lock"):
        assert "prometheus" not in (API_ROOT / file).read_text(encoding="utf-8").lower()


def test_there_are_no_timeouts_emulator_check_host_filter_nor_json_logs(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the API has no database timeouts, emulator check, Host filter or JSON logs @SIM-01-S1"""
    from app.shared import db

    for name in ("base_disponible", "esquema_al_dia", "uso_del_pool", "POOL_MAXIMO"):
        assert not hasattr(db, name)
    for option in ("database_url_app", "metricas_token", "detras_de_proxy", "hosts_permitidos"):
        assert not hasattr(config, option)
    for module in _REMOVED:
        assert importlib.util.find_spec(f"app.shared.{module}") is None
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr(config, "firebase_credentials_json", "{}")
    monkeypatch.setattr(config, "firebase_project_id", "proyecto-real")
    create_app()
    with TestClient(create_app()) as client:
        assert client.get("/health", headers={"Host": "ajeno.example"}).status_code == 200


def test_the_contract_does_not_advertise_the_limit_429_nor_the_503() -> None:
    """the contract does not advertise the request-limit 429 nor the 503, and keeps the Firebase 429 on sign-in @SIM-01-S1"""
    schema = create_app().openapi()
    assert "/metrics" not in schema["paths"] and "/ready" not in schema["paths"]
    assert "Frenado" not in schema["components"]["schemas"]
    for route, operations in schema["paths"].items():
        for method, operation in operations.items():
            responses = operation["responses"]
            assert "503" not in responses, (method, route)
            if (method, route) != ("put", "/me/password"):
                assert "429" not in responses, (method, route)
    assert "429" in schema["paths"]["/me/password"]["put"]["responses"]


def test_docs_and_openapi_respond_with_the_render_configuration() -> None:
    """/docs and /openapi.json also respond with the render.yaml configuration, with no option to turn them off @SIM-01-S3"""
    render = (REPO_ROOT / "render.yaml").read_text(encoding="utf-8")
    assert "DOCUMENTACION_INTERACTIVA" not in render
    assert "healthCheckPath: /health" in render
    for removed in ("DATABASE_URL_APP", "METRICAS_TOKEN", "DETRAS_DE_PROXY"):
        assert removed not in render
    removed_setting = "documentacion_interactiva"
    assert not hasattr(config, removed_setting)
    with TestClient(create_app()) as client:
        assert client.get("/docs").status_code == 200
        assert client.get("/openapi.json").status_code == 200


def test_a_long_text_or_one_with_control_characters_is_no_longer_rejected_and_hours_stay_1_to_4() -> (
    None
):
    """a long text or one with control characters is no longer rejected and the hours stay 1 to 4 @SIM-01-S1 @assumption:SIM-01-ASM-05"""
    from app.modules.availability.rules import duration_error
    from app.modules.venues.routes import VenueRequest
    from app.shared.input_validation import parse_time

    request = VenueRequest(name="x" * 500 + "\x00", address="y" * 500, opens_at="08:00")
    assert len(request.name) == 501
    assert "maxLength" not in str(create_app().openapi())
    assert parse_time("08:00") is not None and parse_time("8:00") is None
    assert duration_error(0) and duration_error(5)
    assert duration_error(1) is None and duration_error(4) is None


def test_no_scripts_third_party_notices_or_documentation_of_what_was_removed_remain() -> None:
    """no scripts, third-party notices or documentation of what was removed remain @SIM-01-S2"""
    for path in (
        "apps/api/scripts/respaldo.py",
        "apps/api/scripts/usuario_de_la_app.py",
        "apps/api/scripts/avisos_de_terceros.py",
        "THIRD_PARTY_NOTICES.md",
    ):
        assert not (REPO_ROOT / path).exists(), path
    docs = (
        "README.md",
        "apps/api/README.md",
        "docs/technical/runbook.md",
        "docs/technical/system-design.md",
        "docs/technical/architecture.md",
        "docs/technical/code-map.md",
    )
    removed = ("/metrics", "METRICAS_TOKEN", "DATABASE_URL_APP", "DETRAS_DE_PROXY", "/ready")
    for doc in docs:
        text = (REPO_ROOT / doc).read_text(encoding="utf-8")
        for word in removed:
            assert word not in text, (doc, word)
