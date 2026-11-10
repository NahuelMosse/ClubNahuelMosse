import asyncio
from collections.abc import Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.shared import body_limit

ONE_MB = 1024 * 1024


def _in_chunks(chunks: int, size: int) -> Iterator[bytes]:
    for _ in range(chunks):
        yield b"x" * size


def test_the_api_cuts_a_body_over_1_mb_with_413() -> None:
    """the API cuts a body over 1 MB with 413 @SIM-01-S2 @assumption:SIM-01-ASM-09"""
    client = TestClient(create_app())

    declared = client.post("/venues", content=b"x" * (ONE_MB + 1))
    chunked = client.post("/venues", content=_in_chunks(3, ONE_MB // 2))

    assert declared.status_code == 413
    assert chunked.status_code == 413


def test_the_api_cuts_with_408_in_5_s_a_body_that_never_finishes_arriving(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """the API cuts with 408 in 5 s a body that never finishes arriving @SIM-01-S2 @assumption:SIM-01-ASM-09"""
    assert body_limit.TIMEOUT_SECONDS == 5
    monkeypatch.setattr(body_limit, "TIMEOUT_SECONDS", 0.2)
    sent: list[dict[str, Any]] = []

    async def never_ends() -> dict[str, Any]:
        await asyncio.sleep(60)
        return {"type": "http.disconnect"}

    async def send(message: dict[str, Any]) -> None:
        sent.append(message)

    scope = {
        "type": "http",
        "method": "POST",
        "path": "/venues",
        "raw_path": b"/sedes",
        "query_string": b"",
        "headers": [(b"host", b"testserver")],
    }

    asyncio.run(create_app()(scope, never_ends, send))

    assert sent[0]["status"] == 408
