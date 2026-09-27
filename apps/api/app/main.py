from fastapi import FastAPI

from app.interfaz import registro
from app.interfaz.protecciones import Protecciones


def crear_app() -> FastAPI:
    app = FastAPI(
        title="ClubNahuelMosse API",
        version="0.1.0",
        description="API de reservas de espacios deportivos de ClubNahuelMosse.",
    )
    app.include_router(registro.router)
    app.add_middleware(Protecciones)
    return app


app = crear_app()
