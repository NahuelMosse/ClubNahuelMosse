# kit-shape: the registration routes and the models of their bodies are read together
from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.users.registration import register
from app.modules.users.repository import UsersSql, user_repository
from app.modules.users.rules import RegistrationData
from app.shared.club_timezone import CLUB_TIMEZONE
from app.shared.errors import Duplicate
from app.shared.identity import FirebaseProvider, identity

router = APIRouter(tags=["usuarios"])
DUPLICATE_MESSAGE: str = "El usuario ya está registrado. Modificá el correo o el DNI."
FIELD_MESSAGES = {
    "email": "Este correo ya está registrado",
    "dni": "Este DNI ya está registrado",
}


class RegistrationRequest(BaseModel):
    first_name: str = ""
    last_name: str = ""
    dni: str = ""
    birth_date: str = ""
    email: str = ""
    password: str = ""


class RegistrationCreated(BaseModel):
    id: UUID


class FieldErrors(BaseModel):
    errors: dict[str, str]


class DuplicateUser(BaseModel):
    message: str
    fields: list[str]
    errors: dict[str, str]


@router.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
    response_model=RegistrationCreated,
    responses={
        422: {"model": FieldErrors},
        409: {"model": DuplicateUser},
    },
    summary="Registrar un usuario nuevo",
)
def register_user(
    request: RegistrationRequest,
    users: Annotated[UsersSql, Depends(user_repository)],
    provider: Annotated[FirebaseProvider, Depends(identity)],
) -> RegistrationCreated | JSONResponse:
    try:
        new = register(
            RegistrationData(
                first_name=request.first_name,
                last_name=request.last_name,
                dni=request.dni,
                birth_date=request.birth_date,
                email=request.email,
                password=request.password,
            ),
            today=datetime.now(CLUB_TIMEZONE).date(),
            identity=provider,
            users=users,
        )
    except Duplicate as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={
                "message": DUPLICATE_MESSAGE,
                "fields": e.fields,
                "errors": {c: FIELD_MESSAGES[c] for c in e.fields},
            },
        )
    return RegistrationCreated(id=new)
