"""SIM-02 contra la base y el emulador reales: la API legible hace lo mismo."""

from datetime import date, timedelta
from typing import Any

from fastapi.testclient import TestClient


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _espacio(api: TestClient, admin_token: str, sede_id: str) -> str:
    r = api.post(
        "/spaces",
        headers=_con(admin_token),
        json={
            "venue_id": sede_id,
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    )
    assert r.status_code == 201, r.text
    return str(r.json()["id"])


def _pedido(espacio: str, dia: int, hora: int) -> dict[str, Any]:
    return {
        "space_id": espacio,
        "date": (date.today() + timedelta(days=dia)).isoformat(),
        "start_hour": f"{hora:02d}:00",
        "hours": 1,
    }


def test_una_reserva_hecha_y_movida_sobrevive_a_reiniciar_la_api(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """una reserva hecha y movida sobrevive a reiniciar la API sobre la misma base @SIM-02-S1"""
    from app.main import create_app

    espacio = _espacio(api, admin_token, venue[0])
    r = api.post("/bookings", headers=_con(user_token), json=_pedido(espacio, 1, 10))
    assert r.status_code == 201, r.text
    creada = r.json()["id"]
    nuevo = _pedido(espacio, 2, 11)
    nuevo.pop("hours")
    movida = api.post(f"/bookings/{creada}/modify", headers=_con(user_token), json=nuevo)
    assert movida.status_code == 200, movida.text

    with TestClient(create_app()) as otra:
        r = otra.get("/bookings", headers=_con(user_token))
    leida = next(x for x in r.json()["bookings"] if x["id"] == creada)
    assert leida["starts_at"] == movida.json()["starts_at"]
    assert leida["total"] == movida.json()["total"]
