"""Registro de usuarios visto desde la API: lo que la pantalla no puede probar sola."""

from collections.abc import Callable

from fastapi.testclient import TestClient


def test_con_la_cuenta_recien_creada_puede_iniciar_sesion(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """con la cuenta recién creada puede iniciar sesión @CU-03-H01-02

    Verifica: después de registrarse, el correo y la contraseña que eligió abren sesión, y una
    contraseña distinta no. Si falla, la persona crea la cuenta y queda afuera igual.
    """
    s = unico()
    correo = f"Nueva.{s}@Correo.com"
    respuesta = api.post(
        "/registro",
        json={
            "nombre": "Nahuel Agustín",
            "apellido": "Mosse",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "2000-03-14",
            "correo": correo,
            "contrasena": "ClubNahuel1",
        },
    )
    assert respuesta.status_code == 201, respuesta.text

    assert iniciar_sesion(correo.lower(), "ClubNahuel1") is not None
    assert iniciar_sesion(correo.lower(), "OtraClave9") is None
