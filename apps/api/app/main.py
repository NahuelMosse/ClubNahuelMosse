import asyncio
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI

from app.config import config
from app.interfaz import (
    entradas,
    espacios,
    horarios,
    limites,
    notificaciones,
    pruebas,
    recuperacion,
    registro,
    reservas,
    sedes,
    sesion,
)
from app.interfaz.barrido import barrer_cada
from app.interfaz.protecciones import Protecciones
from app.interfaz.registro_errores import RegistroDeErrores, configurar_registro


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
    configurar_registro()
    app = FastAPI(
        title="ClubNahuelMosse API",
        version="0.1.0",
        description="API de reservas de espacios deportivos de ClubNahuelMosse.",
        lifespan=_ciclo_de_vida,
    )
    entradas.instalar(app)
    limites.instalar(app)
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
    app.add_middleware(RegistroDeErrores)
    app.add_middleware(Protecciones)
    return app


app = crear_app()
