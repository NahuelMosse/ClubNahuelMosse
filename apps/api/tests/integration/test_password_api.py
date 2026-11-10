"""`PUT /me/password` against the real database and emulator."""

import time
from collections.abc import Callable

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

CURRENT = "ClubNahuel1"
NEW = "ClubNahuel2"


def _register(api: TestClient, s: str) -> str:
    email = f"socia.{s}@correo.com"
    payload = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1998-11-02",
        "email": email,
        "password": CURRENT,
    }
    assert api.post("/register", json=payload).status_code == 201
    return email


def _change(api: TestClient, token: str | None, current: str, new: str) -> tuple[int, str]:
    r = api.put(
        "/me/password",
        headers={"Authorization": f"Bearer {token}"},
        json={"current_password": current, "new_password": new},
    )
    return r.status_code, r.text


def test_changing_the_password_leaves_a_trace_and_invalidates_the_sessions(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    email = _register(api, unique())
    token = sign_in(email, CURRENT)
    # Firebase revocation counts in seconds: the token has to be from before.
    time.sleep(1.1)

    assert _change(api, token, CURRENT, NEW) == (204, "")

    assert sign_in(email, CURRENT) is None
    fresh = sign_in(email, NEW)
    assert fresh is not None
    # The session that changed the password also expired; the new one signs in.
    assert api.get("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401
    assert api.get("/me", headers={"Authorization": f"Bearer {fresh}"}).status_code == 200
    with engine.connect() as conn:
        changed = conn.execute(
            text("SELECT password_changed_at FROM app_user WHERE email = :c"), {"c": email}
        ).scalar()
    assert changed is not None


def test_a_wrong_current_password_changes_nothing(
    api: TestClient, sign_in: Callable[[str, str], str | None], unique: Callable[[], str]
) -> None:
    email = _register(api, unique())
    token = sign_in(email, CURRENT)
    code, body = _change(api, token, "OtraClave9", NEW)
    assert code == 422
    assert '"current_password":"The current password does not match"' in body
    assert sign_in(email, CURRENT) is not None


def test_a_weak_new_password_is_rejected_with_the_missing_rule(
    api: TestClient, sign_in: Callable[[str, str], str | None], unique: Callable[[], str]
) -> None:
    email = _register(api, unique())
    token = sign_in(email, CURRENT)
    code, body = _change(api, token, CURRENT, "ClubNahuel")
    assert code == 422
    assert '"new_password":"At least one number"' in body
    assert sign_in(email, CURRENT) is not None


def test_without_a_session_it_cannot_be_changed(api: TestClient) -> None:
    assert _change(api, "basura", CURRENT, NEW)[0] == 401
