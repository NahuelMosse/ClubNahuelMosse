"""Donde la API arma lo que sus casos de uso necesitan de afuera: la conexión, los repositorios,
el servicio de notificaciones, la identidad, el correo y los enlaces. Las rutas de `interfaz/`
toman todo de acá y no conocen `infraestructura/`."""

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
    "motor",
]
