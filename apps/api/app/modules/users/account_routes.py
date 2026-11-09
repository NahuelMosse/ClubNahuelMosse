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

router = APIRouter(tags=["session"])


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
    summary="The profile and role of whoever signed in",
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
        429: {"description": "Too many attempts with the current password"},
    },
    summary="Change the password of whoever signed in",
    description="Invalidates every open session: the app signs in again with the new one.",
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
        409: {"model": PasswordErrors, "description": "Another account already has that DNI"},
        422: {"model": PasswordErrors},
    },
    summary="Edit the personal data of whoever signed in",
    description="Everything except the email, which cannot be changed.",
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
            content={"errors": {"dni": "This DNI is already registered"}},
        )
    updated = profiles.active_profile(profile.uid)
    if updated is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return own_profile(updated)


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": NoSession},
        403: {"description": "An administrator cannot be deleted from the app"},
    },
    summary="Delete the account of whoever signed in",
    description=(
        "Soft delete: the account stops being active, its bookings that have not started "
        "become cancelled and the history is kept."
    ),
)
def deactivate_own_account(
    profile: Annotated[Profile, Depends(current_user)],
    users: Annotated[UsersSql, Depends(user_repository)],
    provider: Annotated[FirebaseProvider, Depends(identity)],
) -> Response:
    deactivate(profile, users, provider)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
