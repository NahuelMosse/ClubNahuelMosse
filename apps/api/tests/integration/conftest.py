"""Test accounts and venues for the integration tests, against the database and the emulator."""

from collections.abc import Callable, Iterator

import pytest
from fastapi.testclient import TestClient

from app.modules.users.seed_admin import main as seed

PASSWORD = "ClubNahuel1"


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def admin_token(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> Iterator[str]:
    s = unique()
    monkeypatch.setenv("ADMIN_PASSWORD", PASSWORD)
    arguments = [
        "--email", f"admin.{s}@club.com", "--first-name", "Ana", "--last-name", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--birth-date", "1985-06-01",
    ]  # fmt: skip
    assert seed(arguments) == 0
    token = sign_in(f"admin.{s}@club.com", PASSWORD)
    assert token is not None
    yield token


@pytest.fixture
def user_token(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> str:
    s = unique()
    payload = {
        "first_name": "Martín",
        "last_name": "Ferreyra",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1994-07-21",
        "email": f"socio.{s}@correo.com",
        "password": PASSWORD,
    }
    assert api.post("/register", json=payload).status_code == 201
    token = sign_in(f"socio.{s}@correo.com", PASSWORD)
    assert token is not None
    return token


@pytest.fixture
def venue(api: TestClient, admin_token: str, unique: Callable[[], str]) -> tuple[str, str]:
    s = unique()
    r = api.post(
        "/venues",
        headers=_bearer(admin_token),
        json={
            "name": f"Sede Haedo {s}",
            "address": "Av. Vergara 1850",
            "opens_at": "08:00",
            "closes_at": "23:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    )
    assert r.status_code == 201
    # The compound name joins the words with an initial capital: «Haedo b489» → «HaedoB489».
    return r.json()["id"], f"Haedo{s[0].upper()}{s[1:]}_Vergara_1850"
