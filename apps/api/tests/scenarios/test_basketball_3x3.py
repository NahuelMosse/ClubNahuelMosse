"""The two Basketball kinds: creation composes the name and the filter separates 3x3 from Basketball 5."""

from fastapi.testclient import TestClient

from test_basketball import _court, _bearer, venue, admin_token, user_token  # noqa: F401


def test_the_admin_creates_a_basketball_3x3_court(
    api: TestClient,
    admin_token: str,
    venue: str,  # noqa: F811
) -> None:
    """the admin creates a Basketball 3x3 court with its composed name
    @REV-05-S2 @assumption:REV-05-ASM-01
    """
    r = api.post("/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "3X3"))

    assert r.status_code == 201
    assert r.json()["kind"] == "3X3"
    assert r.json()["name"].endswith("_Basquet_3X3_1")


def test_the_member_filters_basketball_3x3_courts_and_does_not_see_the_basketball_5_ones(
    api: TestClient,
    admin_token: str,
    user_token: str,
    venue: str,  # noqa: F811
) -> None:
    """the member filters Basketball 3x3 courts and does not see the Basketball 5 ones
    @REV-05-S3 @assumption:REV-05-ASM-01
    """
    three = api.post(
        "/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "3X3")
    ).json()
    five = api.post(
        "/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "B5")
    ).json()

    r = api.get(
        "/spaces",
        headers=_bearer(user_token),
        params={"venue_id": venue, "sport": "Basquet", "kind": "3X3"},
    )

    ids = [e["id"] for e in r.json()["spaces"]]
    assert three["id"] in ids
    assert five["id"] not in ids
