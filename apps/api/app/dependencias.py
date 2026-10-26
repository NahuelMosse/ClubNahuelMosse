"""Donde la API arma lo que sus casos de uso necesitan de afuera para las funcionalidades que
todavía están en capas: los repositorios, el servicio de notificaciones, el correo y los enlaces."""

from app.infraestructura.correo import enviar as enviar_correo
from app.infraestructura.enlaces import EnlacesSql
from app.infraestructura.notificaciones import NotificacionesSql
from app.infraestructura.push import canal_push
from app.infraestructura.reservas import ReservasSql
from app.infraestructura.usuarios import UsuariosSql
from app.shared.db import Conexion


# Un repositorio por pedido: todos arman sobre la misma conexión, que FastAPI resuelve una vez.
def repositorio_reservas(conn: Conexion) -> ReservasSql:
    return ReservasSql(conn)


def repositorio_usuarios(conn: Conexion) -> UsuariosSql:
    return UsuariosSql(conn)


def repositorio_notificaciones(conn: Conexion) -> NotificacionesSql:
    return NotificacionesSql(conn)


def repositorio_enlaces(conn: Conexion) -> EnlacesSql:
    return EnlacesSql(conn)


__all__ = [
    "EnlacesSql",
    "NotificacionesSql",
    "ReservasSql",
    "UsuariosSql",
    "canal_push",
    "enviar_correo",
    "repositorio_enlaces",
    "repositorio_notificaciones",
    "repositorio_reservas",
    "repositorio_usuarios",
]
