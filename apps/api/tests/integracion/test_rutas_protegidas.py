"""Toda operación registrada en la API, publicada o no en OpenAPI, pide sesión salvo las
públicas."""

import re
from collections.abc import Iterator
from typing import Any

from fastapi import FastAPI
from fastapi.routing import APIRoute
from fastapi.testclient import TestClient

from app.main import crear_app

# Lo que la API sirve sin sesión: alta de cuenta y recuperación de contraseña, con la página
# del enlace del correo.
PUBLICAS = {
    ("POST", "/registro"),
    ("POST", "/recuperacion"),
    ("POST", "/recuperacion/consulta"),
    ("PUT", "/recuperacion"),
    ("GET", "/enlace/recuperar"),
    ("GET", "/health"),
    ("GET", "/ready"),
    ("GET", "/metrics"),
}
PROTEGIDAS = 28


def _rutas(app: FastAPI) -> Iterator[tuple[str, str]]:
    """Método y ruta de cada operación; FastAPI agrupa los routers incluidos en `app.routes`."""
    grupos: list[Any] = list(app.routes)
    for grupo in grupos:
        if isinstance(grupo, APIRoute):
            registradas, prefijo = [grupo], ""
        elif (router := getattr(grupo, "original_router", None)) is not None:
            registradas = [r for r in router.routes if isinstance(r, APIRoute)]
            prefijo = grupo.include_context.prefix
        else:
            continue  # /docs, /redoc y /openapi.json
        for r in registradas:
            for metodo in r.methods or ():
                yield metodo, prefijo + r.path


def test_cada_ruta_registrada_fuera_de_las_publicas_rechaza_sin_sesion() -> None:
    app = crear_app()
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
