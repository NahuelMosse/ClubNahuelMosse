import contextlib
import json
import logging
import os
import urllib.error
import urllib.request
from functools import cache

import firebase_admin
from firebase_admin import auth

from app.shared.config import config
from app.shared.credencial_firebase import credencial_de_servicio
from app.shared.errores import Demorado, Duplicado

identidad_log = logging.getLogger("clubnahuelmosse.identidad")


@cache
def _app_firebase() -> firebase_admin.App:
    # Con FIREBASE_AUTH_EMULATOR_HOST definido, firebase-admin habla con el emulador.
    return firebase_admin.initialize_app(
        credential=credencial_de_servicio(),
        options={"projectId": config.firebase_project_id, "httpTimeout": _ESPERA_S},
    )


# Firebase no deja comprobar una contraseña desde el SDK de administración: se pregunta
# por la API REST de Identity Toolkit, igual que al iniciar sesión.
_RECHAZOS = {
    "INVALID_LOGIN_CREDENTIALS",
    "INVALID_PASSWORD",
    "MISSING_PASSWORD",
    "EMAIL_NOT_FOUND",
    "USER_DISABLED",
}
# Menos que los 15 s que espera la app: el servidor contesta antes de que ella se rinda.
_ESPERA_S = 4


def _url_de_ingreso() -> str:
    ruta = "identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
    if emulador := os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        return f"http://{emulador}/{ruta}?key=clave-del-emulador"
    if not config.firebase_api_key:
        raise RuntimeError("falta FIREBASE_API_KEY para comprobar contraseñas")
    return f"https://{ruta}?key={config.firebase_api_key}"


class ProveedorFirebase:
    def crear_cuenta(self, correo: str, contrasena: str) -> str:
        try:
            usuario = auth.create_user(email=correo, password=contrasena, app=_app_firebase())
        except auth.EmailAlreadyExistsError as e:
            raise Duplicado(["correo"]) from e
        return str(usuario.uid)

    def uid_de(self, correo: str) -> str | None:
        try:
            return str(auth.get_user_by_email(correo, app=_app_firebase()).uid)
        except auth.UserNotFoundError:
            return None

    def borrar_cuenta(self, uid: str) -> None:
        # Si ya no estaba, otro pedido la borró antes, que es lo que se quería.
        with contextlib.suppress(auth.UserNotFoundError):
            auth.delete_user(uid, app=_app_firebase())

    def uid_del_token(self, token: str) -> str | None:
        try:
            # check_revoked además rechaza cuentas deshabilitadas o borradas en Firebase.
            datos = auth.verify_id_token(token, app=_app_firebase(), check_revoked=True)
        except (auth.InvalidIdTokenError, auth.UserDisabledError, auth.UserNotFoundError):
            return None
        uid = datos.get("uid")
        return str(uid) if uid else None

    def contrasena_correcta(self, correo: str, contrasena: str) -> bool:
        pedido = urllib.request.Request(
            _url_de_ingreso(),
            data=json.dumps({"email": correo, "password": contrasena}).encode(),
            headers={"content-type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(pedido, timeout=_ESPERA_S):
                return True
        except urllib.error.HTTPError as e:
            # La respuesta de error es un recurso abierto: se cierra pase lo que pase.
            with e:
                if e.code != 400:
                    raise
                mensaje = str(json.loads(e.read()).get("error", {}).get("message", ""))
                if mensaje.startswith("TOO_MANY_ATTEMPTS"):
                    raise Demorado from e
                if mensaje.split(" ")[0] in _RECHAZOS:
                    return False
                raise

    def cambiar_contrasena(self, uid: str, nueva: str) -> None:
        auth.update_user(uid, password=nueva, app=_app_firebase())
        # Firebase ya invalida las sesiones al cambiar la contraseña; revocar explícitamente
        # lo asegura, pero si falla el cambio ya está hecho y no se informa como error.
        try:
            auth.revoke_refresh_tokens(uid, app=_app_firebase())
        except Exception:
            identidad_log.exception("no se pudieron revocar las sesiones de %s", uid)


def identidad() -> ProveedorFirebase:
    return ProveedorFirebase()
