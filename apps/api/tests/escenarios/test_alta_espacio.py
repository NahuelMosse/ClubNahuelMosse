from collections.abc import Callable
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def test_un_usuario_sin_rol_de_administrador_no_puede_dar_de_alta_un_espacio(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """un usuario sin rol de administrador no puede dar de alta un espacio @CU-21-H01-03"""
    s = unico()
    correo = f"socio.{s}@correo.com"
    assert (
        api.post(
            "/register",
            json={
                "first_name": "Martín",
                "last_name": "Ferreyra",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
                "birth_date": "1994-07-21",
                "email": correo,
                "password": "ClubNahuel1",
            },
        ).status_code
        == 201
    )
    with motor.begin() as conn:
        sede: Any = conn.execute(
            text(
                "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede Haedo {s}"},
        ).scalar_one()
    token = iniciar_sesion(correo, "ClubNahuel1")

    r = api.post(
        "/spaces",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "venue_id": str(sede),
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    )

    # Verifica: la API lo rechaza por falta de permisos.
    assert r.status_code == 403
    # Verifica: la sede sigue sin espacios.
    with motor.connect() as conn:
        assert (
            conn.execute(
                text("SELECT count(*) FROM space WHERE venue_id = :s"), {"s": sede}
            ).scalar_one()
            == 0
        )
