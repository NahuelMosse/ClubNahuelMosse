from fastapi import APIRouter

router = APIRouter(tags=["salud"])


@router.get("/health", summary="Chequeo de vida de la API, sin tocar dependencias")
def salud() -> dict[str, str]:
    """Responde 200 mientras el proceso atiende; no consulta la base ni Firebase."""
    return {"estado": "vivo"}
