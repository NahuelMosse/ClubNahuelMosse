"""`PUT /me` against the real database and emulator."""

from collections.abc import Callable
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

PASSWORD = "ClubNahuel1"


def _register(api: TestClient, s: str, dni: str | None = None) -> tuple[str, str]:
    email = f"socia.{s}@correo.com"
    dni = dni or str(int(s, 16) % 90_000_000 + 10_000_000)
    payload = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": dni,
        "birth_date": "1998-11-02",
        "email": email,
        "password": PASSWORD,
    }
    assert api.post("/register", json=payload).status_code == 201
    return email, dni


def _edit(api: TestClient, token: str | None, **data: str) -> tuple[int, dict[str, Any]]:
    r = api.put("/me", headers={"Authorization": f"Bearer {token}"}, json=data)
    return r.status_code, r.json()


def test_saves_the_personal_data_and_returns_the_new_profile(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    email, _ = _register(api, unique())
    token = sign_in(email, PASSWORD)
    code, body = _edit(
        api,
        token,
        first_name=" Lucía Inés ",
        last_name="Gómez Paz",
        dni="30.111.225",
        birth_date="1998-11-03",
    )
    assert code == 200
    assert body == {
        "first_name": "Lucía Inés",
        "last_name": "Gómez Paz",
        "email": email,
        "role": "user",
        "dni": "30111225",
        "birth_date": "1998-11-03",
    }
    with engine.connect() as conn:
        created, modified = conn.execute(
            text("SELECT created_at, updated_at FROM app_user WHERE email = :c"), {"c": email}
        ).one()
    # The database stamps the trace of the modification.
    assert modified > created


def test_the_email_is_not_changed_even_if_sent(
    api: TestClient, sign_in: Callable[[str, str], str | None], unique: Callable[[], str]
) -> None:
    email, dni = _register(api, unique())
    token = sign_in(email, PASSWORD)
    code, body = _edit(
        api,
        token,
        first_name="Lucía",
        last_name="Gómez",
        dni=dni,
        birth_date="1998-11-02",
        email="otra@correo.com",
    )
    assert (code, body["email"]) == (200, email)


def test_invalid_data_saves_nothing(
    api: TestClient, sign_in: Callable[[str, str], str | None], unique: Callable[[], str]
) -> None:
    email, _ = _register(api, unique())
    token = sign_in(email, PASSWORD)
    code, body = _edit(
        api, token, first_name="Otra", last_name="", dni="42118", birth_date="2000-13-32"
    )
    assert code == 422
    assert set(body["errors"]) == {"last_name", "dni", "birth_date"}
    assert (
        api.get("/me", headers={"Authorization": f"Bearer {token}"}).json()["first_name"] == "Lucía"
    )


def test_a_dni_of_another_account_is_rejected(
    api: TestClient, sign_in: Callable[[str, str], str | None], unique: Callable[[], str]
) -> None:
    """Checks CU-06-SUP-02."""
    _, foreign = _register(api, unique())
    email, _ = _register(api, unique())
    token = sign_in(email, PASSWORD)
    code, body = _edit(
        api, token, first_name="Lucía", last_name="Gómez", dni=foreign, birth_date="1998-11-02"
    )
    assert (code, body) == (409, {"errors": {"dni": "This DNI is already registered"}})


def test_without_a_session_it_is_not_edited(api: TestClient) -> None:
    assert api.put("/me", json={"name": "X"}).status_code == 401
