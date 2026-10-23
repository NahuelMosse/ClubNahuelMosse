"""`PUT /yo` contra la base y el emulador reales."""

from collections.abc import Callable
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

CONTRASENA = "ClubNahuel1"


def _registrar(api: TestClient, s: str, dni: str | None = None) -> tuple[str, str]:
    correo = f"socia.{s}@correo.com"
    dni = dni or str(int(s, 16) % 90_000_000 + 10_000_000)
    pedido = {
        "nombre": "Lucía",
        "apellido": "Gómez",
        "dni": dni,
        "fecha_nacimiento": "1998-11-02",
        "correo": correo,
        "contrasena": CONTRASENA,
    }
    assert api.post("/registro", json=pedido).status_code == 201
    return correo, dni


def _editar(api: TestClient, token: str | None, **datos: str) -> tuple[int, dict[str, Any]]:
    r = api.put("/yo", headers={"Authorization": f"Bearer {token}"}, json=datos)
    return r.status_code, r.json()


def test_guarda_los_datos_personales_y_devuelve_el_perfil_nuevo(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    correo, _ = _registrar(api, unico())
    token = iniciar_sesion(correo, CONTRASENA)
    codigo, cuerpo = _editar(
        api,
        token,
        nombre=" Lucía Inés ",
        apellido="Gómez Paz",
        dni="30.111.225",
        fecha_nacimiento="1998-11-03",
    )
    assert codigo == 200
    assert cuerpo == {
        "nombre": "Lucía Inés",
        "apellido": "Gómez Paz",
        "correo": correo,
        "rol": "usuario",
        "dni": "30111225",
        "fecha_nacimiento": "1998-11-03",
    }
    with motor.connect() as conn:
        creado, modificado = conn.execute(
            text("SELECT creado_en, modificado_en FROM usuario WHERE correo = :c"), {"c": correo}
        ).one()
    # El rastro de la modificación lo estampa la base.
    assert modificado > creado


def test_el_correo_no_se_cambia_aunque_se_mande(
    api: TestClient, iniciar_sesion: Callable[[str, str], str | None], unico: Callable[[], str]
) -> None:
    correo, dni = _registrar(api, unico())
    token = iniciar_sesion(correo, CONTRASENA)
    codigo, cuerpo = _editar(
        api,
        token,
        nombre="Lucía",
        apellido="Gómez",
        dni=dni,
        fecha_nacimiento="1998-11-02",
        correo="otra@correo.com",
    )
    assert (codigo, cuerpo["correo"]) == (200, correo)


def test_datos_invalidos_no_guardan_nada(
    api: TestClient, iniciar_sesion: Callable[[str, str], str | None], unico: Callable[[], str]
) -> None:
    correo, _ = _registrar(api, unico())
    token = iniciar_sesion(correo, CONTRASENA)
    codigo, cuerpo = _editar(
        api, token, nombre="Otra", apellido="", dni="42118", fecha_nacimiento="2000-13-32"
    )
    assert codigo == 422
    assert set(cuerpo["errores"]) == {"apellido", "dni", "fecha_nacimiento"}
    assert api.get("/yo", headers={"Authorization": f"Bearer {token}"}).json()["nombre"] == "Lucía"


def test_un_dni_de_otra_cuenta_se_rechaza(
    api: TestClient, iniciar_sesion: Callable[[str, str], str | None], unico: Callable[[], str]
) -> None:
    """Verifica CU-06-SUP-02."""
    _, ajeno = _registrar(api, unico())
    correo, _ = _registrar(api, unico())
    token = iniciar_sesion(correo, CONTRASENA)
    codigo, cuerpo = _editar(
        api, token, nombre="Lucía", apellido="Gómez", dni=ajeno, fecha_nacimiento="1998-11-02"
    )
    assert (codigo, cuerpo) == (409, {"errores": {"dni": "Este DNI ya está registrado"}})


def test_sin_sesion_no_se_edita(api: TestClient) -> None:
    assert api.put("/yo", json={"nombre": "X"}).status_code == 401
