"""SIM-02 contra la base y el emulador reales: la API legible hace lo mismo."""

from datetime import date, timedelta
from typing import Any

from fastapi.testclient import TestClient


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _espacio(api: TestClient, token_admin: str, sede_id: str) -> str:
    r = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede_id,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    )
    assert r.status_code == 201, r.text
    return str(r.json()["id"])


def _pedido(espacio: str, dia: int, hora: int) -> dict[str, Any]:
    return {
        "espacio_id": espacio,
        "fecha": (date.today() + timedelta(days=dia)).isoformat(),
        "desde": f"{hora:02d}:00",
        "horas": 1,
    }


def test_una_reserva_hecha_y_movida_sobrevive_a_reiniciar_la_api(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """una reserva hecha y movida sobrevive a reiniciar la API sobre la misma base @SIM-02-S1"""
    from app.main import crear_app

    espacio = _espacio(api, token_admin, sede[0])
    r = api.post("/reservas", headers=_con(token_usuario), json=_pedido(espacio, 1, 10))
    assert r.status_code == 201, r.text
    creada = r.json()["id"]
    nuevo = _pedido(espacio, 2, 11)
    nuevo.pop("horas")
    movida = api.post(
        f"/reservas/{creada}/modificar", headers=_con(token_usuario), json=nuevo
    )
    assert movida.status_code == 200, movida.text

    with TestClient(crear_app()) as otra:
        r = otra.get("/reservas", headers=_con(token_usuario))
    leida = next(x for x in r.json()["reservas"] if x["id"] == creada)
    assert leida["inicio"] == movida.json()["inicio"]
    assert leida["total"] == movida.json()["total"]
