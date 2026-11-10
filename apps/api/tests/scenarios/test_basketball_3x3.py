"""Los dos tipos de Básquet: el alta compone el nombre y el filtro separa 3x3 de Básquet 5."""

from fastapi.testclient import TestClient

from test_basketball import _court, _bearer, venue, admin_token, user_token  # noqa: F401


def test_el_administrador_da_de_alta_una_cancha_de_basquet_3x3(
    api: TestClient,
    admin_token: str,
    venue: str,  # noqa: F811
) -> None:
    """el administrador da de alta una cancha de Básquet 3x3 con su nombre compuesto
    @REV-05-S2 @assumption:REV-05-ASM-01
    """
    r = api.post("/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "3X3"))

    assert r.status_code == 201
    assert r.json()["kind"] == "3X3"
    assert r.json()["name"].endswith("_Basquet_3X3_1")


def test_el_socio_filtra_las_canchas_de_basquet_3x3_y_no_ve_las_de_basquet_5(
    api: TestClient,
    admin_token: str,
    user_token: str,
    venue: str,  # noqa: F811
) -> None:
    """el socio filtra las canchas de Básquet 3x3 y no ve las de Básquet 5
    @REV-05-S3 @assumption:REV-05-ASM-01
    """
    tres = api.post(
        "/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "3X3")
    ).json()
    cinco = api.post(
        "/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "B5")
    ).json()

    r = api.get(
        "/spaces",
        headers=_bearer(user_token),
        params={"venue_id": venue, "sport": "Basquet", "kind": "3X3"},
    )

    ids = [e["id"] for e in r.json()["spaces"]]
    assert tres["id"] in ids
    assert cinco["id"] not in ids
