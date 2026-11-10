"""DAT-01: the API receives and returns ids as UUID text."""

# ruff: noqa: E501  (test titles carry their tag and are not split)
import re
import uuid

import pytest
from fastapi.testclient import TestClient

UUID_V7 = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _space(venue_id: str) -> dict[str, object]:
    return {
        "venue_id": venue_id,
        "sport": "Futbol",
        "kind": "F5",
        "covered": False,
        "lit": True,
        "price_per_hour": 38000,
    }


@pytest.fixture
def space_id(api: TestClient, admin_token: str, venue: tuple[str, str]) -> str:
    r = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue[0]))
    assert r.status_code == 201, r.text
    id_ = r.json()["id"]
    assert isinstance(id_, str)
    return id_


def test_the_api_returns_and_receives_ids_as_uuid_text(
    api: TestClient, admin_token: str, venue: tuple[str, str], space_id: str
) -> None:
    """the API returns and receives ids as UUID text in paths, bodies and queries @DAT-01-S3"""
    venue_id = venue[0]

    assert UUID_V7.match(venue_id)
    assert UUID_V7.match(space_id)
    listing = api.get("/spaces", headers=_bearer(admin_token), params={"venue_id": venue_id})
    assert listing.status_code == 200
    assert space_id in [e["id"] for e in listing.json()["spaces"]]
    slots = api.get(f"/spaces/{space_id}/slots", headers=_bearer(admin_token))
    assert slots.status_code == 200, slots.text


def test_a_malformed_id_answers_422_and_one_that_does_not_exist_404(
    api: TestClient, admin_token: str, venue: tuple[str, str]
) -> None:
    """a malformed id in the path, the body or the query answers 422 and a UUID that does not exist answers 404 @DAT-01-S3"""
    admin = _bearer(admin_token)
    missing = str(uuid.uuid4())

    assert api.put("/venues/no-es-un-uuid", headers=admin, json={}).status_code == 422
    assert api.post("/spaces", headers=admin, json=_space("no-es-un-uuid")).status_code == 422
    assert (
        api.get("/spaces", headers=admin, params={"venue_id": "no-es-un-uuid"}).status_code == 422
    )
    assert api.delete(f"/spaces/{missing}", headers=admin).status_code == 404
    assert api.delete(f"/venues/{missing}", headers=admin).status_code == 404


def test_an_uppercase_or_hyphenless_uuid_is_accepted(
    api: TestClient, admin_token: str, space_id: str
) -> None:
    """an uppercase or hyphenless UUID is accepted and the response returns it lowercase with hyphens @assumption:DAT-01-ASM-06"""
    admin = _bearer(admin_token)

    for written in (space_id.upper(), space_id.replace("-", "")):
        r = api.put(f"/spaces/{written}", headers=admin, json={"price_per_hour": 40000})
        assert r.status_code == 200, r.text
        assert r.json()["id"] == space_id


def test_an_unsupported_method_answers_405_even_if_the_id_is_malformed(
    api: TestClient, admin_token: str
) -> None:
    """an unsupported method answers 405 even if the id is malformed @assumption:DAT-01-ASM-08"""
    assert api.patch("/venues/no-es-un-uuid", headers=_bearer(admin_token)).status_code == 405
