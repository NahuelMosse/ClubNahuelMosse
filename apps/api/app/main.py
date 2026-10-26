import asyncio
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI

from app.config import config
from app.interfaz import (
    entradas,
    errores_http,
    espacios,
    horarios,
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


@asynccontextmanager
async def _ciclo_de_vida(_: FastAPI) -> AsyncIterator[None]:
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


def crear_app() -> FastAPI:
    app = FastAPI(
        title="ClubNahuelMosse API",
        version=config.version,
        description="API de reservas de espacios deportivos de ClubNahuelMosse.",
        lifespan=_ciclo_de_vida,
    )
    entradas.instalar(app)
    errores_http.instalar(app)
    app.include_router(salud.router)
    app.include_router(registro.router)
    app.include_router(sesion.router)
    app.include_router(recuperacion.router)
    app.include_router(sedes.router)
    app.include_router(espacios.router)
    app.include_router(horarios.router)
    app.include_router(reservas.router)
    app.include_router(notificaciones.router)
    # El buzón sólo se abre contra el emulador, nunca en producción.
    if config.pruebas and os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        app.include_router(pruebas.router)
    return app


app = crear_app()
