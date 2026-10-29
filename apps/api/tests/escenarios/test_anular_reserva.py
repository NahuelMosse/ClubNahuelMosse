from collections.abc import Callable

from fastapi.testclient import TestClient


def test_la_api_rechaza_la_anulacion_pedida_por_un_usuario_sin_rol_de_administrador(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """la API rechaza la anulación pedida por un usuario sin rol de administrador @CU-15-H01-04"""
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

    r = api.post(
        "/bookings/00000000-0000-7000-8000-000000000001/void",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "reason": "mantenimiento de la cancha",
            "space_id": "00000000-0000-7000-8000-000000000002",
            "starts_at": "2030-01-01T21:00:00-03:00",
        },
    )

    # Verifica: la API lo rechaza por falta de permisos, no por un error de datos.
    assert r.status_code == 403
