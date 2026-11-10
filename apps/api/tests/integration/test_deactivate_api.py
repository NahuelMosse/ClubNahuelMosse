"""`DELETE /me` against the real database and emulator."""

import os
from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.users.seed_admin import main as seed

ZONE = ZoneInfo("America/Argentina/Buenos_Aires")
PASSWORD = "ClubNahuel1"


def _register(api: TestClient, s: str) -> tuple[str, str]:
    email = f"socia.{s}@correo.com"
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    payload = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": dni,
        "birth_date": "1998-11-02",
        "email": email,
        "password": PASSWORD,
    }
    assert api.post("/register", json=payload).status_code == 201
    return email, dni


def _space(engine: Engine, s: str) -> UUID:
    with engine.begin() as conn:
        venue: Any = conn.execute(
            text(
                "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Belgrano', 1240, '00:00', '00:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede {s}"},
        ).scalar_one()
        return UUID(
            str(
                conn.execute(
                    text(
                        "INSERT INTO space (venue_id, sport, kind, number, name,"
                        " price_per_hour, covered, lit)"
                        " VALUES (:venue, 'Voley', 'IND', 1, :n, 33000, true, true) RETURNING id"
                    ),
                    {"venue": venue, "n": f"RamosMejia_Belgrano_1240_Voley_IND_1_{s}"},
                ).scalar_one()
            )
        )


def _book(engine: Engine, email: str, space: UUID, start: datetime) -> UUID:
    with engine.begin() as conn:
        return UUID(
            str(
                conn.execute(
                    text(
                        "INSERT INTO booking (user_id, space_id, starts_at, ends_at,"
                        " price_per_hour, total)"
                        " SELECT id, :e, :i, :f, 33000, 33000 FROM app_user"
                        " WHERE email = :c AND active RETURNING id"
                    ),
                    {"c": email, "e": space, "i": start, "f": start + timedelta(hours=1)},
                ).scalar_one()
            )
        )


def test_deactivation_is_logical_keeps_the_history_and_frees_the_email(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    s = unique()
    email, dni = _register(api, s)
    space = _space(engine, s)
    hour = datetime.now(ZONE).replace(minute=0, second=0, microsecond=0)
    past = _book(engine, email, space, hour - timedelta(days=3))
    ongoing = _book(engine, email, space, hour)
    future = _book(engine, email, space, hour + timedelta(days=1))
    token = sign_in(email, PASSWORD)

    assert api.delete("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 204

    with engine.connect() as conn:
        statuses: dict[UUID, str] = dict(
            conn.execute(
                text("SELECT id, status FROM booking WHERE id IN (:a, :b, :c)"),
                {"a": past, "b": ongoing, "c": future},
            ).all()
        )
        active: Any = conn.execute(
            text("SELECT active FROM app_user WHERE email = :c"), {"c": email}
        ).scalar_one()
    # Checks CU-07-SUP-04: the future one is cancelled; the past one and the ongoing one stay.
    assert statuses == {past: "active", ongoing: "active", future: "canceled"}
    assert active is False
    # The session is no longer valid and that password no longer signs in.
    assert api.get("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401
    assert sign_in(email, PASSWORD) is None
    # Checks CU-07-SUP-01: the email and the DNI are free for a new account.
    another = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": dni,
        "birth_date": "1998-11-02",
        "email": email,
        "password": PASSWORD,
    }
    assert api.post("/register", json=another).status_code == 201


def test_an_admin_is_not_deactivated(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    s = unique()
    email = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", PASSWORD)
    arguments = [
        "--correo", email, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert seed(arguments) == 0
    token = sign_in(email, PASSWORD)
    assert api.delete("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 403
    assert api.get("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 200
    os.environ.pop("ADMIN_CONTRASENA", None)


def test_no_session_no_deactivation(api: TestClient) -> None:
    assert api.delete("/me").status_code == 401


def test_two_simultaneous_deactivations_deactivate_only_once(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    from concurrent.futures import ThreadPoolExecutor

    email, _ = _register(api, unique())
    token = sign_in(email, PASSWORD)
    with ThreadPoolExecutor(max_workers=2) as pool:
        codes = sorted(
            pool.map(
                lambda _: (
                    api.delete("/me", headers={"Authorization": f"Bearer {token}"}).status_code
                ),
                range(2),
            )
        )
    # One deactivates; the other finds it already done (204) or the session expired (401).
    assert codes[0] == 204 and codes[1] in (204, 401)
    with engine.connect() as conn:
        active: Any = conn.execute(
            text("SELECT active FROM app_user WHERE email = :c"), {"c": email}
        ).scalar_one()
    assert active is False
