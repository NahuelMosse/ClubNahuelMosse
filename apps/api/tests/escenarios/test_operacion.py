"""Operación: versión y configuración."""

import tomllib
from pathlib import Path

from fastapi.testclient import TestClient

from app.shared.config import Config, config

RAIZ_API = Path(__file__).resolve().parents[2]
VERSION = tomllib.loads((RAIZ_API / "pyproject.toml").read_text(encoding="utf-8"))["project"][
    "version"
]


def test_la_version_vive_en_pyproject_y_la_api_la_expone(api: TestClient) -> None:
    """la versión vive en pyproject.toml y la API la expone @REV-02-S14 @assumption:REV-02-ASM-09"""
    salud = api.get("/health").json()

    assert salud["version"] == VERSION
    assert config.version == VERSION


def test_la_version_vive_en_un_solo_lugar_y_la_api_la_expone(api: TestClient) -> None:
    """la versión vive en un solo lugar y la API la expone @REV-02-S14"""
    contrato = api.get("/openapi.json").json()

    assert contrato["info"]["version"] == VERSION
    assert VERSION not in (RAIZ_API / "app" / "main.py").read_text(encoding="utf-8")


def test_la_configuracion_se_lee_igual_desde_cualquier_carpeta() -> None:
    """la configuración se lee igual desde cualquier carpeta de arranque @REV-02-S15"""
    archivo = Path(str(Config.model_config.get("env_file")))

    assert archivo.is_absolute()
    assert archivo == RAIZ_API / ".env"
