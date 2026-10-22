import asyncio
import logging
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager, suppress
from typing import Any

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import InterfaceError, OperationalError
from sqlalchemy.exc import TimeoutError as SATimeoutError

from app.config import config
from app.infraestructura.db import base_disponible, esquema_al_dia
from app.interfaz import (
    entradas,
    espacios,
    horarios,
    limites,
    metricas,
    notificaciones,
    pruebas,
    recuperacion,
    registro,
    reservas,
    salud,
    sedes,
    sesion,
)
from app.interfaz.barrido import barrer_cada
from app.interfaz.protecciones import Protecciones
from app.interfaz.registro_errores import RegistroDeErrores, configurar_registro, referencia_actual


_registro = logging.getLogger("clubnahuelmosse.arranque")
_MENSAJE_BASE = "La base de datos no respondió a tiempo. Probá de nuevo en unos minutos."


async def _sin_base(request: Request, _: Exception) -> JSONResponse:
    """Una base caída, lenta o bloqueada es un 503 con referencia, no un 500 sin explicar."""
    referencia = referencia_actual()
    return JSONResponse(
        {"mensaje": _MENSAJE_BASE, "referencia": referencia},
        status_code=503,
        headers={"X-Request-ID": referencia},
    )


async def _verificar_arranque() -> None:
    """El proceso sigue en pie sin base o sin esquema: /ready dice 503 y el aviso queda en el log."""
    if not await asyncio.to_thread(base_disponible):
        _registro.error("arranque_sin_base: la base de datos no responde")
    elif not await asyncio.to_thread(esquema_al_dia):
        _registro.error("arranque_sin_esquema: el esquema de la base no está al día")


@asynccontextmanager
async def _ciclo_de_vida(_: FastAPI) -> AsyncIterator[None]:
    await _verificar_arranque()
    barrido = (
        asyncio.create_task(barrer_cada(config.recordatorios_cada))
        if config.recordatorios_cada > 0
        else None
    )
    try:
        yield
    finally:
        if barrido is not None:
            barrido.cancel()
            with suppress(asyncio.CancelledError):
                await barrido


def _exigir_emulador_aislado() -> None:
    """Con el emulador de Firebase en el entorno no puede haber credenciales ni proyecto reales:
    el emulador acepta cualquier token y sería una puerta abierta a la cuenta real."""
    if not os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        return
    if (
        config.firebase_credenciales_json
        or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        or not config.firebase_project_id.startswith("demo-")
    ):
        raise RuntimeError(
            "La API no arranca con el emulador de Firebase junto a credenciales o un proyecto "
            "reales: el emulador exige un proyecto demo-* y ninguna credencial."
        )


def _documentar_el_400(app: FastAPI) -> None:
    """Todas las rutas salvo /health responden 400 ante un Host ajeno o un Content-Length
    inválido; el contrato lo declara una sola vez acá."""
    original = app.openapi

    def con_400() -> dict[str, Any]:
        if app.openapi_schema is None:
            esquema = original()
            for ruta, operaciones in esquema["paths"].items():
                if ruta in ("/health", "/ready"):
                    continue
                for operacion in operaciones.values():
                    operacion["responses"].setdefault(
                        "400",
                        {
                            "description": (
                                "Host no permitido, Content-Length inválido o cuerpo que no es JSON"
                            ),
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "detail": {"type": "string"},
                                            "errores": {
                                                "type": "object",
                                                "additionalProperties": {"type": "string"},
                                            },
                                        },
                                    }
                                }
                            },
                        },
                    )
        return app.openapi_schema or {}

    app.openapi = con_400  # type: ignore[method-assign]


def crear_app() -> FastAPI:
    _exigir_emulador_aislado()
    configurar_registro()
    app = FastAPI(
        title="ClubNahuelMosse API",
        version=config.version,
        description="API de reservas de espacios deportivos de ClubNahuelMosse.",
        lifespan=_ciclo_de_vida,
        docs_url="/docs" if config.documentacion_interactiva else None,
        redoc_url="/redoc" if config.documentacion_interactiva else None,
        responses={
            500: {"description": "Error inesperado, con una referencia para soporte."},
            503: {"description": "La base de datos no respondió."},
        },
    )
    # Un SQL mal armado (ProgrammingError) es un error propio y sigue siendo un 500.
    for error in (OperationalError, InterfaceError, SATimeoutError):
        app.add_exception_handler(error, _sin_base)
    entradas.instalar(app)
    limites.instalar(app)
    app.include_router(salud.router)
    app.include_router(metricas.router)
    app.include_router(registro.router)
    app.include_router(sesion.router)
    app.include_router(recuperacion.router)
    app.include_router(sedes.router)
    app.include_router(espacios.router)
    app.include_router(horarios.router)
    app.include_router(reservas.router)
    app.include_router(notificaciones.router)
    # Un segundo candado: el buzón sólo se abre contra el emulador, nunca en producción.
    if config.pruebas and os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        app.include_router(pruebas.router)
    # El último que se agrega es el de afuera: el registro ve también lo que Protecciones rechaza.
    app.add_middleware(Protecciones)
    app.add_middleware(RegistroDeErrores)
    _documentar_el_400(app)
    return app


app = crear_app()
