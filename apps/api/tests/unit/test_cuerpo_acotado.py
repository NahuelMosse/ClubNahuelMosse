import asyncio
from collections.abc import Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.shared import body_limit

UN_MB = 1024 * 1024


def _por_partes(partes: int, tamano: int) -> Iterator[bytes]:
    for _ in range(partes):
        yield b"x" * tamano


def test_la_api_corta_un_cuerpo_de_mas_de_1_mb_con_413() -> None:
    """la API corta un cuerpo de más de 1 MB con 413 @SIM-01-S2 @assumption:SIM-01-ASM-09"""
    cliente = TestClient(create_app())

    declarado = cliente.post("/sedes", content=b"x" * (UN_MB + 1))
    por_partes = cliente.post("/sedes", content=_por_partes(3, UN_MB // 2))

    assert declarado.status_code == 413
    assert por_partes.status_code == 413


def test_la_api_corta_con_408_en_5_s_un_cuerpo_que_no_termina_de_llegar(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """la API corta con 408 en 5 s un cuerpo que no termina de llegar @SIM-01-S2 @assumption:SIM-01-ASM-09"""
    assert body_limit.TIMEOUT_SECONDS == 5
    monkeypatch.setattr(body_limit, "TIMEOUT_SECONDS", 0.2)
    enviados: list[dict[str, Any]] = []

    async def nunca_termina() -> dict[str, Any]:
        await asyncio.sleep(60)
        return {"type": "http.disconnect"}

    async def enviar(mensaje: dict[str, Any]) -> None:
        enviados.append(mensaje)

    scope = {
        "type": "http",
        "method": "POST",
        "path": "/sedes",
        "raw_path": b"/sedes",
        "query_string": b"",
        "headers": [(b"host", b"testserver")],
    }

    asyncio.run(create_app()(scope, nunca_termina, enviar))

    assert enviados[0]["status"] == 408
