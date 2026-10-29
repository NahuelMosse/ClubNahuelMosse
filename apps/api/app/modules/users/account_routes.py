# kit-shape: the account routes and the models of their requests and responses are read together
from datetime import date as date_type
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.session import NoSession, Profile, Profiles, Role, current_user
from app.modules.users.deactivation import deactivate
from app.modules.users.password import change_password
from app.modules.users.profile import update_profile
from app.modules.users.repository import UsersSql, user_repository
from app.modules.users.rules import PersonalData
from app.shared.club_timezone import CLUB_TIMEZONE
from app.shared.errors import Duplicate, RateLimited
from app.shared.identity import FirebaseProvider, identity

router = APIRouter(tags=["sesión"])


class OwnProfile(BaseModel):
    first_name: str
    last_name: str
    email: str
    role: Role
    dni: str
    birth_date: date_type


@router.get(
    "/me",
    response_model=OwnProfile,
    responses={401: {"model": NoSession}},
    summary="El perfil y el rol de quien inició sesión",
)
def own_profile(profile: Annotated[Profile, Depends(current_user)]) -> OwnProfile:
    return OwnProfile(
        first_name=profile.first_name,
        last_name=profile.last_name,
        email=profile.email,
        role=profile.role,
        dni=profile.dni,
        birth_date=profile.birth_date,
    )


class PasswordChangeRequest(BaseModel):
    current_password: str = ""
    new_password: str = ""


class PasswordErrors(BaseModel):
    errors: dict[str, str]


@router.put(
    "/me/password",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        422: {"model": PasswordErrors},
        429: {"description": "Demasiados intentos con la contraseña actual"},
    },
    summary="Cambiar la contraseña de quien inició sesión",
    description="Invalida todas las sesiones abiertas: la app vuelve a entrar con la nueva.",
)
def change_own_password(
    request: PasswordChangeRequest,
    profile: Annotated[Profile, Depends(current_user)],
    users: Annotated[UsersSql, Depends(user_repository)],
    provider: Annotated[FirebaseProvider, Depends(identity)],
) -> Response:
    try:
        change_password(
            profile,
            request.current_password,
            request.new_password,
            identity=provider,
            users=users,
        )
    except RateLimited:
        return Response(status_code=status.HTTP_429_TOO_MANY_REQUESTS)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class ProfileEditRequest(BaseModel):
    first_name: str = ""
    last_name: str = ""
    dni: str = ""
    birth_date: str = ""


@router.put(
    "/me",
    response_model=OwnProfile,
    responses={
        401: {"model": NoSession},
        409: {"model": PasswordErrors, "description": "Otra cuenta ya tiene ese DNI"},
        422: {"model": PasswordErrors},
    },
    summary="Editar los datos personales de quien inició sesión",
    description="Todo menos el correo, que no se puede cambiar.",
)
def update_own_profile(
    request: ProfileEditRequest,
    profile: Annotated[Profile, Depends(current_user)],
    users: Annotated[UsersSql, Depends(user_repository)],
    profiles: Profiles,
) -> OwnProfile | JSONResponse:
    try:
        update_profile(
            profile,
            PersonalData(
                first_name=request.first_name,
                last_name=request.last_name,
                dni=request.dni,
                birth_date=request.birth_date,
            ),
            today=datetime.now(CLUB_TIMEZONE).date(),
            users=users,
        )
    except Duplicate:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"errors": {"dni": "Este DNI ya está registrado"}},
        )
    updated = profiles.active_profile(profile.uid)
    if updated is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión inválida o vencida",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return own_profile(updated)


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        403: {"description": "Un administrador no se da de baja desde la app"},
    },
    summary="Dar de baja la cuenta de quien inició sesión",
    description=(
        "Baja lógica: la cuenta deja de estar activa, sus reservas que todavía no empezaron "
        "pasan a canceladas y el historial se conserva."
    ),
)
def deactivate_own_account(
    profile: Annotated[Profile, Depends(current_user)],
    users: Annotated[UsersSql, Depends(user_repository)],
    provider: Annotated[FirebaseProvider, Depends(identity)],
) -> Response:
    deactivate(profile, users, provider)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
