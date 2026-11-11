"""Basketball in the sports catalog: it is offered, created and filtered."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient

from app.modules.users.seed_admin import main as seed_admin

PASSWORD = "ClubNahuel1"


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def user_token(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> str:
    s = unique()
    signup = api.post(
        "/register",
        json={
            "first_name": "Martín",
            "last_name": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1994-07-21",
            "email": f"socio.{s}@correo.com",
            "password": PASSWORD,
        },
    )
    assert signup.status_code == 201
    token = sign_in(f"socio.{s}@correo.com", PASSWORD)
    assert token is not None
    return token


@pytest.fixture
def admin_token(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> str:
    s = unique()
    monkeypatch.setenv("ADMIN_PASSWORD", PASSWORD)
    args = [
        "--email", f"admin.{s}@club.com", "--first-name", "Ana", "--last-name", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--birth-date", "1985-06-01",
    ]  # fmt: skip
    assert seed_admin(args) == 0
    token = sign_in(f"admin.{s}@club.com", PASSWORD)
    assert token is not None
    return token


@pytest.fixture
def venue(api: TestClient, admin_token: str, unique: Callable[[], str]) -> str:
    r = api.post(
        "/venues",
        headers=_bearer(admin_token),
        json={
            "name": f"Sede Castelar {unique()}",
            "address": "Av. Santa Rosa 1200",
            "opens_at": "08:00",
            "closes_at": "23:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    )
    assert r.status_code == 201
    return str(r.json()["id"])


def _court(venue: str, sport: str, kind: str) -> dict[str, object]:
    return {
        "venue_id": venue,
        "sport": sport,
        "kind": kind,
        "covered": True,
        "lit": True,
        "price_per_hour": 30000,
    }


def test_the_catalog_offers_basketball_with_its_kind(api: TestClient, user_token: str) -> None:
    """the sports catalog offers Basketball with its court kind
    @REV-05-S1 @assumption:REV-05-ASM-01 @assumption:REV-05-ASM-03
    """
    catalog = api.get("/spaces/catalog", headers=_bearer(user_token)).json()
    keys = [d["key"] for d in catalog["sports"]]

    assert keys.index("Basquet") == keys.index("Voley") + 1

    basketball = next((d for d in catalog["sports"] if d["key"] == "Basquet"), None)
    assert basketball == {
        "key": "Basquet",
        "name": "Basketball",
        "kinds": [
            {"key": "B5", "name": "Basketball 5"},
            {"key": "3X3", "name": "Basketball 3x3"},
        ],
    }


def test_the_admin_creates_a_basketball_court(
    api: TestClient, admin_token: str, venue: str
) -> None:
    """the admin creates a Basketball court @REV-05-S2"""
    r = api.post("/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "B5"))

    assert r.status_code == 201
    assert r.json()["sport"] == "Basquet"
    assert r.json()["name"].endswith("_Basquet_B5_1")


def test_a_kind_from_another_sport_is_not_valid_for_basketball(
    api: TestClient, admin_token: str, venue: str
) -> None:
    """a kind that does not belong to Basketball is rejected @REV-05-S2"""
    r = api.post("/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "F5"))

    assert r.status_code == 422
    assert r.json()["errors"]["kind"] == "Choose a kind from the list"


def test_the_member_filters_spaces_by_basketball(
    api: TestClient, admin_token: str, user_token: str, venue: str
) -> None:
    """the member filters spaces by Basketball @REV-05-S3"""
    basketball = api.post(
        "/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "3X3")
    ).json()
    football = api.post(
        "/spaces", headers=_bearer(admin_token), json=_court(venue, "Futbol", "F5")
    ).json()

    r = api.get(
        "/spaces", headers=_bearer(user_token), params={"venue_id": venue, "sport": "Basquet"}
    )

    ids = [e["id"] for e in r.json()["spaces"]]
    assert basketball["id"] in ids
    assert football["id"] not in ids
