# kit-shape: the model of the no-session response and the current-user dependency go together
from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel

from app.modules.session.profile import Profile
from app.modules.session.repository import Profiles
from app.modules.session.use_cases import authenticated_profile
from app.shared.errors import NotAuthenticated
from app.shared.identity import FirebaseProvider, identity

_bearer = HTTPBearer(auto_error=False, description="ID token de Firebase Authentication")


class NoSession(BaseModel):
    detail: str


def current_user(
    request: Request,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    profiles: Profiles,
    provider: Annotated[FirebaseProvider, Depends(identity)],
) -> Profile:
    """Who makes the request, according to the Firebase token in the `Authorization` header."""
    try:
        return authenticated_profile(
            credentials.credentials if credentials else None,
            identity=provider,
            users=profiles,
        )
    except NotAuthenticated as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión inválida o vencida",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
