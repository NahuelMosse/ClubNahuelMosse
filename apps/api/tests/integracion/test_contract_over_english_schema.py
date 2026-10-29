"""The HTTP contract keeps main's Spanish values while the database stores English ones."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import json
import subprocess
from collections.abc import Callable, Sequence
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import Notice
from app.modules.notifications.use_cases import DeliveryResult, send_reminders

API_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = API_ROOT.parents[1]
MODULES = API_ROOT / "app" / "modules"
ZONE = ZoneInfo("America/Argentina/Buenos_Aires")
PASSWORD = "ClubNahuel1"
CONSTRAINTS_BY_REPOSITORY = {
    "venues": ["venue_name_active_unique"],
    "spaces": ["space_name_key"],
    "users": ["app_user_email_unique", "app_user_dni_unique"],
}


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


def _book(api: TestClient, token: str, space: str, day: int, since: str = "21:00") -> dict[str, Any]:
    r = api.post(
        "/reservas",
        headers=_auth(token),
        json={
            "espacio_id": space,
            "fecha": (date.today() + timedelta(days=day)).isoformat(),
            "desde": since,
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
    listed = api.get("/reservas/todas?q=" + sede[1], headers=_auth(token_admin)).json()
    assert "enviada" in json.dumps(listed, ensure_ascii=False)


def test_the_published_contract_is_the_same_as_mains() -> None:
    """the published contract is the same as main's @ENG-17-S5"""
    from app.main import app

    published = (API_ROOT / "openapi.json").read_text(encoding="utf-8")
    from_main = subprocess.run(
        ["git", "show", "main:apps/api/openapi.json"],
        cwd=REPO_ROOT, capture_output=True, check=True, encoding="utf-8",
    ).stdout  # fmt: skip

    assert published == from_main
    assert json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n" == published


def test_a_booking_survives_restarting_the_app_on_the_migrated_database(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """a booking survives restarting the app on the migrated database @ENG-17-S4"""
    from app.main import create_app

    booking = _book(api, token_usuario, _new_space(api, token_admin, sede[0]), 1)

    with TestClient(create_app()) as restarted:
        listed = restarted.get("/reservas", headers=_auth(token_usuario)).json()

    assert booking["id"] in json.dumps(listed)


def test_every_constraint_name_the_api_compares_exists_in_the_migrated_schema_and_a_duplicate_that_reaches_it_answers_409(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    """every constraint name the API compares exists in the migrated schema and a duplicate that reaches it answers 409 @assumption:ENG-17-ASM-10"""
    with motor.connect() as conn:
        existing = {
            n for (n,) in conn.execute(text("SELECT conname FROM pg_constraint UNION SELECT indexname FROM pg_indexes"))
        }
    for module, names in CONSTRAINTS_BY_REPOSITORY.items():
        source = (MODULES / module / "repository.py").read_text(encoding="utf-8")
        for name in names:
            assert name in existing, name
            assert name in source, (module, name)

    me = api.get("/yo", headers=_auth(token_usuario)).json()
    s = unico()
    same_email = {
        "nombre": "Ana", "apellido": "Gil", "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1994-07-21", "correo": me["correo"], "contrasena": PASSWORD,
    }  # fmt: skip
    same_dni = same_email | {"correo": f"otro.{s}@correo.com", "dni": me["dni"]}
    assert api.post("/registro", json=same_email).status_code == 409
    assert api.post("/registro", json=same_dni).status_code == 409

    venue_name = _stored(motor, "SELECT name FROM venue WHERE id = :i", i=sede[0])
    again = api.post(
        "/sedes",
        headers=_auth(token_admin),
        json={"nombre": venue_name, "direccion": "Av. Vergara 1850", "apertura": "08:00", "cierre": "23:00", "dias": [1]},
    )
    assert again.status_code == 409
