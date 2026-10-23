from fastapi import APIRouter
from fastapi.responses import JSONResponse

from app.config import config
from app.dependencias import base_disponible, esquema_al_dia
from app.interfaz.registro_errores import referencia_actual

router = APIRouter(tags=["operación"])


@router.get("/health", summary="Chequeo de vida de la API, sin tocar dependencias")
def vivo() -> dict[str, str]:
    """La API está viva; no mira la base ni Firebase."""
    return {"estado": "vivo", "version": config.version}


@router.get("/ready", responses={503: {"description": "Sin base o sin esquema al día."}})
def lista() -> JSONResponse:
    """La API puede atender: tiene base y el esquema está al día."""
    if base_disponible() and esquema_al_dia():
        return JSONResponse({"estado": "lista", "version": config.version})
    return JSONResponse(
        {"mensaje": "La API todavía no está lista.", "referencia": referencia_actual()},
        status_code=503,
    )
