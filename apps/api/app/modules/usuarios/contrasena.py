# kit-shape: los contratos del cambio de contraseña y el caso de uso que los usa se leen juntos
import logging
from typing import Protocol
from uuid import UUID

from app.modules.sesion import Perfil
from app.modules.usuarios.reglas import problemas_contrasena
from app.shared.errors import InvalidData

NO_COINCIDE = "La contraseña actual no coincide"
contrasena_log = logging.getLogger("clubnahuelmosse.contrasena")


class ClavesDeIdentidad(Protocol):
    def password_matches(self, email: str, password: str) -> bool:
        """Lanza `RateLimited` si el proveedor frena por demasiados intentos."""
        ...

    def change_password(self, uid: str, new_password: str) -> None:
        """Cambia la contraseña e invalida todas las sesiones abiertas de la cuenta."""
        ...


class RastroDeContrasena(Protocol):
    def marcar_cambio_de_contrasena(self, id_usuario: UUID) -> None: ...


def cambiar_contrasena(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
    perfil: Perfil,
    actual: str,
    nueva: str,
    identidad: ClavesDeIdentidad,
    usuarios: RastroDeContrasena,
) -> None:
    """Reemplaza la contraseña de quien tiene la sesión, si confirma la actual."""
    if faltan := problemas_contrasena(nueva):
        raise InvalidData({"nueva": faltan[0]})
    if not actual or not identidad.password_matches(perfil.correo, actual):
        raise InvalidData({"actual": NO_COINCIDE})
    identidad.change_password(perfil.uid, nueva)
    # La contraseña ya cambió: si el rastro falla, la respuesta tiene que seguir diciendo que
    # cambió, o la persona intentaría entrar con la vieja.
    try:
        usuarios.marcar_cambio_de_contrasena(perfil.id)
    except Exception:
        contrasena_log.exception("no se pudo registrar el cambio de contraseña de %s", perfil.id)
