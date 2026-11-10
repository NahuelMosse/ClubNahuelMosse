"""SIM-01 against the real database and emulator: history without a marker, notices without retries."""

import os
from collections.abc import Sequence
from datetime import date, timedelta
from pathlib import Path
from typing import Any
from uuid import UUID

from alembic import command
from alembic.config import Config as AlembicConfig
from fastapi.testclient import TestClient
from sqlalchemy import Engine, create_engine, text

from app.modules.notifications.rules import Notice, DeliveryResult
from tests.integration.test_uuid_and_audit import new_db  # noqa: F401  (fixture)

API_ROOT = Path(__file__).resolve().parents[2]
TEST_DATABASE_URL = os.environ["DATABASE_URL"]


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _space(api: TestClient, admin_token: str, venue_id: str) -> str:
    r = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json={
            "venue_id": venue_id,
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    )
    return str(r.json()["id"])


def _book(api: TestClient, token: str, space: str, day: int, hour: int) -> dict[str, Any]:
    r = api.post(
        "/bookings",
        headers=_bearer(token),
        json={
            "space_id": space,
            "date": (date.today() + timedelta(days=day)).isoformat(),
            "start_hour": f"{hour:02d}:00",
            "hours": 1,
        },
    )
    assert r.status_code == 201, r.text
    body: dict[str, Any] = r.json()
    return body


def test_the_own_history_is_the_whole_listing_and_without_a_marker(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """the own history is the listing ordered by date, whole and without a marker @SIM-01-S1 @assumption:SIM-01-ASM-01"""
    space = _space(api, admin_token, venue[0])
    created = [_book(api, user_token, space, d, h)["id"] for d in (1, 2) for h in range(8, 19)]

    r = api.get("/bookings", headers=_bearer(user_token), params={"cuando": "upcoming"})

    assert r.status_code == 200
    assert "siguiente" not in r.json()
    assert [x["id"] for x in r.json()["bookings"]] == created
    assert api.get("/bookings?despues=x", headers=_bearer(user_token)).status_code == 200


def test_the_admin_history_still_paginates_by_page_number(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """the admin history still paginates by page number @SIM-01-S2 @assumption:SIM-01-ASM-01"""
    space = _space(api, admin_token, venue[0])
    for h in range(8, 8 + 22):
        _book(api, user_token, space, 1 + (h - 8) // 11, 8 + (h - 8) % 11)
    q = {"q": venue[1]}

    first = api.get("/bookings/all", headers=_bearer(admin_token), params={**q, "page": 1})
    second = api.get("/bookings/all", headers=_bearer(admin_token), params={**q, "page": 2})

    assert first.status_code == second.status_code == 200
    assert len(first.json()["bookings"]) == 20 and len(second.json()["bookings"]) == 2
    assert "siguiente" not in first.json()


def test_a_booking_survives_restarting_the_api(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """a booking survives restarting the API on the same database @SIM-01-S2"""
    from app.main import create_app

    space = _space(api, admin_token, venue[0])
    created = _book(api, user_token, space, 1, 10)["id"]

    with TestClient(create_app()) as other:
        r = other.get("/bookings", headers=_bearer(user_token))
    assert created in [x["id"] for x in r.json()["bookings"]]


class _FailingChannel:
    calls = 0

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        type(self).calls += 1
        raise ConnectionError("FCM no responde")


def test_a_notice_that_fails_stays_failed_and_is_not_retried(engine: Engine) -> None:
    """a notice that fails stays failed and is not tried again @SIM-01-S1 @assumption:SIM-01-ASM-02"""
    from app.modules.notifications.use_cases import dispatch_pending
    from app.modules.notifications.repository import NotificationsSql

    with engine.begin() as conn:
        id_: UUID = conn.execute(
            text(
                "INSERT INTO notification (user_id, kind, title, body, delivery)"
                " SELECT id, 'forced_cancellation', 'Cancelaron', 'Fútbol 5', 'pending'"
                " FROM app_user WHERE active LIMIT 1 RETURNING id"
            )
        ).scalar_one()
        conn.execute(
            text(
                "INSERT INTO device (user_id, token, platform, permission_granted)"
                " SELECT user_id, 'fcm-sim01-' || id, 'android', true FROM notification"
                " WHERE id = :id ON CONFLICT DO NOTHING"
            ),
            {"id": id_},
        )
    channel = _FailingChannel()
    with engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), channel)
        after_the_first = _FailingChannel.calls
        dispatch_pending(NotificationsSql(conn), channel)
    with engine.connect() as conn:
        delivery: str = conn.execute(
            text("SELECT delivery FROM notification WHERE id = :id"), {"id": id_}
        ).scalar_one()
    assert delivery == "failed"
    assert after_the_first >= 1 and _FailingChannel.calls == after_the_first


def test_notification_no_longer_has_attempts_or_taken_at(engine: Engine) -> None:
    """the database no longer has «intentos» or «tomada_en» in «notificacion» @assumption:SIM-01-ASM-02"""
    with engine.connect() as conn:
        columns = {
            f[0]
            for f in conn.execute(
                text(
                    "SELECT column_name FROM information_schema.columns"
                    " WHERE table_name = 'notification'"
                )
            )
        }
    assert columns and not {"intentos", "tomada_en"} & columns


def test_migration_0009_turns_a_sending_notice_into_failed(
    new_db: tuple[AlembicConfig, str],  # noqa: F811  (the imported fixture)
) -> None:
    """migration 0009 turns a notice that was sending into failed @assumption:SIM-01-ASM-07"""
    # In its own database: the shared database cannot go back to 0008 once 0010
    # created rows with new ids (DAT-01-ASM-02).
    alembic, url = new_db
    command.upgrade(alembic, "0008")
    engine = create_engine(url)
    try:
        with engine.begin() as conn:
            conn.execute(
                text(
                    "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni,"
                    " fecha_nacimiento) VALUES ('uid-0009', 'a@correo.com', 'Ana', 'Pérez',"
                    " '30111222', '2000-03-14')"
                )
            )
            id_: int = conn.execute(
                text(
                    "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio, tomada_en)"
                    " SELECT id, 'cancelacion_forzosa', 'Cancelaron', 'Fútbol 5', 'enviando', now()"
                    " FROM usuario LIMIT 1 RETURNING id"
                )
            ).scalar_one()
        command.upgrade(alembic, "0009")
        with engine.connect() as conn:
            delivery: str = conn.execute(
                text("SELECT envio FROM notificacion WHERE id = :id"), {"id": id_}
            ).scalar_one()
    finally:
        engine.dispose()
    assert delivery == "fallida"
