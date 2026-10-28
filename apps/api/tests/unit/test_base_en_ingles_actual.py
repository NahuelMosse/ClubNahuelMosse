"""La ruta de pruebas se reconoce con el FastAPI instalado, que anida los routers incluidos."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

RAIZ_API = Path(__file__).resolve().parents[2]


def test_el_contrato_la_salud_y_la_ruta_de_pruebas_responden_igual_que_en_main(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el contrato, la salud y la ruta de pruebas responden igual que en main @ENG-01-S3 @assumption:ENG-01-ASM-05"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr("app.shared.config.config.e2e_testing", True)
    from app import e2e_support
    from app.main import create_app

    app = create_app()
    esperado = json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n"
    publicado = (RAIZ_API / "openapi.json").read_text(encoding="utf-8")
    incluidos = [getattr(r, "original_router", None) for r in app.routes]
    salud = TestClient(app).get("/health")

    assert esperado == publicado
    assert salud.json() == {"estado": "vivo", "version": salud.json()["version"]}
    assert e2e_support.router in incluidos
