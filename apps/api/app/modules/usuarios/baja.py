# kit-shape: los contratos de la baja y el caso de uso que los usa se leen juntos
import logging
from typing import Protocol
from uuid import UUID

from app.modules.sesion import Perfil
from app.shared.errores import Prohibido

baja_log = logging.getLogger("clubnahuelmosse.baja")


class CuentasQueSeDanDeBaja(Protocol):
    def dar_de_baja(self, id_usuario: UUID) -> bool:
        """Baja lógica: la cuenta deja de estar activa y sus reservas que todavía no
        empezaron pasan a canceladas por ella. Todo en una transacción. Devuelve False si la
        cuenta ya estaba de baja."""
        ...


class CuentasDelProveedor(Protocol):
    def borrar_cuenta(self, uid: str) -> None: ...


def dar_de_baja(
    perfil: Perfil, usuarios: CuentasQueSeDanDeBaja, identidad: CuentasDelProveedor
) -> None:
    """Da de baja la cuenta de quien tiene la sesión. El historial queda en la base."""
    if perfil.rol != "usuario":
        raise Prohibido("un administrador no se da de baja desde la app")
    if not usuarios.dar_de_baja(perfil.id):
        return
    # La baja ya está hecha: sin perfil activo, ningún token de esa cuenta pasa la API.
    # Borrarla del proveedor libera el correo; si falla, el registro la reemplaza.
    try:
        identidad.borrar_cuenta(perfil.uid)
    except Exception:
        baja_log.exception("no se pudo borrar del proveedor la cuenta %s", perfil.id)
