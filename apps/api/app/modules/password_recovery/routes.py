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

router = APIRouter(tags=["password recovery"])

# The app's Android package: the link in the email opens it with this intent.
ANDROID_PACKAGE = "ar.edu.unimoron.clubnahuelmosse"


class LinkRequest(BaseModel):
    email: str = ""


class LinkCheck(BaseModel):
    code: str = ""


class NewPassword(BaseModel):
    code: str = ""
    new_password: str = ""


class FieldErrors(BaseModel):
    errors: dict[str, str]


@router.post(
    "/password-recovery",
    status_code=status.HTTP_202_ACCEPTED,
    responses={422: {"model": FieldErrors}},
    summary="Ask for a link to create a new password",
    description="Answers the same whether or not an account with that email exists.",
)
def request_recovery(
    request: LinkRequest,
    tasks: BackgroundTasks,
    links: Annotated[LinksSql, Depends(link_repository)],
) -> Response:
    message = request_link(request.email, config.public_url, links)
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
    "/password-recovery/check",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={410: {"description": "The link expired, was already used or was replaced"}},
    summary="Find out whether a recovery link still works",
)
def check_link(check: LinkCheck, links: Annotated[LinksSql, Depends(link_repository)]) -> Response:
    valid = bool(check.code) and link_is_valid(check.code, links)
    return Response(status_code=status.HTTP_204_NO_CONTENT if valid else status.HTTP_410_GONE)


@router.put(
    "/password-recovery",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        410: {"description": "The link expired, was already used or was replaced"},
        422: {"model": FieldErrors},
    },
    summary="Create the new password with the link",
    description="The link stops working and every session of the account is invalidated.",
)
def reset_password(
    request: NewPassword,
    links: Annotated[LinksSql, Depends(link_repository)],
    users: Annotated[UsersSql, Depends(user_repository)],
    provider: Annotated[FirebaseProvider, Depends(identity)],
) -> Response:
    try:
        use_link(
            request.code,
            request.new_password,
            links,
            identity=provider,
            users=users,
        )
    except InvalidLink:
        return Response(status_code=status.HTTP_410_GONE)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


_LINK_SCRIPT = f"""
  var code = new URLSearchParams(location.hash.slice(1)).get("code") || "";
  location.replace("intent://app/recuperar?codigo=" + encodeURIComponent(code) +
    "#Intent;scheme=clubnahuelmosse;package={ANDROID_PACKAGE};end");
"""

_LINK_PAGE = f"""<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ClubNahuelMosse</title>
<p>Opening the ClubNahuelMosse app…</p>
<p>If it does not open, open this email on the phone that has the app installed.</p>
<script>{_LINK_SCRIPT}</script>
</html>
"""

# The page only runs its own script: the browser recognizes it by its hash.
_SCRIPT_HASH = base64.b64encode(hashlib.sha256(_LINK_SCRIPT.encode("utf-8")).digest()).decode(
    "ascii"
)
_LINK_POLICY = f"default-src 'none'; script-src 'sha256-{_SCRIPT_HASH}'; frame-ancestors 'none'"


@router.get(
    "/link/recover",
    response_class=HTMLResponse,
    summary="Email link page: opens the app on the new password",
    description=(
        "Email clients do not make links with a custom scheme tappable; this https "
        "link takes the app through an Android intent."
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
