import logging
from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient

from app.main import crear_app

REGISTRO = "clubnahuelmosse.errores"


def test_un_pedido_sin_sesion_queda_en_el_registro(
    api: TestClient, caplog: pytest.LogCaptureFixture
) -> None:
    """un pedido rechazado por falta de sesión queda registrado @supuesto:TP-07-SUP-06"""
    with caplog.at_level(logging.INFO, logger=REGISTRO):
        assert api.get("/yo").status_code == 401

    assert any("GET /yo 401 usuario=anónimo" in r.getMessage() for r in caplog.records)


def test_un_acceso_denegado_queda_en_el_registro_con_el_usuario(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    caplog: pytest.LogCaptureFixture,
) -> None:
    """un acceso denegado queda registrado con quién lo intentó @supuesto:TP-07-SUP-06"""
    s = unico()
    correo = f"socio.{s}@correo.com"
    alta = api.post(
        "/registro",
        json={
            "nombre": "Martín",
            "apellido": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1994-07-21",
            "correo": correo,
            "contrasena": "ClubNahuel1",
        },
    )
    assert alta.status_code == 201
    token_usuario = iniciar_sesion(correo, "ClubNahuel1")
    with caplog.at_level(logging.INFO, logger=REGISTRO):
        r = api.post(
            "/sedes",
            headers={"Authorization": f"Bearer {token_usuario}"},
            json={
                "nombre": "Sede Haedo",
                "direccion": "Av. Vergara 1850",
                "apertura": "08:00",
                "cierre": "23:00",
                "dias": [1],
            },
        )
    assert r.status_code == 403

    mensajes = [m for m in (x.getMessage() for x in caplog.records) if "POST /sedes 403" in m]
    assert mensajes
    assert "usuario=anónimo" not in mensajes[0]
    assert "usuario=" in mensajes[0]


def test_una_excepcion_no_atrapada_queda_en_el_registro_y_responde_500(
    caplog: pytest.LogCaptureFixture,
) -> None:
    """una excepción no atrapada queda registrada con su causa @supuesto:TP-07-SUP-06"""
    app = crear_app()

    def falla() -> None:
        raise RuntimeError("se rompió algo")

    app.add_api_route("/falla", falla)
    with caplog.at_level(logging.INFO, logger=REGISTRO):
        with TestClient(app, raise_server_exceptions=False) as cliente:
            r = cliente.get("/falla")
    assert r.status_code == 500

    registros = [x for x in caplog.records if "GET /falla 500" in x.getMessage()]
    assert registros
    assert registros[0].levelno == logging.ERROR
    assert registros[0].exc_info is not None
