from fastapi import APIRouter

from app.config import config

router = APIRouter(tags=["operación"])


@router.get("/health", summary="Chequeo de vida de la API, sin tocar dependencias")
def vivo() -> dict[str, str]:
    """La API está viva; no mira la base ni Firebase."""
    return {"estado": "vivo", "version": config.version}
