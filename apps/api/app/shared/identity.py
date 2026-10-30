import contextlib
import json
import logging
import os
import urllib.error
import urllib.request
from functools import cache
from http import HTTPStatus

import firebase_admin
from firebase_admin import auth

from app.shared.config import config
from app.shared.errors import Duplicate, RateLimited
from app.shared.firebase_credential import service_credential

identity_log = logging.getLogger("clubnahuelmosse.identidad")


@cache
def _firebase_app() -> firebase_admin.App:
    # With FIREBASE_AUTH_EMULATOR_HOST set, firebase-admin talks to the emulator.
    return firebase_admin.initialize_app(
        credential=service_credential(),
        options={"projectId": config.firebase_project_id, "httpTimeout": _TIMEOUT_S},
    )


# Firebase does not allow checking a password from the admin SDK: it is asked through
# the Identity Toolkit REST API, just like at sign-in.
_REJECTIONS = {
    "INVALID_LOGIN_CREDENTIALS",
    "INVALID_PASSWORD",
    "MISSING_PASSWORD",
    "EMAIL_NOT_FOUND",
    "USER_DISABLED",
}
# Less than the 15 s the app waits: the server answers before the app gives up.
_TIMEOUT_S = 4


def _sign_in_url() -> str:
    path = "identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
    if emulator := os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        return f"http://{emulator}/{path}?key=clave-del-emulador"
    if not config.firebase_api_key:
        raise RuntimeError("falta FIREBASE_API_KEY para comprobar contraseñas")
    return f"https://{path}?key={config.firebase_api_key}"


class FirebaseProvider:
    def create_account(self, email: str, password: str) -> str:
        try:
            user = auth.create_user(email=email, password=password, app=_firebase_app())
        except auth.EmailAlreadyExistsError as e:
            raise Duplicate(["email"]) from e
        return str(user.uid)

    def uid_of(self, email: str) -> str | None:
        try:
            return str(auth.get_user_by_email(email, app=_firebase_app()).uid)
        except auth.UserNotFoundError:
            return None

    def delete_account(self, uid: str) -> None:
        # If it was already gone, another request deleted it first, which is what was wanted.
        with contextlib.suppress(auth.UserNotFoundError):
            auth.delete_user(uid, app=_firebase_app())

    def uid_from_token(self, token: str) -> str | None:
        try:
            # check_revoked also rejects accounts disabled or deleted in Firebase.
            claims = auth.verify_id_token(token, app=_firebase_app(), check_revoked=True)
        except (auth.InvalidIdTokenError, auth.UserDisabledError, auth.UserNotFoundError):
            return None
        uid = claims.get("uid")
        return str(uid) if uid else None

    def password_matches(self, email: str, password: str) -> bool:
        request = urllib.request.Request(
            _sign_in_url(),
            data=json.dumps({"email": email, "password": password}).encode(),
            headers={"content-type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=_TIMEOUT_S):
                return True
        except urllib.error.HTTPError as e:
            # The error response is an open resource: it is closed no matter what.
            with e:
                if e.code != HTTPStatus.BAD_REQUEST:
                    raise
                message = str(json.loads(e.read()).get("error", {}).get("message", ""))
                if message.startswith("TOO_MANY_ATTEMPTS"):
                    raise RateLimited from e
                if message.split(" ")[0] in _REJECTIONS:
                    return False
                raise

    def change_password(self, uid: str, new_password: str) -> None:
        auth.update_user(uid, password=new_password, app=_firebase_app())
        # Firebase already invalidates sessions when the password changes; revoking explicitly
        # makes sure of it, but if it fails the change is done and it is not reported as an error.
        try:
            auth.revoke_refresh_tokens(uid, app=_firebase_app())
        except Exception:
            identity_log.exception("no se pudieron revocar las sesiones de %s", uid)


def identity() -> FirebaseProvider:
    return FirebaseProvider()
