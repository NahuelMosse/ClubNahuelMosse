from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")


def _proxima_hora(dias: int) -> datetime:
    ahora = datetime.now(ZONA).replace(minute=0, second=0, microsecond=0)
    return ahora + timedelta(days=dias, hours=1)


def test_al_eliminar_la_cuenta_el_horario_de_su_reserva_vigente_vuelve_a_estar_disponible(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """al eliminar la cuenta, el horario de su reserva vigente vuelve a estar disponible @CU-07-H01-02"""
    s = unico()
    correo = f"socia.{s}@correo.com"
    assert (
        api.post(
            "/register",
            json={
                "first_name": "Lucía",
                "last_name": "Gómez",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
                "birth_date": "1998-11-02",
                "email": correo,
                "password": "ClubNahuel1",
            },
        ).status_code
        == 201
    )
    inicio = _proxima_hora(dias=2)
    with motor.begin() as conn:
        usuario: Any = conn.execute(
            text("SELECT id FROM app_user WHERE email = :c"), {"c": correo}
        ).scalar_one()
        sede: Any = conn.execute(
            text(
                "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Rivadavia', 19850, '08:00', '00:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede {s}"},
        ).scalar_one()
        espacio: Any = conn.execute(
            text(
                "INSERT INTO space (venue_id, sport, kind, number, name, price_per_hour,"
                " covered, lit) VALUES (:venue, 'Futbol', 'F5', 1, :name, 38000, false,"
                " true) RETURNING id"
            ),
            {"venue": sede, "name": f"Moron_Rivadavia_19850_Futbol_F5_1_{s}"},
        ).scalar_one()
        reserva: Any = conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
            ),
            {"u": usuario, "e": espacio, "i": inicio, "f": inicio + timedelta(hours=1)},
        ).scalar_one()

    token = iniciar_sesion(correo, "ClubNahuel1")
    assert api.delete("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 204

    with motor.begin() as conn:
        estado, cancelada_por = conn.execute(
            text("SELECT status, canceled_by FROM booking WHERE id = :r"), {"r": reserva}
        ).one()
        # Verifica: la reserva queda cancelada por la persona que se dio de baja, con rastro.
        assert (estado, cancelada_por) == ("canceled", usuario)
        # Verifica: el mismo horario del mismo espacio se puede volver a reservar; si siguiera
        # tomado, la base lo rechazaría por superposición.
        otra: Any = conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " VALUES (:u, :e, :i, :f, 38000, 38000) RETURNING id"
            ),
            {"u": usuario, "e": espacio, "i": inicio, "f": inicio + timedelta(hours=1)},
        ).scalar_one()
        assert otra != reserva
