"""RNF-01-H06-02 on the published contract: /health is public (REV-01-ASM-07)."""

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


def test_every_api_operation_without_a_user_except_the_public_ones_is_rejected_with_401(
    api: TestClient,
) -> None:
    """an operation on users or bookings without an authenticated user is rejected with 401 @RNF-01-H06-02 @assumption:RNF-01-SUP-01 @REV-02-ASM-03 @INT-01-S1"""
    schema: dict[str, Any] = api.get("/openapi.json").json()
    operations = {
        (method, route)
        for route, ops in schema["paths"].items()
        for method in ops
        if method in METHODS
    }
    protected = sorted(operations - PUBLIC)
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
