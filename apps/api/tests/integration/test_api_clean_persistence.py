"""What a repository commits stays in the database for another connection, as after a restart."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.main import create_app
from app.modules.users.seed_admin import main as seed

PASSWORD = "ClubNahuel1"


def test_a_created_venue_survives_restarting_the_api_on_the_same_database(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    engine: Engine,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """a created venue survives restarting the API on the same database @ARQ-02-S2"""
    s = unique()
    email = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_PASSWORD", PASSWORD)
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    arguments = ["--email", email, "--first-name", "Ana", "--last-name", "Díaz",
                 "--dni", dni, "--birth-date", "1985-06-01"]  # fmt: skip
    assert seed(arguments) == 0
    token = sign_in(email, PASSWORD)
    assert token is not None
    venue = {
        "name": f"Sede {s}",
        "address": "Calle 1",
        "opens_at": "08:00",
        "closes_at": "23:00",
        "open_days": [1, 2, 3, 4, 5],
    }

    created = TestClient(create_app(), base_url="http://localhost").post(
        "/venues", json=venue, headers={"Authorization": f"Bearer {token}"}
    )
    assert created.status_code == 201

    with engine.connect() as other:
        saved = other.execute(
            text("SELECT name FROM venue WHERE id = :id"), {"id": created.json()["id"]}
        ).scalar_one()
    assert saved == venue["name"]
    other_api = TestClient(create_app(), base_url="http://localhost")
    listing = other_api.get("/venues", headers={"Authorization": f"Bearer {token}"}).json()
    assert venue["name"] in [x["name"] for x in listing["venues"]]
