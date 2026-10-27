# kit-shape: el contrato del repositorio de sedes y los casos de uso que lo usan se leen juntos
from typing import Protocol
from uuid import UUID

from app.modules.sedes.reglas import DatosSede, Sede, SedeNueva, validar_sede
from app.modules.sesion import Perfil
from app.shared.errors import Forbidden, InvalidData


class Sedes(Protocol):
    def activas(self) -> list[Sede]: ...

    def insertar(self, nueva: SedeNueva, autor: UUID) -> Sede:
        """Lanza `Duplicate(["nombre"])` si otra sede activa ya tiene ese nombre."""
        ...

    def actualizar(self, sede_id: UUID, datos: SedeNueva, autor: UUID, *, confirmar: bool) -> Sede:
        """Guarda los datos nuevos de la sede activa [sede_id]. Las reservas no se tocan.

        Sin [confirmar], lanza `BookingsOutsideHours` si el horario nuevo deja afuera reservas
        futuras activas que el de antes admitía. Lanza `NotFound` si la sede ya no está
        activa y `Duplicate(["nombre"])` si otra sede activa ya tiene ese nombre.
        """
        ...

    def dar_de_baja(self, sede_id: UUID, autor: UUID) -> None:
        """Da de baja la sede activa [sede_id] y sus espacios, a nombre de [autor]. Las
        reservas pasadas los siguen nombrando.

        Lanza `NotFound` si la sede ya no está activa y `HasFutureBookings` si alguno de
        sus espacios tiene una reserva activa que todavía no terminó.
        """
        ...


def dar_de_alta_sede(perfil: Perfil, datos: DatosSede, sedes: Sedes) -> Sede:
    """Registra una sede nueva, activa desde ya, a nombre del administrador que la carga."""
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador da de alta sedes")
    nueva, errores = validar_sede(datos)
    if nueva is None:
        raise InvalidData(errores)
    return sedes.insertar(nueva, autor=perfil.id)


def editar_sede(  # noqa: PLR0913 -- firma pública fijada por sus llamadores
    perfil: Perfil, sede_id: UUID, datos: DatosSede, *, confirmar: bool, sedes: Sedes
) -> Sede:
    """Corrige el nombre, la dirección o el horario de una sede (CU-18). Las reservas ya
    hechas se respetan: el horario nuevo rige para las que vengan (RF 3 se valida al
    reservar)."""
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador edita sedes")
    nueva, errores = validar_sede(datos)
    if nueva is None:
        raise InvalidData(errores)
    return sedes.actualizar(sede_id, nueva, autor=perfil.id, confirmar=confirmar)


def sedes_activas(sedes: Sedes) -> list[Sede]:
    """Las sedes que se ven hoy, por nombre, con la cantidad de canchas activas de cada una."""
    return sedes.activas()


def dar_de_baja_sede(perfil: Perfil, sede_id: UUID, sedes: Sedes) -> None:
    """Retira una sede (CU-19): deja de verse y sus espacios dejan de poder reservarse. No se
    permite con reservas pendientes (decisión 5): la cancelación forzosa es de CU-15."""
    if perfil.rol != "admin":
        raise Forbidden("sólo un administrador da de baja sedes")
    sedes.dar_de_baja(sede_id, autor=perfil.id)
