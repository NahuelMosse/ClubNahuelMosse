import logging
from typing import Protocol

from app.dominio.usuarios import problemas_contrasena
from app.modules.sesion import Perfil
from app.shared.errores import DatosInvalidos

NO_COINCIDE = "La contraseña actual no coincide"
contrasena_log = logging.getLogger("clubnahuelmosse.contrasena")


class ClavesDeIdentidad(Protocol):
    def contrasena_correcta(self, correo: str, contrasena: str) -> bool:
        """Lanza `Demorado` si el proveedor frena por demasiados intentos."""
        ...

    def cambiar_contrasena(self, uid: str, nueva: str) -> None:
        """Cambia la contraseña e invalida todas las sesiones abiertas de la cuenta."""
        ...


class RastroDeContrasena(Protocol):
    def marcar_cambio_de_contrasena(self, id_usuario: int) -> None: ...


def cambiar_contrasena(
    perfil: Perfil,
    actual: str,
    nueva: str,
    identidad: ClavesDeIdentidad,
    usuarios: RastroDeContrasena,
) -> None:
    """Reemplaza la contraseña de quien tiene la sesión, si confirma la actual."""
    if faltan := problemas_contrasena(nueva):
        raise DatosInvalidos({"nueva": faltan[0]})
    if not actual or not identidad.contrasena_correcta(perfil.correo, actual):
        raise DatosInvalidos({"actual": NO_COINCIDE})
    identidad.cambiar_contrasena(perfil.uid, nueva)
    # La contraseña ya cambió: si el rastro falla, la respuesta tiene que seguir diciendo que
    # cambió, o la persona intentaría entrar con la vieja.
    try:
        usuarios.marcar_cambio_de_contrasena(perfil.id)
    except Exception:
        contrasena_log.exception("no se pudo registrar el cambio de contraseña de %s", perfil.id)
