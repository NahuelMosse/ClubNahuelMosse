"""Lo que el registro de errores deja en el log, y lo que no."""

import logging
from typing import Annotated

import pytest
from fastapi import Depends
from fastapi.testclient import TestClient
from sqlalchemy import Connection, Engine, text
from starlette.types import Receive, Scope, Send

from app.infraestructura.db import conexion
from app.interfaz.registro_errores import RegistroDeErrores
from app.main import crear_app

REGISTRO = "clubnahuelmosse.errores"
DNI = "30123456"
CORREO = "secreto.privado@correo.com"


def _texto_del_registro(caplog: pytest.LogCaptureFixture) -> str:
    formato = logging.Formatter()
    return "\n".join(formato.format(x) for x in caplog.records)


def test_el_error_de_la_base_no_deja_datos_personales_en_el_registro(
    motor: Engine, caplog: pytest.LogCaptureFixture
) -> None:
    app = crear_app()

    def falla(conn: Annotated[Connection, Depends(conexion)]) -> None:
        conn.execute(
            text("SELECT columna_inexistente FROM usuario WHERE dni = :dni AND correo = :correo"),
            {"dni": DNI, "correo": CORREO},
        )

    app.add_api_route("/falla-base", falla)
    with (
        caplog.at_level(logging.INFO, logger=REGISTRO),
        TestClient(app, raise_server_exceptions=False) as cliente,
    ):
        r = cliente.get("/falla-base")

    assert r.status_code == 500
    registro = _texto_del_registro(caplog)
    assert "GET /falla-base 500" in registro
    assert "columna_inexistente" in registro
    assert DNI not in registro
    assert CORREO not in registro


def test_una_tarea_de_fondo_que_falla_despues_de_responder_registra_el_codigo_enviado(
    caplog: pytest.LogCaptureFixture,
) -> None:
    async def tarea_de_fondo(scope: Scope, receive: Receive, send: Send) -> None:
        await send({"type": "http.response.start", "status": 202, "headers": []})
        await send({"type": "http.response.body", "body": b""})
        raise RuntimeError("falló la tarea")

    # Sin `with`: el cliente no corre el ciclo de vida, que esta app cruda no atiende.
    cliente = TestClient(RegistroDeErrores(tarea_de_fondo), raise_server_exceptions=False)
    with caplog.at_level(logging.INFO, logger=REGISTRO):
        cliente.get("/aviso")

    mensajes = [x.getMessage() for x in caplog.records if x.levelno == logging.ERROR]
    assert any("GET /aviso 202" in m and "posterior a la respuesta" in m for m in mensajes)
    assert not any("GET /aviso 500" in m for m in mensajes)
