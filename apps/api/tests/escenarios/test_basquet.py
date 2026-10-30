"""Básquet en el catálogo de deportes: se ofrece, se da de alta y se filtra."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient

from app.modules.users.seed_admin import main as sembrar

CONTRASENA = "ClubNahuel1"


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def token_usuario(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> str:
    s = unico()
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
    token = iniciar_sesion(f"socio.{s}@correo.com", CONTRASENA)
    assert token is not None
    return token


@pytest.fixture
def token_admin(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> str:
    s = unico()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(f"admin.{s}@club.com", CONTRASENA)
    assert token is not None
    return token


@pytest.fixture
def sede(api: TestClient, token_admin: str, unico: Callable[[], str]) -> str:
    r = api.post(
        "/venues",
        headers=_con(token_admin),
        json={
            "name": f"Sede Castelar {unico()}",
            "address": "Av. Santa Rosa 1200",
            "opens_at": "08:00",
            "closes_at": "23:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    )
    assert r.status_code == 201
    return str(r.json()["id"])


def _cancha(sede: str, deporte: str, tipo: str) -> dict[str, object]:
    return {
        "venue_id": sede,
        "sport": deporte,
        "kind": tipo,
        "covered": True,
        "lit": True,
        "price_per_hour": 30000,
    }


def test_el_catalogo_ofrece_basquet_con_su_tipo(api: TestClient, token_usuario: str) -> None:
    """el catálogo de deportes ofrece Básquet con su tipo de cancha
    @REV-05-S1 @assumption:REV-05-ASM-01 @assumption:REV-05-ASM-03
    """
    catalogo = api.get("/spaces/catalog", headers=_con(token_usuario)).json()
    claves = [d["key"] for d in catalogo["sports"]]

    assert claves.index("Basquet") == claves.index("Voley") + 1

    basquet = next((d for d in catalogo["sports"] if d["key"] == "Basquet"), None)
    assert basquet == {
        "key": "Basquet",
        "name": "Básquet",
        "kinds": [
            {"key": "B5", "name": "Básquet 5"},
            {"key": "3X3", "name": "Básquet 3x3"},
        ],
    }


def test_el_administrador_da_de_alta_una_cancha_de_basquet(
    api: TestClient, token_admin: str, sede: str
) -> None:
    """el administrador da de alta una cancha de Básquet @REV-05-S2"""
    r = api.post("/spaces", headers=_con(token_admin), json=_cancha(sede, "Basquet", "B5"))

    assert r.status_code == 201
    assert r.json()["sport"] == "Basquet"
    assert r.json()["name"].endswith("_Basquet_B5_1")


def test_un_tipo_de_otro_deporte_no_sirve_para_basquet(
    api: TestClient, token_admin: str, sede: str
) -> None:
    """un tipo que no es de Básquet se rechaza @REV-05-S2"""
    r = api.post("/spaces", headers=_con(token_admin), json=_cancha(sede, "Basquet", "F5"))

    assert r.status_code == 422
    assert r.json()["errors"]["kind"] == "Elegí un tipo de la lista"


def test_el_socio_filtra_los_espacios_por_basquet(
    api: TestClient, token_admin: str, token_usuario: str, sede: str
) -> None:
    """el socio filtra los espacios por Básquet @REV-05-S3"""
    basquet = api.post(
        "/spaces", headers=_con(token_admin), json=_cancha(sede, "Basquet", "3X3")
    ).json()
    futbol = api.post(
        "/spaces", headers=_con(token_admin), json=_cancha(sede, "Futbol", "F5")
    ).json()

    r = api.get(
        "/spaces", headers=_con(token_usuario), params={"venue_id": sede, "sport": "Basquet"}
    )

    ids = [e["id"] for e in r.json()["spaces"]]
    assert basquet["id"] in ids
    assert futbol["id"] not in ids
