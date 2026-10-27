"""Los dos tipos de Básquet: el alta compone el nombre y el filtro separa 3x3 de Básquet 5."""

from fastapi.testclient import TestClient

from test_basquet import _cancha, _con, sede, token_admin, token_usuario  # noqa: F401


def test_el_administrador_da_de_alta_una_cancha_de_basquet_3x3(
    api: TestClient,
    token_admin: str,
    sede: str,  # noqa: F811
) -> None:
    """el administrador da de alta una cancha de Básquet 3x3 con su nombre compuesto
    @REV-05-S2 @assumption:REV-05-ASM-01
    """
    r = api.post("/espacios", headers=_con(token_admin), json=_cancha(sede, "Basquet", "3X3"))

    assert r.status_code == 201
    assert r.json()["tipo"] == "3X3"
    assert r.json()["nombre"].endswith("_Basquet_3X3_1")


def test_el_socio_filtra_las_canchas_de_basquet_3x3_y_no_ve_las_de_basquet_5(
    api: TestClient,
    token_admin: str,
    token_usuario: str,
    sede: str,  # noqa: F811
) -> None:
    """el socio filtra las canchas de Básquet 3x3 y no ve las de Básquet 5
    @REV-05-S3 @assumption:REV-05-ASM-01
    """
    tres = api.post(
        "/espacios", headers=_con(token_admin), json=_cancha(sede, "Basquet", "3X3")
    ).json()
    cinco = api.post(
        "/espacios", headers=_con(token_admin), json=_cancha(sede, "Basquet", "B5")
    ).json()

    r = api.get(
        "/espacios",
        headers=_con(token_usuario),
        params={"sede_id": sede, "deporte": "Basquet", "tipo": "3X3"},
    )

    ids = [e["id"] for e in r.json()["espacios"]]
    assert tres["id"] in ids
    assert cinco["id"] not in ids
