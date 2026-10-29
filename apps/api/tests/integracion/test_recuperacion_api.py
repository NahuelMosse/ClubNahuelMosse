"""La recuperación de contraseña contra la base y el emulador reales, con el buzón."""

import re
import time
from collections.abc import Callable
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

VIEJA = "ClubNahuel1"
NUEVA = "ClubNahuel2"


def _registrar(api: TestClient, s: str) -> str:
    correo = f"socia.{s}@correo.com"
    pedido = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1998-11-02",
        "email": correo,
        "password": VIEJA,
    }
    assert api.post("/register", json=pedido).status_code == 201
    return correo


def _codigos(motor: Engine, correo: str) -> list[str]:
    with motor.connect() as conn:
        cuerpos: Any = conn.execute(
            text("SELECT body FROM outgoing_email WHERE recipient = :p ORDER BY id"), {"p": correo}
        ).scalars()
        return [m.group(1) for c in cuerpos if (m := re.search(r"#codigo=([\w-]+)", c))]


def test_pedir_y_usar_el_enlace_cambia_la_contrasena_una_sola_vez(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    correo = _registrar(api, unico())
    token = iniciar_sesion(correo, VIEJA)
    time.sleep(1.1)
    assert api.post("/password-recovery", json={"email": correo.upper()}).status_code == 202
    (codigo,) = _codigos(motor, correo)

    assert api.post("/password-recovery/check", json={"code": codigo}).status_code == 204
    assert (
        api.put("/password-recovery", json={"code": codigo, "new_password": NUEVA}).status_code
        == 204
    )

    assert iniciar_sesion(correo, VIEJA) is None
    assert iniciar_sesion(correo, NUEVA) is not None
    # Las sesiones abiertas antes quedaron vencidas.
    assert api.get("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401
    assert api.post("/password-recovery/check", json={"code": codigo}).status_code == 410
    assert (
        api.put(
            "/password-recovery", json={"code": codigo, "new_password": "ClubNahuel3"}
        ).status_code
        == 410
    )


def test_un_correo_sin_cuenta_recibe_la_misma_respuesta_y_ningun_mail(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    correo = f"nadie.{unico()}@correo.com"
    r = api.post("/password-recovery", json={"email": correo})
    assert (r.status_code, r.content) == (202, b"")
    assert _codigos(motor, correo) == []


def test_una_cuenta_dada_de_baja_no_recibe_enlace(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    """Verifica CU-04b-SUP-01."""
    correo = _registrar(api, unico())
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE app_user SET active = false, deactivated_at = now() WHERE email = :c"),
            {"c": correo},
        )
    assert api.post("/password-recovery", json={"email": correo}).status_code == 202
    assert _codigos(motor, correo) == []


def test_reenviar_invalida_el_enlace_anterior_y_hay_tope_por_hora(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    correo = _registrar(api, unico())
    for _ in range(4):
        assert api.post("/password-recovery", json={"email": correo}).status_code == 202
    codigos = _codigos(motor, correo)
    assert len(codigos) == 3
    assert [
        api.post("/password-recovery/check", json={"code": c}).status_code for c in codigos
    ] == [410, 410, 204]


def test_cambiar_la_contrasena_por_otra_via_invalida_los_enlaces(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """Verifica CU-04b-SUP-03."""
    correo = _registrar(api, unico())
    api.post("/password-recovery", json={"email": correo})
    (codigo,) = _codigos(motor, correo)
    token = iniciar_sesion(correo, VIEJA)
    r = api.put(
        "/me/password",
        headers={"Authorization": f"Bearer {token}"},
        json={"current_password": VIEJA, "new_password": NUEVA},
    )
    assert r.status_code == 204
    assert api.post("/password-recovery/check", json={"code": codigo}).status_code == 410


def test_una_contrasena_debil_se_rechaza_y_el_enlace_sigue_sirviendo(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    correo = _registrar(api, unico())
    api.post("/password-recovery", json={"email": correo})
    (codigo,) = _codigos(motor, correo)
    r = api.put("/password-recovery", json={"code": codigo, "new_password": "ClubNahuel"})
    assert r.status_code == 422
    assert r.json() == {"errors": {"new_password": "Al menos un número"}}
    assert api.post("/password-recovery/check", json={"code": codigo}).status_code == 204


def test_un_codigo_inventado_no_sirve(api: TestClient) -> None:
    assert api.post("/password-recovery/check", json={"code": "inventado"}).status_code == 410
    assert api.post("/password-recovery/check", json={}).status_code == 410
    assert (
        api.put("/password-recovery", json={"code": "inventado", "new_password": NUEVA}).status_code
        == 410
    )


def test_un_correo_mal_escrito_se_rechaza(api: TestClient) -> None:
    r = api.post("/password-recovery", json={"email": "lucia@correo"})
    assert r.status_code == 422
    assert r.json() == {"errors": {"email": "Revisá el formato del correo"}}


def test_sin_modo_pruebas_no_existe_el_buzon(api: TestClient) -> None:
    assert api.get("/_testing/emails", params={"para": "x@y.com"}).status_code == 404


def test_el_enlace_del_correo_es_https_y_el_codigo_no_llega_al_servidor(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    correo = _registrar(api, unico())
    api.post("/password-recovery", json={"email": correo})
    with motor.connect() as conn:
        cuerpo: Any = conn.execute(
            text("SELECT body FROM outgoing_email WHERE recipient = :p"), {"p": correo}
        ).scalar_one()
    enlace = re.search(r"(\S+/enlace/recuperar)#codigo=", cuerpo)
    assert enlace is not None and enlace.group(1).startswith("http")
    pagina = api.get("/link/recover")
    assert pagina.status_code == 200
    assert "intent://app/recuperar?codigo=" in pagina.text
    assert "package=ar.edu.unimoron.clubnahuelmosse" in pagina.text
    assert pagina.headers["referrer-policy"] == "no-referrer"


def test_pedidos_simultaneos_no_dejan_dos_enlaces_vigentes(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    from concurrent.futures import ThreadPoolExecutor

    correo = _registrar(api, unico())
    with ThreadPoolExecutor(max_workers=6) as pool:
        codigos_http = list(
            pool.map(
                lambda _: api.post("/password-recovery", json={"email": correo}).status_code,
                range(6),
            )
        )
    assert codigos_http == [202] * 6
    codigos = _codigos(motor, correo)
    assert len(codigos) == 3
    vigentes = [
        c
        for c in codigos
        if api.post("/password-recovery/check", json={"code": c}).status_code == 204
    ]
    assert len(vigentes) == 1
