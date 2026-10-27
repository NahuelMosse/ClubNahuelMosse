import asyncio
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI

from app import e2e_support, health
from app.modules import bookings, espacios, horarios, notificaciones, recuperacion, sedes, usuarios
from app.modules.notificaciones import barrer_cada
from app.shared import http_errors, input_validation
from app.shared.body_limit import BodyLimit
from app.shared.config import config


@asynccontextmanager
async def _lifespan(_: FastAPI) -> AsyncIterator[None]:
    sweep = (
        asyncio.create_task(barrer_cada(config.reminders_every))
        if config.reminders_every > 0
        else None
    )
    try:
        yield
    finally:
        if sweep is not None:
            sweep.cancel()
            with suppress(asyncio.CancelledError):
                await sweep


def create_app() -> FastAPI:
    app = FastAPI(
        title="ClubNahuelMosse API",
        version=config.version,
        description="API de reservas de espacios deportivos de ClubNahuelMosse.",
        lifespan=_lifespan,
    )
    app.add_middleware(BodyLimit)
    input_validation.install(app)
    http_errors.install(app)
    app.include_router(health.router)
    app.include_router(usuarios.router)
    app.include_router(recuperacion.router)
    app.include_router(sedes.router)
    app.include_router(espacios.router)
    app.include_router(horarios.router)
    app.include_router(bookings.router)
    app.include_router(notificaciones.router)
    # The outbox only opens against the emulator, never in production.
    if config.e2e_testing and os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        app.include_router(e2e_support.router)
    return app


app = create_app()
