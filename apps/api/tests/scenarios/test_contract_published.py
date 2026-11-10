"""RNF-01 tested against the contract the API publishes, without reading the app code."""

import json
import re
from pathlib import Path
from typing import Any

from fastapi.testclient import TestClient

API_ROOT = Path(__file__).resolve().parents[2]
METHODS = {"get", "post", "put", "delete", "patch"}

# What the API serves without a session: account signup and password recovery (with the page of the email link).
PUBLIC = {
    ("post", "/register"),
    ("post", "/password-recovery"),
    ("post", "/password-recovery/check"),
    ("put", "/password-recovery"),
    ("get", "/link/recover"),
    ("get", "/health"),
}


def _operations(schema: dict[str, Any]) -> set[tuple[str, str]]:
    return {
        (method, route)
        for route, ops in schema["paths"].items()
        for method in ops
        if method in METHODS
    }


def test_the_api_publishes_openapi_with_all_the_contract_endpoints(api: TestClient) -> None:
    """the API publishes its OpenAPI documentation with all the contract endpoints the app uses @RNF-01-H04-01"""
    published = api.get("/openapi.json")
    versioned = json.loads((API_ROOT / "openapi.json").read_text(encoding="utf-8"))
    docs = api.get("/docs")

    assert published.status_code == 200
    assert _operations(published.json()) == _operations(versioned)
    assert len(_operations(versioned)) >= 30
    assert _operations(versioned) >= PUBLIC
    assert docs.status_code == 200
    assert "swagger" in docs.text.lower()


def test_every_api_operation_without_a_user_is_rejected_with_401(api: TestClient) -> None:
    """an operation on users or bookings without an authenticated user is rejected with 401 @RNF-01-H06-02 @assumption:RNF-01-SUP-01"""
    schema: dict[str, Any] = api.get("/openapi.json").json()
    protected = sorted(_operations(schema) - PUBLIC)
    accepted = []

    for method, route in protected:
        url = re.sub(r"\{[^}]*\}", "1", route)
        r = api.request(method.upper(), url, json={} if method != "get" else None)
        if r.status_code != 401:
            accepted.append((method, route, r.status_code))

    assert not accepted, accepted
    assert len(protected) >= 28
    fake_token = {"Authorization": "Bearer no-es-un-token"}
    assert api.get("/bookings", headers=fake_token).status_code == 401
    assert api.get("/me", headers=fake_token).status_code == 401


def test_rnf_01_h04_01_is_tested_with_the_published_contract_and_not_by_reading_the_readme(
    api: TestClient,
) -> None:
    """RNF-01-H04-01 is tested with the published contract and not by reading the README @REV-08-S4 @assumption:REV-08-ASM-08"""
    contract = api.get("/openapi.json")

    assert contract.status_code == 200
    assert len(contract.json()["paths"]) >= 20
    assert "swagger" in api.get("/docs").text.lower()
