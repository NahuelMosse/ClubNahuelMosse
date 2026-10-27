from fastapi import APIRouter

from app.modules.users.account_routes import router as _account_routes
from app.modules.users.registration_routes import router as _registration_routes
from app.modules.users.repository import UsersSql, user_repository
from app.modules.users.rules import normalize_email, password_problems, valid_email

router = APIRouter()
router.include_router(_registration_routes)
router.include_router(_account_routes)

__all__ = [
    "UsersSql",
    "normalize_email",
    "password_problems",
    "router",
    "user_repository",
    "valid_email",
]
