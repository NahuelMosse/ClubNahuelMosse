from collections.abc import Callable

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
    with motor.begin() as conn:
        sede = conn.execute(
            text(
                "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede Haedo {s}"},
        ).scalar_one()
    token = iniciar_sesion(correo, "ClubNahuel1")

    r = api.post(
        "/espacios",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "sede_id": sede,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    )

    # Verifica: la API lo rechaza por falta de permisos.
    assert r.status_code == 403
    # Verifica: la sede sigue sin espacios.
    with motor.connect() as conn:
        assert (
            conn.execute(
                text("SELECT count(*) FROM espacio WHERE sede_id = :s"), {"s": sede}
            ).scalar_one()
            == 0
        )
