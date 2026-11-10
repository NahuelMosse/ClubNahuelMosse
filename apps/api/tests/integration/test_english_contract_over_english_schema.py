"""The HTTP contract speaks English over a database that stores English values."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import json
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


def _new_space(api: TestClient, admin_token: str, venue_id: str) -> str:
    r = api.post(
        "/spaces",
        headers=_auth(admin_token),
        json={
            "venue_id": venue_id,
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    )
    assert r.status_code == 201
    return str(r.json()["id"])


def _book(api: TestClient, token: str, space: str, day: int, since: str = "21:00") -> dict[str, Any]:
    r = api.post(
        "/bookings",
        headers=_auth(token),
        json={
            "space_id": space,
            "date": (date.today() + timedelta(days=day)).isoformat(),
            "start_hour": since,
            "hours": 1,
        },
    )
    assert r.status_code == 201
    booking: dict[str, Any] = r.json()
    return booking


def _stored(engine: Engine, sql: str, **binds: object) -> Any:
    with engine.connect() as conn:
        return conn.execute(text(sql), binds).scalar_one()


def test_the_api_answers_with_the_contract_values_of_main_while_the_database_stores_english_ones(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """the API answers with the contract values of main while the database stores English ones @ENG-17-S5 @assumption:ENG-17-ASM-01"""
    space = _new_space(api, admin_token, venue[0])
    active = _book(api, user_token, space, 1)
    to_cancel = _book(api, user_token, space, 2)
    to_void = _book(api, user_token, space, 3)

    assert active["status"] == "active"
    assert _stored(engine, "SELECT status FROM booking WHERE id = :i", i=active["id"]) == "active"
    cancel = api.post(f"/bookings/{to_cancel['id']}/cancel", headers=_auth(user_token))
    assert cancel.json()["status"] == "canceled"
    assert _stored(engine, "SELECT status FROM booking WHERE id = :i", i=to_cancel["id"]) == "canceled"
    void = api.post(
        f"/bookings/{to_void['id']}/void",
        headers=_auth(admin_token),
        json={"reason": "mantenimiento", "space_id": space, "starts_at": to_void["starts_at"]},
    )
    assert void.status_code == 200
    assert void.json()["status"] == "voided"
    assert _stored(engine, "SELECT status FROM booking WHERE id = :i", i=to_void["id"]) == "voided"

    me = api.get("/me", headers=_auth(user_token)).json()
    assert me["role"] == "user"
    assert _stored(engine, "SELECT role FROM app_user WHERE email = :e", e=me["email"]) == "user"

    api.put(
        "/devices",
        headers=_auth(user_token),
        json={"token": f"fcm-{to_void['id']}", "platform": "android", "permission_granted": True},
    )
    user_id = UUID(str(_stored(engine, "SELECT id FROM app_user WHERE email = :e", e=me["email"])))
    sweep = datetime.combine(date.today() + timedelta(days=1), datetime.min.time(), ZONE)
    with engine.connect() as conn:
        send_reminders(NotificationsSql(conn), _Channel(), sweep.replace(hour=20), user_id)
    notifications = api.get("/notifications", headers=_auth(user_token)).json()["notifications"]
    assert {"reminder", "forced_cancellation"} <= {n["kind"] for n in notifications}
    stored_kinds = {
        k for (k,) in engine.connect().execute(text("SELECT kind FROM notification WHERE user_id = :u"), {"u": user_id})
    }
    assert {"reminder", "forced_cancellation"} <= stored_kinds
    assert _stored(engine, "SELECT count(*) FROM notification WHERE user_id = :u AND delivery = 'sent'", u=user_id) >= 1
    listed = api.get("/bookings/all?q=" + venue[1], headers=_auth(admin_token)).json()
    assert {b["notice_delivery"] for b in listed["bookings"]} <= {None, "sent", "no_channel", "no_permission", "failed"}


def test_the_published_contract_is_the_same_as_mains() -> None:
    """the published contract is the same as main's @ENG-17-S5"""
    from app.main import app

    published = (API_ROOT / "openapi.json").read_text(encoding="utf-8")

    assert json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n" == published


def test_a_booking_survives_restarting_the_app_on_the_migrated_database(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """a booking survives restarting the app on the migrated database @ENG-17-S4"""
    from app.main import create_app

    booking = _book(api, user_token, _new_space(api, admin_token, venue[0]), 1)

    with TestClient(create_app()) as restarted:
        listed = restarted.get("/bookings", headers=_auth(user_token)).json()

    assert booking["id"] in json.dumps(listed)


def test_every_constraint_name_the_api_compares_exists_in_the_migrated_schema_and_a_duplicate_that_reaches_it_answers_409(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    """every constraint name the API compares exists in the migrated schema and a duplicate that reaches it answers 409 @assumption:ENG-17-ASM-10"""
    with engine.connect() as conn:
        existing = {
            n for (n,) in conn.execute(text("SELECT conname FROM pg_constraint UNION SELECT indexname FROM pg_indexes"))
        }
    for module, names in CONSTRAINTS_BY_REPOSITORY.items():
        source = (MODULES / module / "repository.py").read_text(encoding="utf-8")
        for name in names:
            assert name in existing, name
            assert name in source, (module, name)

    me = api.get("/me", headers=_auth(user_token)).json()
    s = unique()
    same_email = {
        "first_name": "Ana", "last_name": "Gil", "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1994-07-21", "email": me["email"], "password": PASSWORD,
    }  # fmt: skip
    same_dni = same_email | {"email": f"otro.{s}@correo.com", "dni": me["dni"]}
    assert api.post("/register", json=same_email).status_code == 409
    assert api.post("/register", json=same_dni).status_code == 409

    venue_name = _stored(engine, "SELECT name FROM venue WHERE id = :i", i=venue[0])
    again = api.post(
        "/venues",
        headers=_auth(admin_token),
        json={"name": venue_name, "address": "Av. Vergara 1850", "opens_at": "08:00", "closes_at": "23:00", "open_days": [1]},
    )
    assert again.status_code == 409
