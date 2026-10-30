from fastapi import APIRouter

from app.shared.config import config

router = APIRouter(tags=["operations"])


@router.get(
    "/health",
    summary="API liveness check, without touching dependencies",
    description="The API is alive; it does not check the database or Firebase.",
)
def alive() -> dict[str, str]:
    return {"status": "ok", "version": config.version}
