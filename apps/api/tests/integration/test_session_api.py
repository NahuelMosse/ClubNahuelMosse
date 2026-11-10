"""`GET /me` and the admin seeding against the real database and emulator."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.users.seed_admin import main as seed

PASSWORD = "ClubNahuel1"


def _register(api: TestClient, s: str) -> str:
    email = f"socia.{s}@correo.com"
    payload = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1998-11-02",
        "email": email,
        "password": PASSWORD,
    }
    assert api.post("/register", json=payload).status_code == 201
    return email


def _me(api: TestClient, token: str | None) -> tuple[int, dict[str, object]]:
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    r = api.get("/me", headers=headers)
    return r.status_code, r.json()


def test_with_the_account_token_it_returns_its_profile_and_role(
    api: TestClient, sign_in: Callable[[str, str], str | None], unique: Callable[[], str]
) -> None:
    email = _register(api, unique())
    code, body = _me(api, sign_in(email, PASSWORD))
    assert code == 200
    assert body == {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "email": email,
        "role": "user",
        "dni": body["dni"],
        "birth_date": "1998-11-02",
    }
    assert isinstance(body["dni"], str) and len(body["dni"]) == 8


@pytest.mark.parametrize("header", [None, "Bearer ", "Bearer basura", "Basic dXNlcjpwYXNz"])
def test_without_a_valid_token_there_is_no_session(api: TestClient, header: str | None) -> None:
    r = api.get("/me", headers={"Authorization": header} if header is not None else {})
    assert r.status_code == 401
    assert r.headers["www-authenticate"] == "Bearer"
    assert r.json() == {"detail": "Invalid or expired session"}


def test_a_deactivated_account_has_no_session_even_if_the_token_is_valid(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """Checks CU-01-SUP-05."""
    email = _register(api, unique())
    token = sign_in(email, PASSWORD)
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE app_user SET active = false, deactivated_at = now() WHERE email = :c"),
            {"c": email},
        )
    assert _me(api, token)[0] == 401


def test_an_account_disabled_in_firebase_has_no_session(
    api: TestClient, sign_in: Callable[[str, str], str | None], unique: Callable[[], str]
) -> None:
    from firebase_admin import auth

    from app.shared.identity import FirebaseProvider, _firebase_app

    email = _register(api, unique())
    token = sign_in(email, PASSWORD)
    uid = FirebaseProvider().uid_of(email)
    assert uid is not None
    auth.update_user(uid, disabled=True, app=_firebase_app())
    assert _me(api, token)[0] == 401


def test_the_seeding_creates_an_admin_who_signs_in_with_the_admin_role(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    s = unique()
    email = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", PASSWORD)
    arguments = [
        "--correo", email, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert seed(arguments) == 0
    # Seeding again does not duplicate: the account already exists and is only promoted if asked.
    assert seed(arguments) == 1
    assert seed([*arguments, "--promover"]) == 0
    code, body = _me(api, sign_in(email, PASSWORD))
    assert (code, body["role"]) == (200, "admin")


def test_the_seeding_does_not_promote_a_foreign_account_without_being_asked(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    email = _register(api, unique())
    monkeypatch.setenv("ADMIN_CONTRASENA", "OtraClave9")
    arguments = [
        "--correo", email, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", "30111224", "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert seed(arguments) == 1
    assert _me(api, sign_in(email, PASSWORD))[1]["role"] == "user"


def test_the_seeding_promotes_an_account_that_already_exists(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    email = _register(api, unique())
    monkeypatch.setenv("ADMIN_CONTRASENA", "OtraClave9")
    arguments = [
        "--correo", email.upper(), "--nombre", "Lucía", "--apellido", "Gómez",
        "--dni", "30111222", "--nacimiento", "1998-11-02", "--promover",
    ]  # fmt: skip
    assert seed(arguments) == 0
    # The account keeps its password: the seeding only changes its role.
    assert _me(api, sign_in(email, PASSWORD))[1]["role"] == "admin"


def test_the_seeding_without_a_password_touches_nothing(
    engine: Engine, unique: Callable[[], str], monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.delenv("ADMIN_CONTRASENA", raising=False)
    email = f"admin.{unique()}@club.com"
    arguments = [
        "--correo", email, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", "30111223", "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert seed(arguments) == 2
    with engine.connect() as conn:
        row = conn.execute(text("SELECT 1 FROM app_user WHERE email = :c"), {"c": email})
        assert row.first() is None
