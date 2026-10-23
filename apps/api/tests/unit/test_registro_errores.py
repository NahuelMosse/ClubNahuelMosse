"""El registro de errores: ruta escapada, rechazos y log de accesos sin query, sin base."""

import logging

import pytest
from fastapi.testclient import TestClient
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import PlainTextResponse, Response
from starlette.routing import Route
from starlette.types import Receive, Scope, Send

from app.interfaz.registro_errores import (
    RegistroDeErrores,
    _SinQuery,
    configurar_registro,
    escapar,
)


def _responde(codigo: int) -> Route:
    async def ruta(_: Request) -> Response:
        return PlainTextResponse("x", status_code=codigo)

    return Route(f"/c{codigo}", ruta)


async def _siempre_403(scope: Scope, receive: Receive, send: Send) -> None:
    """Sin router: el de Starlette no casa una ruta con saltos de línea."""
    await PlainTextResponse("x", status_code=403)(scope, receive, send)


async def _falla(_: Request) -> Response:
    raise RuntimeError("roto")


def _cliente() -> TestClient:
    app = Starlette(
        routes=[
            *(_responde(c) for c in (200, 400, 401, 403, 404, 409, 429, 500)),
            Route("/f", _falla),
        ]
    )
    app.add_middleware(RegistroDeErrores)
    return TestClient(app, raise_server_exceptions=False)


def test_escapar_muestra_los_caracteres_de_control_y_deja_el_resto() -> None:
    assert escapar("/a\nb\rc\x00d\x7fe") == "/a\\nb\\rc\\x00d\\x7fe"
    assert escapar("/ñandú/é ü") == "/ñandú/é ü"


@pytest.mark.parametrize("codigo", [400, 401, 403, 409, 429])
def test_los_rechazos_se_registran_como_aviso(
    caplog: pytest.LogCaptureFixture, codigo: int
) -> None:
    with caplog.at_level(logging.INFO, logger="clubnahuelmosse.errores"):
        _cliente().get(f"/c{codigo}")

    assert [(r.levelno, r.getMessage()) for r in caplog.records] == [
        (logging.WARNING, f"GET /c{codigo} {codigo} usuario=anónimo")
    ]


@pytest.mark.parametrize("codigo", [200, 404])
def test_lo_demas_no_se_registra(caplog: pytest.LogCaptureFixture, codigo: int) -> None:
    with caplog.at_level(logging.INFO, logger="clubnahuelmosse.errores"):
        _cliente().get(f"/c{codigo}")

    assert caplog.records == []


def test_un_5xx_y_una_excepcion_se_registran_como_error(caplog: pytest.LogCaptureFixture) -> None:
    with caplog.at_level(logging.INFO, logger="clubnahuelmosse.errores"):
        _cliente().get("/c500")
        _cliente().get("/f")

    assert [r.levelno for r in caplog.records] == [logging.ERROR, logging.ERROR]
    assert caplog.records[0].getMessage() == "GET /c500 500 usuario=anónimo"
    assert caplog.records[1].getMessage() == "GET /f 500 usuario=anónimo"
    assert caplog.records[1].exc_info is not None


def test_la_ruta_registrada_no_parte_la_linea(caplog: pytest.LogCaptureFixture) -> None:
    with caplog.at_level(logging.INFO, logger="clubnahuelmosse.errores"):
        TestClient(RegistroDeErrores(_siempre_403)).get("/x/a%0aFALSO%0d2026")

    assert [r.getMessage() for r in caplog.records] == [
        "GET /x/a\\nFALSO\\r2026 403 usuario=anónimo"
    ]


def _acceso(ruta: str) -> logging.LogRecord:
    registro = logging.LogRecord(
        "uvicorn.access", logging.INFO, "", 0, '%s - "%s %s HTTP/%s" %d',
        ("127.0.0.1:1", "GET", ruta, "1.1", 200), None,
    )  # fmt: skip
    _SinQuery().filter(registro)
    return registro


def test_el_log_de_accesos_pierde_el_query_string() -> None:
    registro = _acceso("/reservas/todas?q=ana%40ejemplo.com")

    assert registro.getMessage() == '127.0.0.1:1 - "GET /reservas/todas HTTP/1.1" 200'


def test_el_log_de_accesos_escapa_la_ruta() -> None:
    assert "\n" not in _acceso("/a\nb").getMessage()


def test_un_registro_de_accesos_de_otra_forma_pasa_igual() -> None:
    registro = logging.LogRecord("uvicorn.access", logging.INFO, "", 0, "hola %s", ("x",), None)

    assert _SinQuery().filter(registro) is True
    assert registro.getMessage() == "hola x"


def test_configurar_el_registro_instala_el_filtro_una_sola_vez() -> None:
    accesos = logging.getLogger("uvicorn.access")
    configurar_registro()
    configurar_registro()

    assert sum(isinstance(f, _SinQuery) for f in accesos.filters) == 1
