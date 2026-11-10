from collections.abc import Callable

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def test_un_usuario_sin_rol_de_administrador_no_puede_dar_de_alta_una_sede(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """un usuario sin rol de administrador no puede dar de alta una sede @CU-17-H01-03"""
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
    token = iniciar_sesion(correo, "ClubNahuel1")
    nombre = f"Sede Haedo {s}"

    r = api.post(
        "/venues",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "name": nombre,
            "address": "Av. Vergara 1850",
            "opens_at": "08:00",
            "closes_at": "23:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    )

    # Verifica: la API lo rechaza por falta de permisos.
    assert r.status_code == 403
    # Verifica: la sede no quedó guardada.
    with motor.connect() as conn:
        assert (
            conn.execute(
                text("SELECT count(*) FROM venue WHERE name = :n"), {"n": nombre}
            ).scalar_one()
            == 0
        )
