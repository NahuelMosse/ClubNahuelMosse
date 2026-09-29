from typing import Protocol

from app.aplicacion.errores import DatosInvalidos, Prohibido
from app.dominio.sedes import DatosSede, Sede, SedeNueva, validar_sede
from app.dominio.usuarios import Perfil


class Sedes(Protocol):
    def activas(self) -> list[Sede]: ...

    def insertar(self, nueva: SedeNueva, autor: int) -> Sede:
        """Lanza `Duplicado(["nombre"])` si otra sede activa ya tiene ese nombre."""
        ...

    def actualizar(self, sede_id: int, datos: SedeNueva, autor: int, confirmar: bool) -> Sede:
        """Guarda los datos nuevos de la sede activa [sede_id]. Las reservas no se tocan.

        Sin [confirmar], lanza `ReservasAfuera` si el horario nuevo deja afuera reservas
        futuras activas que el de antes admitía. Lanza `NoEncontrada` si la sede ya no está
        activa y `Duplicado(["nombre"])` si otra sede activa ya tiene ese nombre.
        """
        ...


def dar_de_alta_sede(perfil: Perfil, datos: DatosSede, sedes: Sedes) -> Sede:
    """Registra una sede nueva, activa desde ya, a nombre del administrador que la carga."""
    if perfil.rol != "admin":
        raise Prohibido("sólo un administrador da de alta sedes")
    nueva, errores = validar_sede(datos)
    if nueva is None:
        raise DatosInvalidos(errores)
    return sedes.insertar(nueva, autor=perfil.id)


def editar_sede(
    perfil: Perfil, sede_id: int, datos: DatosSede, confirmar: bool, sedes: Sedes
) -> Sede:
    """Corrige el nombre, la dirección o el horario de una sede (CU-18). Las reservas ya
    hechas se respetan: el horario nuevo rige para las que vengan (RF 3 se valida al
    reservar)."""
    if perfil.rol != "admin":
        raise Prohibido("sólo un administrador edita sedes")
    nueva, errores = validar_sede(datos)
    if nueva is None:
        raise DatosInvalidos(errores)
    return sedes.actualizar(sede_id, nueva, autor=perfil.id, confirmar=confirmar)


def sedes_activas(sedes: Sedes) -> list[Sede]:
    """Las sedes que se ven hoy, por nombre, con la cantidad de canchas activas de cada una."""
    return sedes.activas()
