"""Donde la API arma lo que sus casos de uso necesitan de afuera: la conexión, los repositorios,
el servicio de notificaciones, la identidad, el correo y los enlaces. Las rutas de `interfaz/`
toman todo de acá y no conocen `infraestructura/`."""

from typing import Annotated

from fastapi import Depends
from sqlalchemy import Connection

from app.infraestructura.correo import enviar as enviar_correo
from app.infraestructura.db import conexion, motor
from app.infraestructura.enlaces import EnlacesSql
from app.infraestructura.espacios import EspaciosSql
from app.infraestructura.horarios import HorariosSql
from app.infraestructura.identidad import ProveedorFirebase
from app.infraestructura.notificaciones import NotificacionesSql
from app.infraestructura.push import canal_push
from app.infraestructura.reservas import ReservasSql
from app.infraestructura.sedes import SedesSql
from app.infraestructura.usuarios import UsuariosSql

Conexion = Annotated[Connection, Depends(conexion, scope="function")]


# Un repositorio por pedido: todos arman sobre la misma conexión, que FastAPI resuelve una vez.
def repositorio_reservas(conn: Conexion) -> ReservasSql:
    return ReservasSql(conn)


def repositorio_sedes(conn: Conexion) -> SedesSql:
    return SedesSql(conn)


def repositorio_espacios(conn: Conexion) -> EspaciosSql:
    return EspaciosSql(conn)


def repositorio_horarios(conn: Conexion) -> HorariosSql:
    return HorariosSql(conn)


def repositorio_usuarios(conn: Conexion) -> UsuariosSql:
    return UsuariosSql(conn)


def repositorio_notificaciones(conn: Conexion) -> NotificacionesSql:
    return NotificacionesSql(conn)


def repositorio_enlaces(conn: Conexion) -> EnlacesSql:
    return EnlacesSql(conn)


def identidad() -> ProveedorFirebase:
    return ProveedorFirebase()


__all__ = [
    "EnlacesSql",
    "EspaciosSql",
    "HorariosSql",
    "NotificacionesSql",
    "ProveedorFirebase",
    "ReservasSql",
    "SedesSql",
    "UsuariosSql",
    "canal_push",
    "conexion",
    "enviar_correo",
    "identidad",
    "motor",
    "repositorio_enlaces",
    "repositorio_espacios",
    "repositorio_horarios",
    "repositorio_notificaciones",
    "repositorio_reservas",
    "repositorio_sedes",
    "repositorio_usuarios",
]
