# kit-shape: the recovery routes and the models of their requests and responses are read together
import base64
import hashlib
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, Response, status
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

from app.modules.password_recovery.repository import LinksSql, link_repository
from app.modules.password_recovery.use_cases import (
    InvalidLink,
    link_is_valid,
    request_link,
    use_link,
)
from app.modules.users import UsersSql, user_repository
from app.shared.config import config
from app.shared.email import send
from app.shared.identity import FirebaseProvider, identity

router = APIRouter(tags=["recuperación de contraseña"])

# The app's Android package: the link in the email opens it with this intent.
ANDROID_PACKAGE = "ar.edu.unimoron.clubnahuelmosse"


class LinkRequest(BaseModel):
    correo: str = ""


class LinkCheck(BaseModel):
    codigo: str = ""


class NewPassword(BaseModel):
    codigo: str = ""
    nueva: str = ""


class FieldErrors(BaseModel):
    errores: dict[str, str]


@router.post(
    "/recuperacion",
    operation_id="pedir_recuperacion_post",
    status_code=status.HTTP_202_ACCEPTED,
    responses={422: {"model": FieldErrors}},
    summary="Pedir un enlace para crear una contraseña nueva",
    description="Responde lo mismo exista o no una cuenta con ese correo.",
)
def request_recovery(
    request: LinkRequest,
    tasks: BackgroundTasks,
    links: Annotated[LinksSql, Depends(link_repository)],
) -> Response:
    message = request_link(request.correo, config.public_url, links)
    if message is not None:
        if config.email_mode == "outbox":
            # In development and scenarios the outbox is filled before responding, so the
            # email is already there when the app shows «Revisá tu correo».
            send(message)
        else:
            # Over SMTP, after responding: the delay does not reveal that the account exists.
            tasks.add_task(send, message)
    return Response(status_code=status.HTTP_202_ACCEPTED)


# The codes travel in the body, not in the path: the path ends up in the request logs.
@router.post(
    "/recuperacion/consulta",
    operation_id="consultar_recuperacion_consulta_post",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={410: {"description": "El enlace venció, ya se usó o fue reemplazado"}},
    summary="Saber si un enlace de recuperación sigue sirviendo",
)
def check_link(check: LinkCheck, links: Annotated[LinksSql, Depends(link_repository)]) -> Response:
    valid = bool(check.codigo) and link_is_valid(check.codigo, links)
    return Response(status_code=status.HTTP_204_NO_CONTENT if valid else status.HTTP_410_GONE)


@router.put(
    "/recuperacion",
    operation_id="usar_recuperacion_put",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        410: {"description": "El enlace venció, ya se usó o fue reemplazado"},
        422: {"model": FieldErrors},
    },
    summary="Crear la contraseña nueva con el enlace",
    description="El enlace deja de servir y se invalidan todas las sesiones de la cuenta.",
)
def reset_password(
    request: NewPassword,
    links: Annotated[LinksSql, Depends(link_repository)],
    users: Annotated[UsersSql, Depends(user_repository)],
    provider: Annotated[FirebaseProvider, Depends(identity)],
) -> Response:
    try:
        use_link(
            request.codigo,
            request.nueva,
            links,
            identity=provider,
            users=users,
        )
    except InvalidLink:
        return Response(status_code=status.HTTP_410_GONE)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


_LINK_SCRIPT = f"""
  var codigo = new URLSearchParams(location.hash.slice(1)).get("codigo") || "";
  location.replace("intent://app/recuperar?codigo=" + encodeURIComponent(codigo) +
    "#Intent;scheme=clubnahuelmosse;package={ANDROID_PACKAGE};end");
"""

_LINK_PAGE = f"""<!doctype html>
<html lang="es">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ClubNahuelMosse</title>
<p>Abriendo la app de ClubNahuelMosse…</p>
<p>Si no se abre, abrí este correo desde el teléfono que tiene la app instalada.</p>
<script>{_LINK_SCRIPT}</script>
</html>
"""

# The page only runs its own script: the browser recognizes it by its hash.
_SCRIPT_HASH = base64.b64encode(hashlib.sha256(_LINK_SCRIPT.encode("utf-8")).digest()).decode(
    "ascii"
)
_LINK_POLICY = f"default-src 'none'; script-src 'sha256-{_SCRIPT_HASH}'; frame-ancestors 'none'"


@router.get(
    "/enlace/recuperar",
    operation_id="pagina_del_enlace_enlace_recuperar_get",
    response_class=HTMLResponse,
    summary="Página del enlace del correo: abre la app en la contraseña nueva",
    description=(
        "Los clientes de correo no vuelven tocables los enlaces con esquema propio; este "
        "enlace https lleva a la app con un intent de Android."
    ),
)
def link_page() -> HTMLResponse:
    return HTMLResponse(
        _LINK_PAGE,
        headers={
            "Referrer-Policy": "no-referrer",
            "Content-Security-Policy": _LINK_POLICY,
        },
    )
