import asyncio
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager, suppress
from typing import Any

from fastapi import FastAPI

from app import e2e_support, health
from app.modules import (
    availability,
    bookings,
    notifications,
    password_recovery,
    spaces,
    users,
    venues,
)
from app.modules.notifications import sweep_every
from app.shared import http_errors, input_validation
from app.shared.body_limit import BodyLimit
from app.shared.config import config


@asynccontextmanager
async def _lifespan(_: FastAPI) -> AsyncIterator[None]:
    sweep = (
        asyncio.create_task(sweep_every(config.reminders_every))
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


BODY_ERRORS = {
    "400": "El cuerpo no se puede leer",
    "408": "El cuerpo no llegó entero en 5 segundos",
    "413": "El cuerpo supera 1 MB",
}
BODY_ERROR_SCHEMA = {
    "type": "object",
    "properties": {"errors": {"type": "object", "additionalProperties": {"type": "string"}}},
    "required": ["errors"],
}
BODY_ERROR_CONTENT = {"application/json": {"schema": {"$ref": "#/components/schemas/BodyError"}}}


def _document_body_errors(app: FastAPI) -> dict[str, Any]:
    """BodyLimit and input_validation answer outside each route, so FastAPI does not know them."""
    if app.openapi_schema is None:
        schema = FastAPI.openapi(app)
        schema["components"]["schemas"]["BodyError"] = BODY_ERROR_SCHEMA
        for methods in schema["paths"].values():
            for operation in methods.values():
                if "requestBody" not in operation:
                    continue
                for status, description in BODY_ERRORS.items():
                    operation["responses"][status] = {
                        "description": description,
                        "content": BODY_ERROR_CONTENT,
                    }
        app.openapi_schema = schema
    return app.openapi_schema


def create_app() -> FastAPI:
    app = FastAPI(
        title="ClubNahuelMosse API",
        version=config.version,
        description="API de reservas de espacios deportivos de ClubNahuelMosse.",
        lifespan=_lifespan,
    )
    app.openapi = lambda: _document_body_errors(app)  # type: ignore[method-assign]
    app.add_middleware(BodyLimit)
    input_validation.install(app)
    http_errors.install(app)
    app.include_router(health.router)
    app.include_router(users.router)
    app.include_router(password_recovery.router)
    app.include_router(venues.router)
    app.include_router(spaces.router)
    app.include_router(availability.router)
    app.include_router(bookings.router)
    app.include_router(notifications.router)
    # The outbox only opens against the emulator, never in production.
    if config.e2e_testing and os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        app.include_router(e2e_support.router)
    return app


app = create_app()
