"""Operations: version and configuration."""

import tomllib
from pathlib import Path

from fastapi.testclient import TestClient

from app.shared.config import Settings, config

API_ROOT = Path(__file__).resolve().parents[2]
VERSION = tomllib.loads((API_ROOT / "pyproject.toml").read_text(encoding="utf-8"))["project"][
    "version"
]


def test_the_version_lives_in_pyproject_and_the_api_exposes_it(api: TestClient) -> None:
    """the version lives in pyproject.toml and the API exposes it @REV-02-S14 @assumption:REV-02-ASM-09"""
    health = api.get("/health").json()

    assert health["version"] == VERSION
    assert config.version == VERSION


def test_the_version_lives_in_one_place_and_the_api_exposes_it(api: TestClient) -> None:
    """the version lives in one place and the API exposes it @REV-02-S14"""
    contract = api.get("/openapi.json").json()

    assert contract["info"]["version"] == VERSION
    assert VERSION not in (API_ROOT / "app" / "main.py").read_text(encoding="utf-8")


def test_the_configuration_is_read_the_same_from_any_folder() -> None:
    """the configuration is read the same from any start folder @REV-02-S15"""
    file = Path(str(Settings.model_config.get("env_file")))

    assert file.is_absolute()
    assert file == API_ROOT / ".env"
