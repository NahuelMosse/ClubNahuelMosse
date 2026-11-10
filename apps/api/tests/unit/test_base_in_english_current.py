"""The test route is recognized with the installed FastAPI, which nests the included routers."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

API_ROOT = Path(__file__).resolve().parents[2]


def test_the_contract_health_and_test_route_answer_the_same_as_in_main(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the contract, health and test route answer the same as in main @ENG-01-S3 @assumption:ENG-01-ASM-05"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr("app.shared.config.config.e2e_testing", True)
    from app import e2e_support
    from app.main import create_app

    app = create_app()
    expected = json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n"
    published = (API_ROOT / "openapi.json").read_text(encoding="utf-8")
    included = [getattr(r, "original_router", None) for r in app.routes]
    health = TestClient(app).get("/health")

    assert expected == published
    assert health.json() == {"status": "ok", "version": health.json()["version"]}
    assert e2e_support.router in included
