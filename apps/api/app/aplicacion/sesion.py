from typing import Protocol

from app.aplicacion.errores import NoAutenticado
from app.dominio.usuarios import Perfil


class VerificadorDeTokens(Protocol):
    def uid_del_token(self, token: str) -> str | None:
        """El uid de la cuenta si el token es válido y no venció; si no, None."""
        ...


class PerfilesActivos(Protocol):
    def perfil_activo(self, uid: str) -> Perfil | None: ...


def perfil_autenticado(
    token: str | None, identidad: VerificadorDeTokens, usuarios: PerfilesActivos
) -> Perfil:
    """El perfil de quien hace el pedido. Una cuenta sin perfil activo no está autenticada."""
    uid = identidad.uid_del_token(token) if token else None
    perfil = usuarios.perfil_activo(uid) if uid else None
    if perfil is None:
        raise NoAutenticado
    return perfil
