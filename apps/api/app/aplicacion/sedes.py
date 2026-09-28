from typing import Protocol

from app.aplicacion.errores import DatosInvalidos, Prohibido
from app.dominio.sedes import DatosSede, Sede, SedeNueva, validar_sede
from app.dominio.usuarios import Perfil


class Sedes(Protocol):
    def activas(self) -> list[Sede]: ...

    def insertar(self, nueva: SedeNueva, autor: int) -> Sede:
        """Lanza `Duplicado(["nombre"])` si otra sede activa ya tiene ese nombre."""
        ...


def dar_de_alta_sede(perfil: Perfil, datos: DatosSede, sedes: Sedes) -> Sede:
    """Registra una sede nueva, activa desde ya, a nombre del administrador que la carga."""
    if perfil.rol != "admin":
        raise Prohibido("sólo un administrador da de alta sedes")
    nueva, errores = validar_sede(datos)
    if nueva is None:
        raise DatosInvalidos(errores)
    return sedes.insertar(nueva, autor=perfil.id)


def sedes_activas(sedes: Sedes) -> list[Sede]:
    """Las sedes que se ven hoy, por nombre, con la cantidad de canchas activas de cada una."""
    return sedes.activas()
