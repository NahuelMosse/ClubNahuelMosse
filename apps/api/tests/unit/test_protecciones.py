"""Las protecciones del borde (Host, tamaño, cabeceras), sobre una app mínima y sin base."""

from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import JSONResponse, PlainTextResponse, Response
from starlette.routing import Route

from app.config import config
from app.interfaz.protecciones import Protecciones, hosts_permitidos


async def _eco(peticion: Request) -> Response:
    return PlainTextResponse(str(len(await peticion.body())))


async def _con_politica_propia(_: Request) -> Response:
    return JSONResponse({}, headers={"Content-Security-Policy": "script-src 'self'"})


def _cliente(host: str = "localhost") -> TestClient:
    app = Starlette(
        routes=[
            Route("/eco", _eco, methods=["POST"]),
            Route("/propia", _con_politica_propia),
            Route("/docs", _eco, methods=["GET", "POST"]),
            Route("/redoc", _eco, methods=["GET"]),
            Route("/otra", _eco, methods=["GET"]),
        ]
    )
    app.add_middleware(Protecciones)
    return TestClient(app, base_url=f"http://{host}")


@pytest.fixture(autouse=True)
def _config_base(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(config, "url_publica", "https://club.onrender.com")
    monkeypatch.setattr(config, "hosts_permitidos", "")
    monkeypatch.setattr(config, "documentacion_interactiva", True)


@pytest.mark.parametrize(
    "host",
    ["localhost", "127.0.0.1", "10.0.2.2", "club.onrender.com", "LOCALHOST", "localhost:8000"],
)
def test_los_host_propios_pasan(host: str) -> None:
    assert _cliente().get("/otra", headers={"Host": host}).status_code == 200


@pytest.mark.parametrize("host", ["attacker.example", "localhost.attacker.example", "", "[::1]"])
def test_un_host_ajeno_da_400_con_las_cabeceras_de_seguridad(host: str) -> None:
    r = _cliente().get("/otra", headers={"Host": host})

    assert r.status_code == 400
    assert r.headers["content-security-policy"] == "default-src 'none'; frame-ancestors 'none'"
    assert r.headers["cache-control"] == "no-store"
    assert r.headers["x-content-type-options"] == "nosniff"


def test_los_host_se_suman_desde_la_configuracion(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(config, "hosts_permitidos", " Testserver , otro.ejemplo ,")

    assert {"testserver", "otro.ejemplo", "club.onrender.com", "localhost"} <= hosts_permitidos()
    assert "" not in hosts_permitidos()


def test_el_host_de_url_publica_se_suma_y_sin_host_no_suma_nada(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(config, "url_publica", "")

    assert hosts_permitidos() == {"localhost", "127.0.0.1", "10.0.2.2"}


def test_el_host_con_corchetes_se_compara_sin_el_puerto(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(config, "hosts_permitidos", "[::1]")

    assert _cliente().get("/otra", headers={"Host": "[::1]:8000"}).status_code == 200


def test_toda_respuesta_lleva_la_politica_de_contenido_y_las_cabeceras() -> None:
    r = _cliente().get("/otra")

    assert r.headers["content-security-policy"] == "default-src 'none'; frame-ancestors 'none'"
    assert r.headers["cache-control"] == "no-store"
    assert r.headers["x-content-type-options"] == "nosniff"


def test_una_politica_propia_de_la_ruta_se_conserva() -> None:
    r = _cliente().get("/propia")

    assert r.headers.get_list("content-security-policy") == ["script-src 'self'"]


@pytest.mark.parametrize("ruta", ["/docs", "/redoc"])
def test_la_documentacion_prendida_no_lleva_politica(ruta: str) -> None:
    assert "content-security-policy" not in _cliente().get(ruta).headers


def test_la_documentacion_apagada_lleva_politica(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(config, "documentacion_interactiva", False)

    assert "content-security-policy" in _cliente().get("/docs").headers


def test_la_exencion_es_solo_de_docs_y_redoc() -> None:
    assert "content-security-policy" in _cliente().get("/otra").headers


def test_un_content_length_que_no_es_un_numero_da_400() -> None:
    r = _cliente().post("/eco", content=b"{}", headers={"Content-Length": "abc"})

    assert r.status_code == 400


def test_un_content_length_declarado_de_mas_de_64_kb_da_413() -> None:
    r = _cliente().post("/eco", content=b"{}", headers={"Content-Length": "65537"})

    assert r.status_code == 413


def test_un_cuerpo_de_exactamente_64_kb_pasa() -> None:
    assert _cliente().post("/eco", content=b"a" * 65536).text == "65536"


def test_un_cuerpo_por_partes_de_mas_de_64_kb_da_413() -> None:
    def partes() -> Iterator[bytes]:
        yield b"a" * 40_000
        yield b"a" * 40_000

    assert _cliente().post("/eco", content=partes()).status_code == 413


def test_lo_que_no_es_http_pasa_sin_tocarse() -> None:
    llamadas: list[str] = []

    async def interior(scope: dict[str, str], receive: object, send: object) -> None:
        llamadas.append(scope["type"])

    import asyncio

    asyncio.run(Protecciones(interior)({"type": "lifespan"}, None, None))  # type: ignore[arg-type]

    assert llamadas == ["lifespan"]
