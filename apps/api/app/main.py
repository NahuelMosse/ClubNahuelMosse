from fastapi import FastAPI

from app.interfaz import registro


def crear_app() -> FastAPI:
    app = FastAPI(
        title="ClubNahuelMosse API",
        version="0.1.0",
        description="API de reservas de espacios deportivos de ClubNahuelMosse.",
    )
    app.include_router(registro.router)
    return app


app = crear_app()
