"""El barrido de recordatorios como comando aparte del servicio web."""

import os
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

RAIZ_API = Path(__file__).resolve().parents[2]


def _reserva_en_la_proxima_hora(motor: Engine, correo: str, s: str) -> UUID:
    with motor.begin() as conn:
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
            {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1", "c": correo},
        ).scalar_one()


def test_los_recordatorios_salen_con_un_comando_fuera_del_servicio_web(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    """los recordatorios salen aunque el servicio web esté dormido @REV-02-S3
    @assumption:REV-02-ASM-02
    """
    s = unico()
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
    reserva = _reserva_en_la_proxima_hora(motor, f"socio.{s}@correo.com", s)

    corrida = subprocess.run(
        [sys.executable, "-m", "app.modules.notifications.sweep", "--una-vez"],
        cwd=RAIZ_API, env={**os.environ, "PYTHONUTF8": "1"},
        capture_output=True, text=True, timeout=120, check=False,
    )  # fmt: skip

    assert corrida.returncode == 0, corrida.stdout + corrida.stderr
    with motor.connect() as conn:
        avisos = conn.execute(
            text(
                "SELECT count(*) FROM notification WHERE kind = 'reminder' AND booking_id = :r"
            ),
            {"r": reserva},
        ).scalar_one()
    assert avisos == 1
