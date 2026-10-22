import uuid

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

from app.config import config
from app.infraestructura.db import base_disponible, esquema_al_dia

router = APIRouter(tags=["operación"])


@router.get("/health", summary="Chequeo de vida de la API, sin tocar dependencias")
def vivo() -> dict[str, str]:
    """La API está viva; no mira la base ni Firebase."""
    return {"estado": "vivo", "version": config.version}


@router.get("/ready", responses={503: {"description": "Sin base o sin esquema al día."}})
def lista(request: Request) -> JSONResponse:
    """La API puede atender: tiene base y el esquema está al día."""
    if base_disponible() and esquema_al_dia():
        return JSONResponse({"estado": "lista", "version": config.version})
    referencia = request.headers.get("x-request-id") or str(uuid.uuid4())
    return JSONResponse(
        {"mensaje": "La API todavía no está lista.", "referencia": referencia}, status_code=503
    )
