"""`PUT /yo/contrasena` contra la base y el emulador reales."""

import time
from collections.abc import Callable

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ACTUAL = "ClubNahuel1"
NUEVA = "ClubNahuel2"


def _registrar(api: TestClient, s: str) -> str:
    correo = f"socia.{s}@correo.com"
    pedido = {
        "nombre": "Lucía",
        "apellido": "Gómez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1998-11-02",
        "correo": correo,
        "contrasena": ACTUAL,
    }
    assert api.post("/registro", json=pedido).status_code == 201
    return correo


def _cambiar(api: TestClient, token: str | None, actual: str, nueva: str) -> tuple[int, str]:
    r = api.put(
        "/yo/contrasena",
        headers={"Authorization": f"Bearer {token}"},
        json={"actual": actual, "nueva": nueva},
    )
    return r.status_code, r.text


def test_cambia_la_contrasena_deja_rastro_e_invalida_las_sesiones(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    correo = _registrar(api, unico())
    token = iniciar_sesion(correo, ACTUAL)
    # La revocación de Firebase cuenta por segundos: el token tiene que ser de antes.
    time.sleep(1.1)

    assert _cambiar(api, token, ACTUAL, NUEVA) == (204, "")

    assert iniciar_sesion(correo, ACTUAL) is None
    nuevo = iniciar_sesion(correo, NUEVA)
    assert nuevo is not None
    # La sesión que cambió la contraseña también quedó vencida; con la nueva se entra.
    assert api.get("/yo", headers={"Authorization": f"Bearer {token}"}).status_code == 401
    assert api.get("/yo", headers={"Authorization": f"Bearer {nuevo}"}).status_code == 200
    with motor.connect() as conn:
        cambiada = conn.execute(
            text("SELECT contrasena_cambiada_en FROM usuario WHERE correo = :c"), {"c": correo}
        ).scalar()
    assert cambiada is not None


def test_la_actual_equivocada_no_cambia_nada(
    api: TestClient, iniciar_sesion: Callable[[str, str], str | None], unico: Callable[[], str]
) -> None:
    correo = _registrar(api, unico())
    token = iniciar_sesion(correo, ACTUAL)
    codigo, cuerpo = _cambiar(api, token, "OtraClave9", NUEVA)
    assert codigo == 422
    assert '"actual":"La contraseña actual no coincide"' in cuerpo
    assert iniciar_sesion(correo, ACTUAL) is not None


def test_una_nueva_debil_se_rechaza_con_la_regla_que_falta(
    api: TestClient, iniciar_sesion: Callable[[str, str], str | None], unico: Callable[[], str]
) -> None:
    correo = _registrar(api, unico())
    token = iniciar_sesion(correo, ACTUAL)
    codigo, cuerpo = _cambiar(api, token, ACTUAL, "ClubNahuel")
    assert codigo == 422
    assert '"nueva":"Al menos un número"' in cuerpo
    assert iniciar_sesion(correo, ACTUAL) is not None


def test_sin_sesion_no_se_puede_cambiar(api: TestClient) -> None:
    assert _cambiar(api, "basura", ACTUAL, NUEVA)[0] == 401
