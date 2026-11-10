import json
import re
import tomllib
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.shared.errors import Forbidden, InvalidData, NotFound

API = Path(__file__).resolve().parents[2]
APP = API / "app"
MODULES = APP / "modules"
SHARED = APP / "shared"


def _code(files: list[Path]) -> dict[str, str]:
    return {a.relative_to(APP).as_posix(): a.read_text(encoding="utf-8") for a in sorted(files)}


def _sources(folder: Path) -> list[Path]:
    return [a for a in folder.rglob("*.py") if "__pycache__" not in a.parts]


def _data() -> dict[str, str]:
    """The files that talk to the database: the transactions one and the repositories."""
    return _code(
        [SHARED / "db.py", *MODULES.glob("*/repositorio.py"), *MODULES.glob("*/repository.py")]
    )


def test_no_route_catches_the_errors_that_are_answered_the_same_across_the_api() -> None:
    """no route catches the errors that are answered the same across the API
    @ARQ-02-S2 @assumption:ARQ-02-ASM-01"""
    common = re.compile(
        r"sin_permiso\(|no_encontrado\(|datos_invalidos\("
        r"|HTTP_403_FORBIDDEN\)|HTTP_404_NOT_FOUND\)"
        r'|HTTP_422_UNPROCESSABLE_CONTENT,\s*content=\{"errors": e\.errors\}'
    )
    routes = [a for a in _sources(MODULES) if a.name.startswith("routes")]
    assert routes
    found = [
        f"{name}: {m.group(0)}"
        for name, text in _code(routes).items()
        for m in common.finditer(text)
    ]
    assert found == []


@pytest.mark.parametrize(
    ("error", "code", "body"),
    [
        (
            InvalidData({"nombre": "Falta el nombre"}),
            422,
            b'{"errors":{"nombre":"Falta el nombre"}}',
        ),
        (Forbidden("no"), 403, b""),
        (NotFound(), 404, b""),
    ],
)
def test_each_common_domain_error_is_answered_with_its_code_and_its_body(
    error: Exception, code: int, body: bytes
) -> None:
    """invalid data answers 422 with its errors, forbidden 403 and not found 404, with no body
    @ARQ-02-S1 @assumption:ARQ-02-ASM-01"""
    app = create_app()

    def fails() -> None:
        raise error

    app.add_api_route("/falla", fails)

    response = TestClient(app, base_url="http://localhost").get("/falla")

    assert (response.status_code, response.content) == (code, body)


def test_the_published_contract_does_not_change() -> None:
    """the published contract does not change @ARQ-02-S3 @assumption:ARQ-02-ASM-04"""
    published = json.loads((API / "openapi.json").read_text(encoding="utf-8"))

    assert create_app().openapi() == published


def test_the_repositories_commit_and_roll_back_in_a_single_place() -> None:
    """the repositories commit and roll back in a single place @ARQ-02-S2"""
    code = _data()
    with_rollback = {n for n, t in code.items() if "except BaseException" in t}

    assert with_rollback == {"shared/db.py"}
    assert code["shared/db.py"].count("except BaseException") == 1


def test_the_club_zone_the_time_reader_and_the_identifier_are_defined_once() -> None:
    """the club zone, the time reader and the identifier are defined once @ARQ-02-S2"""
    code = _code(_sources(APP))
    everything = "\n".join(code.values())

    assert "timedelta(hours=-3)" not in everything
    assert len(re.findall(r"^def _?parse_time\(", everything, flags=re.MULTILINE)) == 1
    assert [n for n, t in code.items() if "Identifier = " in t] == ["shared/input_validation.py"]


def test_email_validator_is_no_longer_a_dependency_and_nobody_imports_it() -> None:
    """email-validator is no longer a dependency and nobody imports it @assumption:ARQ-02-ASM-03"""
    project = tomllib.loads((API / "pyproject.toml").read_text(encoding="utf-8"))
    dependencies = " ".join(project["project"]["dependencies"])

    assert "email-validator" not in dependencies
    assert not any("email_validator" in t for t in _code(_sources(APP)).values())
