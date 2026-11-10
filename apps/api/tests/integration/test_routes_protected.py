"""Every operation registered in the API, published in OpenAPI or not, requires a session except
the public ones."""

import re
from collections.abc import Iterator
from typing import Any

from fastapi import FastAPI
from fastapi.routing import APIRoute
from fastapi.testclient import TestClient

from app.main import create_app

# What the API serves without a session: account creation and password recovery, with the
# page of the email link.
PUBLIC = {
    ("POST", "/register"),
    ("POST", "/password-recovery"),
    ("POST", "/password-recovery/check"),
    ("PUT", "/password-recovery"),
    ("GET", "/link/recover"),
    ("GET", "/health"),
}
PROTECTED = 28


def _routes(app: FastAPI) -> Iterator[tuple[str, str]]:
    """Method and path of each operation, also those of a router included inside another."""
    yield from _routes_of(list(app.routes), "")


def _routes_of(groups: list[Any], prefix: str) -> Iterator[tuple[str, str]]:
    for group in groups:
        if isinstance(group, APIRoute):
            for method in group.methods or ():
                yield method, prefix + group.path
        elif (router := getattr(group, "original_router", None)) is not None:
            yield from _routes_of(list(router.routes), prefix + group.include_context.prefix)
        # /docs, /redoc and /openapi.json are not operations of the API.


def test_every_registered_route_outside_the_public_ones_rejects_without_a_session() -> None:
    """@REV-02-ASM-03"""
    app = create_app()
    operations = sorted(op for op in _routes(app) if op not in PUBLIC)
    accepted = []

    with TestClient(app) as client:
        for method, route in operations:
            url = re.sub(r"\{[^}]*\}", "1", route)
            r = client.request(method, url, json=None if method == "GET" else {})
            if r.status_code != 401:
                accepted.append((method, route, r.status_code))

    assert not accepted, accepted
    assert len(operations) == PROTECTED, len(operations)
