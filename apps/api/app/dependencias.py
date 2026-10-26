"""Donde la API arma lo que sus casos de uso necesitan de afuera para las funcionalidades que
todavía están en capas: los repositorios de usuarios y enlaces y el correo."""

from app.infraestructura.correo import enviar as enviar_correo
from app.infraestructura.enlaces import EnlacesSql
from app.infraestructura.usuarios import UsuariosSql
from app.shared.db import Conexion


# Un repositorio por pedido: todos arman sobre la misma conexión, que FastAPI resuelve una vez.
def repositorio_usuarios(conn: Conexion) -> UsuariosSql:
    return UsuariosSql(conn)


def repositorio_enlaces(conn: Conexion) -> EnlacesSql:
    return EnlacesSql(conn)


__all__ = [
    "EnlacesSql",
    "UsuariosSql",
    "enviar_correo",
    "repositorio_enlaces",
    "repositorio_usuarios",
]
