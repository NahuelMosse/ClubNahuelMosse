from fastapi import APIRouter

from app.shared.config import config

router = APIRouter(tags=["operación"])


@router.get(
    "/health",
    summary="Chequeo de vida de la API, sin tocar dependencias",
    description="La API está viva; no mira la base ni Firebase.",
    operation_id="vivo_health_get",
)
def alive() -> dict[str, str]:
    return {"estado": "vivo", "version": config.version}
