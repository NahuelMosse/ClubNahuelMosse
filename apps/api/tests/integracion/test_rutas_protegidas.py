"""Toda operación registrada en la API, publicada o no en OpenAPI, pide sesión salvo las
públicas."""

import re
from collections.abc import Iterator
from typing import Any

from fastapi import FastAPI
from fastapi.routing import APIRoute
from fastapi.testclient import TestClient

from app.main import create_app

# Lo que la API sirve sin sesión: alta de cuenta y recuperación de contraseña, con la página
# del enlace del correo.
PUBLICAS = {
    ("POST", "/register"),
    ("POST", "/password-recovery"),
    ("POST", "/password-recovery/check"),
    ("PUT", "/password-recovery"),
    ("GET", "/link/recover"),
    ("GET", "/health"),
}
PROTEGIDAS = 28


def _rutas(app: FastAPI) -> Iterator[tuple[str, str]]:
    """Método y ruta de cada operación, también las de un router incluido dentro de otro."""
    yield from _rutas_de(list(app.routes), "")


def _rutas_de(grupos: list[Any], prefijo: str) -> Iterator[tuple[str, str]]:
    for grupo in grupos:
        if isinstance(grupo, APIRoute):
            for metodo in grupo.methods or ():
                yield metodo, prefijo + grupo.path
        elif (router := getattr(grupo, "original_router", None)) is not None:
            yield from _rutas_de(list(router.routes), prefijo + grupo.include_context.prefix)
        # /docs, /redoc y /openapi.json no son operaciones de la API.


def test_cada_ruta_registrada_fuera_de_las_publicas_rechaza_sin_sesion() -> None:
    """@REV-02-ASM-03"""
    app = create_app()
    operaciones = sorted(op for op in _rutas(app) if op not in PUBLICAS)
    aceptadas = []

    with TestClient(app) as cliente:
        for metodo, ruta in operaciones:
            url = re.sub(r"\{[^}]*\}", "1", ruta)
            r = cliente.request(metodo, url, json=None if metodo == "GET" else {})
            if r.status_code != 401:
                aceptadas.append((metodo, ruta, r.status_code))

    assert not aceptadas, aceptadas
    assert len(operaciones) == PROTEGIDAS, len(operaciones)
