from datetime import date
from typing import Protocol

from app.modules.usuarios.registro import ProveedorIdentidad, RepositorioUsuarios, registrar
from app.modules.usuarios.reglas import DatosRegistro, normalizar_correo
from app.shared.errores import CuentaExistente


class RepositorioAdministradores(RepositorioUsuarios, Protocol):
    def id_activo_por_correo(self, correo: str) -> int | None: ...

    def hacer_admin(self, id_usuario: int) -> None: ...


def sembrar_admin(
    datos: DatosRegistro,
    hoy: date,
    identidad: ProveedorIdentidad,
    usuarios: RepositorioAdministradores,
    promover: bool = False,
) -> int:
    """Crea una cuenta de administrador con esos datos, o asciende la que ya existe.

    El rol no se elige al iniciar sesión: sale de la cuenta, y la primera se siembra así.
    Ascender una cuenta existente conserva su contraseña, así que sólo se hace si se pide:
    el registro es público y cualquiera pudo haber creado una con ese correo.
    """
    existente = usuarios.id_activo_por_correo(normalizar_correo(datos.correo))
    if existente is not None and not promover:
        raise CuentaExistente
    id_usuario = existente if existente is not None else registrar(datos, hoy, identidad, usuarios)
    usuarios.hacer_admin(id_usuario)
    return id_usuario
