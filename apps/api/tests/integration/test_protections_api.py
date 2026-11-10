"""The security review of the API edge, tested against the real app."""

from collections.abc import Callable
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.shared.config import config


def test_broken_json_gives_400(api: TestClient) -> None:
    r = api.post("/register", content=b"{roto", headers={"content-type": "application/json"})
    assert r.status_code == 400


@pytest.mark.parametrize(
    "body",
    [b"[]", b'{"nombre": 12, "dni": {"a": 1}}', b'"texto"', b""],
)
def test_wrong_types_give_422(api: TestClient, body: bytes) -> None:
    r = api.post("/register", content=body, headers={"content-type": "application/json"})
    assert r.status_code == 422


def test_an_unknown_field_goes_nowhere(api: TestClient, unique: Callable[[], str]) -> None:
    s = unique()
    r = api.post(
        "/register",
        json={
            "first_name": "Ana",
            "last_name": "Pérez",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "2000-03-14",
            "email": f"rol.{s}@correo.com",
            "password": "ClubNahuel1",
            "role": "admin",
        },
    )
    assert r.status_code == 201
    # The role is not taken from the request: the new account is always a user.
    engine = create_engine(config.database_url)
    with engine.connect() as conn:
        role: Any = conn.execute(
            text("SELECT role FROM app_user WHERE email = :c"), {"c": f"rol.{s}@correo.com"}
        ).scalar_one()
    engine.dispose()
    assert role == "user"


def test_an_error_does_not_expose_internal_details(api: TestClient) -> None:
    r = api.post("/register", content=b"{roto", headers={"content-type": "application/json"})
    text_ = r.text.lower()
    for leak in ("traceback", "sqlalchemy", "psycopg", "firebase", 'file "'):
        assert leak not in text_
