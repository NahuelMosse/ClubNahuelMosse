from uuid import UUID

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from pydantic import BaseModel, TypeAdapter, ValidationError

from app.shared import input_validation
from app.shared.input_validation import Identifier


class _Request(BaseModel):
    name: str = ""
    cantidad: Identifier = UUID(int=1)


@pytest.fixture(scope="module")
def client() -> TestClient:
    app = FastAPI()
    input_validation.install(app)

    @app.post("/pedido")
    def request(p: _Request) -> dict[str, str]:
        return {"name": p.name}

    return TestClient(app)


@pytest.mark.parametrize("text", ["", "1", "no-es-un-uuid", "0123456789abcdef0123456789abcdeg"])
def test_a_malformed_identifier_does_not_pass(text: str) -> None:
    with pytest.raises(ValidationError):
        TypeAdapter(Identifier).validate_python(text)


def test_an_identifier_accepts_uppercase_and_no_hyphens() -> None:
    adapter = TypeAdapter(Identifier)
    expected = UUID("0197b5a2-7c3e-7a10-8f4d-1e2f3a4b5c6d")

    assert adapter.validate_python("0197B5A2-7C3E-7A10-8F4D-1E2F3A4B5C6D") == expected
    assert adapter.validate_python("0197b5a27c3e7a108f4d1e2f3a4b5c6d") == expected


def test_a_malformed_identifier_has_a_general_message(client: TestClient) -> None:
    r = client.post("/pedido", json={"cantidad": "1"})

    assert r.json() == {"errors": {"cantidad": "The value is not valid"}}


def test_a_value_of_another_type_has_a_general_message(client: TestClient) -> None:
    r = client.post("/pedido", json={"name": 5})

    assert r.json() == {"errors": {"name": "The value is not valid"}}


def test_broken_json_answers_400_without_repeating_it(client: TestClient) -> None:
    r = client.post(
        "/pedido", content='{"name": "clave-secreta', headers={"Content-Type": "application/json"}
    )

    assert r.status_code == 400
    assert r.json() == {"errors": {"body": "The body is not valid JSON"}}


def test_a_missing_body_answers_422(client: TestClient) -> None:
    r = client.post("/pedido")

    assert r.status_code == 422
    assert list(r.json()["errors"]) == ["body"]
