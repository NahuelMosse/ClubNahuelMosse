"""The reminder sweep as a command apart from the web service."""

import os
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

API_ROOT = Path(__file__).resolve().parents[2]


def _booking_in_the_next_hour(engine: Engine, email: str, s: str) -> UUID:
    with engine.begin() as conn:
        return conn.execute(
            text(
                "WITH s AS (INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Vergara', 1850, '00:00', '00:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id),"
                " e AS (INSERT INTO space (venue_id, sport, kind, number, name, covered,"
                " lit, price_per_hour) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id)"
                " INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                " total, created_at, updated_at)"
                " SELECT u.id, e.id, h, h + interval '1 hour', 38000, 38000,"
                " now() - interval '2 hours', now() - interval '2 hours' FROM app_user u, e,"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
                " + interval '1 hour' AS h) AS t WHERE u.email = :c AND u.active"
                " RETURNING booking.id"
            ),
            {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1", "c": email},
        ).scalar_one()


def test_reminders_go_out_with_a_command_outside_the_web_service(
    api: TestClient, engine: Engine, unique: Callable[[], str]
) -> None:
    """reminders go out even if the web service is asleep @REV-02-S3
    @assumption:REV-02-ASM-02
    """
    s = unique()
    api.post(
        "/register",
        json={
            "first_name": "Martín",
            "last_name": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1994-07-21",
            "email": f"socio.{s}@correo.com",
            "password": "ClubNahuel1",
        },
    )
    booking = _booking_in_the_next_hour(engine, f"socio.{s}@correo.com", s)

    run = subprocess.run(
        [sys.executable, "-m", "app.modules.notifications.sweep", "--una-vez"],
        cwd=API_ROOT, env={**os.environ, "PYTHONUTF8": "1"},
        capture_output=True, text=True, timeout=120, check=False,
    )  # fmt: skip

    assert run.returncode == 0, run.stdout + run.stderr
    with engine.connect() as conn:
        notices = conn.execute(
            text("SELECT count(*) FROM notification WHERE kind = 'reminder' AND booking_id = :r"),
            {"r": booking},
        ).scalar_one()
    assert notices == 1
