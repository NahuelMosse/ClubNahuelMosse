import os

from fastapi import FastAPI

from app.config import config
from app.interfaz import espacios, pruebas, recuperacion, registro, sedes, sesion
from app.interfaz.protecciones import Protecciones


def crear_app() -> FastAPI:
    app = FastAPI(
        title="ClubNahuelMosse API",
        version="0.1.0",
        description="API de reservas de espacios deportivos de ClubNahuelMosse.",
    )
    app.include_router(registro.router)
    app.include_router(sesion.router)
    app.include_router(recuperacion.router)
    app.include_router(sedes.router)
    app.include_router(espacios.router)
    # Un segundo candado: el buzón sólo se abre contra el emulador, nunca en producción.
    if config.pruebas and os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        app.include_router(pruebas.router)
    app.add_middleware(Protecciones)
    return app


app = crear_app()
