from functools import cache

import firebase_admin
from firebase_admin import auth

from app.aplicacion.errores import Duplicado
from app.config import config


@cache
def _app_firebase() -> firebase_admin.App:
    # Con FIREBASE_AUTH_EMULATOR_HOST definido, firebase-admin habla con el emulador.
    return firebase_admin.initialize_app(options={"projectId": config.firebase_project_id})


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
        auth.delete_user(uid, app=_app_firebase())
