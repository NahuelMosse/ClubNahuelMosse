from collections.abc import Callable

from fastapi.testclient import TestClient


def test_la_api_rechaza_la_consulta_global_de_reservas_a_un_usuario_sin_rol_de_administrador(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """la API rechaza la consulta global de reservas a un usuario sin rol de administrador @CU-14-H05-02"""
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

    r = api.get(
        "/bookings/all",
        headers={"Authorization": f"Bearer {token}"},
    )

    # Verifica: la API lo rechaza por falta de permisos, no por un error de datos.
    assert r.status_code == 403
