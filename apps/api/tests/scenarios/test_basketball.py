"""Básquet en el catálogo de deportes: se ofrece, se da de alta y se filtra."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient

from app.modules.users.seed_admin import main as sembrar

CONTRASENA = "ClubNahuel1"


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def user_token(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> str:
    s = unique()
    alta = api.post(
        "/register",
        json={
            "first_name": "Martín",
            "last_name": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1994-07-21",
            "email": f"socio.{s}@correo.com",
            "password": CONTRASENA,
        },
    )
    assert alta.status_code == 201
    token = sign_in(f"socio.{s}@correo.com", CONTRASENA)
    assert token is not None
    return token


@pytest.fixture
def admin_token(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> str:
    s = unique()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = sign_in(f"admin.{s}@club.com", CONTRASENA)
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


def _court(venue: str, deporte: str, tipo: str) -> dict[str, object]:
    return {
        "venue_id": venue,
        "sport": deporte,
        "kind": tipo,
        "covered": True,
        "lit": True,
        "price_per_hour": 30000,
    }


def test_el_catalogo_ofrece_basquet_con_su_tipo(api: TestClient, user_token: str) -> None:
    """el catálogo de deportes ofrece Básquet con su tipo de cancha
    @REV-05-S1 @assumption:REV-05-ASM-01 @assumption:REV-05-ASM-03
    """
    catalogo = api.get("/spaces/catalog", headers=_bearer(user_token)).json()
    claves = [d["key"] for d in catalogo["sports"]]

    assert claves.index("Basquet") == claves.index("Voley") + 1

    basquet = next((d for d in catalogo["sports"] if d["key"] == "Basquet"), None)
    assert basquet == {
        "key": "Basquet",
        "name": "Basketball",
        "kinds": [
            {"key": "B5", "name": "Basketball 5"},
            {"key": "3X3", "name": "Basketball 3x3"},
        ],
    }


def test_el_administrador_da_de_alta_una_cancha_de_basquet(
    api: TestClient, admin_token: str, venue: str
) -> None:
    """el administrador da de alta una cancha de Básquet @REV-05-S2"""
    r = api.post("/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "B5"))

    assert r.status_code == 201
    assert r.json()["sport"] == "Basquet"
    assert r.json()["name"].endswith("_Basquet_B5_1")


def test_un_tipo_de_otro_deporte_no_sirve_para_basquet(
    api: TestClient, admin_token: str, venue: str
) -> None:
    """un tipo que no es de Básquet se rechaza @REV-05-S2"""
    r = api.post("/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "F5"))

    assert r.status_code == 422
    assert r.json()["errors"]["kind"] == "Choose a kind from the list"


def test_el_socio_filtra_los_espacios_por_basquet(
    api: TestClient, admin_token: str, user_token: str, venue: str
) -> None:
    """el socio filtra los espacios por Básquet @REV-05-S3"""
    basquet = api.post(
        "/spaces", headers=_bearer(admin_token), json=_court(venue, "Basquet", "3X3")
    ).json()
    futbol = api.post(
        "/spaces", headers=_bearer(admin_token), json=_court(venue, "Futbol", "F5")
    ).json()

    r = api.get(
        "/spaces", headers=_bearer(user_token), params={"venue_id": venue, "sport": "Basquet"}
    )

    ids = [e["id"] for e in r.json()["spaces"]]
    assert basquet["id"] in ids
    assert futbol["id"] not in ids
