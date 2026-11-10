"""Replaces the scenario H06-02 of test_non_functional_requirements: /health is public (REV-01-ASM-07)."""

import re
from typing import Any

from fastapi.testclient import TestClient

METHODS = {"get", "post", "put", "delete", "patch"}
PUBLIC = {
    ("post", "/register"),
    ("post", "/password-recovery"),
    ("post", "/password-recovery/check"),
    ("put", "/password-recovery"),
    ("get", "/link/recover"),
    ("get", "/health"),
}


def test_every_api_operation_without_an_authenticated_user_is_rejected(api: TestClient) -> None:
    """an operation on users or bookings without an authenticated user is rejected @RNF-01-H06-02 @assumption:RNF-01-SUP-01"""
    schema: dict[str, Any] = api.get("/openapi.json").json()
    accepted = []
    rejected = 0

    for route, ops in schema["paths"].items():
        for method in ops:
            if method not in METHODS or (method, route) in PUBLIC:
                continue
            url = re.sub(r"\{[^}]*\}", "1", route)
            r = api.request(method.upper(), url, json={} if method != "get" else None)
            if r.status_code == 401:
                rejected += 1
            else:
                accepted.append((method, route, r.status_code))

    assert not accepted, accepted
    assert rejected >= 25
    fake_token = {"Authorization": "Bearer no-es-un-token"}
    assert api.get("/bookings", headers=fake_token).status_code == 401
    assert api.get("/me", headers=fake_token).status_code == 401
