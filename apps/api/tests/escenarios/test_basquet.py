"""Básquet en el catálogo de deportes: se ofrece, se da de alta y se filtra."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient

from app.interfaz.sembrar_admin import main as sembrar

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
        "/registro",
        json={
            "nombre": "Martín",
            "apellido": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1994-07-21",
            "correo": f"socio.{s}@correo.com",
            "contrasena": CONTRASENA,
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
def sede(api: TestClient, token_admin: str, unico: Callable[[], str]) -> int:
    r = api.post(
        "/sedes",
        headers=_con(token_admin),
        json={
            "nombre": f"Sede Castelar {unico()}",
            "direccion": "Av. Santa Rosa 1200",
            "apertura": "08:00",
            "cierre": "23:00",
            "dias": [1, 2, 3, 4, 5, 6, 7],
        },
    )
    assert r.status_code == 201
    return int(r.json()["id"])


def _cancha(sede: int, deporte: str, tipo: str) -> dict[str, object]:
    return {
        "sede_id": sede,
        "deporte": deporte,
        "tipo": tipo,
        "techada": True,
        "iluminada": True,
        "precio_por_hora": 30000,
    }


def test_el_catalogo_ofrece_basquet_con_su_tipo(api: TestClient, token_usuario: str) -> None:
    """el catálogo de deportes ofrece Básquet con su tipo de cancha
    @REV-05-H19-01 @assumption:REV-05-ASM-01 @assumption:REV-05-ASM-03
    """
    catalogo = api.get("/espacios/catalogo", headers=_con(token_usuario)).json()
    claves = [d["clave"] for d in catalogo["deportes"]]

    assert claves.index("Basquet") == claves.index("Voley") + 1

    basquet = next((d for d in catalogo["deportes"] if d["clave"] == "Basquet"), None)
    assert basquet == {
        "clave": "Basquet",
        "nombre": "Básquet",
        "tipos": [
            {"clave": "B5", "nombre": "Básquet 5"},
            {"clave": "3X3", "nombre": "Básquet 3x3"},
        ],
    }


def test_el_administrador_da_de_alta_una_cancha_de_basquet(
    api: TestClient, token_admin: str, sede: int
) -> None:
    """el administrador da de alta una cancha de Básquet @REV-05-H19-02"""
    r = api.post("/espacios", headers=_con(token_admin), json=_cancha(sede, "Basquet", "B5"))

    assert r.status_code == 201
    assert r.json()["deporte"] == "Basquet"
    assert r.json()["nombre"].endswith("_Basquet_B5_1")


def test_un_tipo_de_otro_deporte_no_sirve_para_basquet(
    api: TestClient, token_admin: str, sede: int
) -> None:
    """un tipo que no es de Básquet se rechaza @REV-05-H19-02"""
    r = api.post("/espacios", headers=_con(token_admin), json=_cancha(sede, "Basquet", "F5"))

    assert r.status_code == 422
    assert r.json()["errores"]["tipo"] == "Elegí un tipo de la lista"


def test_el_socio_filtra_los_espacios_por_basquet(
    api: TestClient, token_admin: str, token_usuario: str, sede: int
) -> None:
    """el socio filtra los espacios por Básquet @REV-05-H19-03"""
    basquet = api.post(
        "/espacios", headers=_con(token_admin), json=_cancha(sede, "Basquet", "3X3")
    ).json()
    futbol = api.post(
        "/espacios", headers=_con(token_admin), json=_cancha(sede, "Futbol", "F5")
    ).json()

    r = api.get(
        "/espacios", headers=_con(token_usuario), params={"sede_id": sede, "deporte": "Basquet"}
    )

    ids = [e["id"] for e in r.json()["espacios"]]
    assert basquet["id"] in ids
    assert futbol["id"] not in ids
