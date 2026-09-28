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
            "/registro",
            json={
                "nombre": "Martín",
                "apellido": "Ferreyra",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
                "fecha_nacimiento": "1994-07-21",
                "correo": correo,
                "contrasena": "ClubNahuel1",
            },
        ).status_code
        == 201
    )
    token = iniciar_sesion(correo, "ClubNahuel1")
    nombre = f"Sede Haedo {s}"

    r = api.post(
        "/sedes",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "nombre": nombre,
            "direccion": "Av. Vergara 1850",
            "apertura": "08:00",
            "cierre": "23:00",
            "dias": [1, 2, 3, 4, 5, 6, 7],
        },
    )

    # Verifica: la API lo rechaza por falta de permisos.
    assert r.status_code == 403
    # Verifica: la sede no quedó guardada.
    with motor.connect() as conn:
        assert (
            conn.execute(
                text("SELECT count(*) FROM sede WHERE nombre = :n"), {"n": nombre}
            ).scalar_one()
            == 0
        )
