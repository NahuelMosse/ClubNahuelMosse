import asyncio
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI

from app import pruebas, salud
from app.modules import espacios, horarios, notificaciones, recuperacion, reservas, sedes, usuarios
from app.modules.notificaciones import barrer_cada
from app.shared import entradas, errores_http
from app.shared.config import config
from app.shared.cuerpo import CuerpoAcotado


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
    app.add_middleware(CuerpoAcotado)
    entradas.instalar(app)
    errores_http.instalar(app)
    app.include_router(salud.router)
    app.include_router(usuarios.router)
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
