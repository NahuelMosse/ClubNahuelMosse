"""The HTTP contract keeps main's Spanish values while the database stores English ones."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import json
from collections.abc import Sequence
from datetime import date, datetime, timedelta
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import Notice
from app.modules.notifications.use_cases import DeliveryResult, send_reminders

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")


def _auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


class _Channel:
    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        return DeliveryResult(sent=len(tokens))


def _new_space(api: TestClient, token_admin: str, venue_id: str) -> str:
    r = api.post(
        "/espacios",
        headers=_auth(token_admin),
        json={
            "sede_id": venue_id,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    )
    assert r.status_code == 201
    return str(r.json()["id"])


def _book(api: TestClient, token: str, space: str, day: int) -> dict[str, Any]:
    r = api.post(
        "/reservas",
        headers=_auth(token),
        json={
            "espacio_id": space,
            "fecha": (date.today() + timedelta(days=day)).isoformat(),
            "desde": "21:00",
            "horas": 1,
        },
    )
    assert r.status_code == 201
    booking: dict[str, Any] = r.json()
    return booking


def _stored(motor: Engine, sql: str, **binds: object) -> Any:
    with motor.connect() as conn:
        return conn.execute(text(sql), binds).scalar_one()


def test_the_api_answers_with_the_contract_values_of_main_while_the_database_stores_english_ones(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
) -> None:
    """the API answers with the contract values of main while the database stores English ones @ENG-17-S5 @assumption:ENG-17-ASM-01"""
    space = _new_space(api, token_admin, sede[0])
    active = _book(api, token_usuario, space, 1)
    to_cancel = _book(api, token_usuario, space, 2)
    to_void = _book(api, token_usuario, space, 3)

    assert active["estado"] == "activa"
    assert _stored(motor, "SELECT status FROM booking WHERE id = :i", i=active["id"]) == "active"
    cancel = api.post(f"/reservas/{to_cancel['id']}/cancelar", headers=_auth(token_usuario))
    assert cancel.json()["estado"] == "cancelada"
    assert _stored(motor, "SELECT status FROM booking WHERE id = :i", i=to_cancel["id"]) == "canceled"
    void = api.post(
        f"/reservas/{to_void['id']}/anular",
        headers=_auth(token_admin),
        json={"motivo": "mantenimiento", "espacio_id": space, "inicio": to_void["inicio"]},
    )
    assert void.status_code == 200
    assert void.json()["estado"] == "anulada"
    assert _stored(motor, "SELECT status FROM booking WHERE id = :i", i=to_void["id"]) == "voided"

    me = api.get("/yo", headers=_auth(token_usuario)).json()
    assert me["rol"] == "usuario"
    assert _stored(motor, "SELECT role FROM app_user WHERE email = :e", e=me["correo"]) == "user"

    api.put(
        "/dispositivos",
        headers=_auth(token_usuario),
        json={"token": f"fcm-{to_void['id']}", "plataforma": "android", "permiso": True},
    )
    user_id = UUID(str(_stored(motor, "SELECT id FROM app_user WHERE email = :e", e=me["correo"])))
    sweep = datetime.combine(date.today() + timedelta(days=1), datetime.min.time(), ZONE)
    with motor.connect() as conn:
        send_reminders(NotificationsSql(conn), _Channel(), sweep.replace(hour=20), user_id)
    kinds = {n["tipo"] for n in api.get("/notificaciones", headers=_auth(token_usuario)).json()["notificaciones"]}
    assert {"recordatorio", "cancelacion_forzosa"} <= kinds
    stored_kinds = {
        k for (k,) in motor.connect().execute(text("SELECT kind FROM notification WHERE user_id = :u"), {"u": user_id})
    }
    assert {"reminder", "forced_cancellation"} <= stored_kinds
    assert _stored(motor, "SELECT count(*) FROM notification WHERE user_id = :u AND delivery = 'sent'", u=user_id) >= 1

    # The history shows the delivery of the notice linked to the booking: the forced cancellation.
    with motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE notification SET delivery = 'sent', sent_at = now()"
                " WHERE user_id = :u AND kind = 'forced_cancellation'"
            ),
            {"u": user_id},
        )
    listed = api.get("/reservas/todas?q=" + sede[1], headers=_auth(token_admin)).json()
    assert "enviada" in json.dumps(listed, ensure_ascii=False)
