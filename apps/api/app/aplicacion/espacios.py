from collections.abc import Callable
from typing import Protocol

from app.aplicacion.errores import DatosInvalidos, NoDisponible, Prohibido
from app.dominio.espacios import (
    CATALOGO,
    CambioDeEspacio,
    DatosEspacio,
    Deporte,
    Espacio,
    EspacioNuevo,
    NombreSugerido,
    SedeDelEspacio,
    nombre_compuesto,
    tipo_del_catalogo,
    validar_cambio,
    validar_espacio,
)
from app.dominio.usuarios import Perfil


class Espacios(Protocol):
    def activos(
        self,
        sede_id: int | None = None,
        deporte: str | None = None,
        tipo: str | None = None,
    ) -> list[Espacio]: ...

    def siguiente(
        self,
        sede_id: int,
        deporte: str,
        tipo: str,
        nombre: Callable[[SedeDelEspacio, int], str],
    ) -> NombreSugerido | None:
        """El número y el nombre que siguen para ese tipo en esa sede, o `None` si la sede
        no está activa. Los números de bajas no se reutilizan."""
        ...

    def insertar(
        self,
        nuevo: EspacioNuevo,
        numero: int | None,
        nombre: Callable[[SedeDelEspacio, int], str],
        autor: int,
    ) -> Espacio:
        """Guarda el espacio con el número siguiente.

        Si [numero] ya no es el siguiente, lanza `NumeroOcupado` con el que sigue, salvo que
        ese número lo haya tomado hace un momento el mismo [autor] con los mismos datos: es
        su propio pedido repetido después de un corte, y lo devuelve. Lanza `NoDisponible`
        si la sede ya no está activa.
        """
        ...

    def actualizar(self, espacio_id: int, cambio: CambioDeEspacio, autor: int) -> Espacio:
        """Guarda el cambio del espacio activo [espacio_id]. Las reservas ya hechas conservan
        el precio con que se hicieron.

        Lanza `NoEncontrada` si el espacio o su sede ya no están activos.
        """
        ...

    def dar_de_baja(self, espacio_id: int, autor: int) -> None:
        """Da de baja el espacio activo [espacio_id] a nombre de [autor]. Las reservas pasadas
        lo siguen nombrando.

        Lanza `NoEncontrada` si ya no está activo y `ConReservasFuturas` si tiene una reserva
        activa que todavía no terminó.
        """
        ...


def _solo_admin(perfil: Perfil) -> None:
    if perfil.rol != "admin":
        raise Prohibido("sólo un administrador gestiona espacios")


def catalogo() -> tuple[Deporte, ...]:
    return CATALOGO


def _nombre(deporte: str, tipo: str) -> Callable[[SedeDelEspacio, int], str]:
    return lambda sede, numero: nombre_compuesto(
        sede.nombre, sede.calle, sede.altura, deporte, tipo, numero
    )


def nombre_sugerido(
    perfil: Perfil, sede_id: int, deporte: str, tipo: str, espacios: Espacios
) -> NombreSugerido:
    """El nombre que tendría el próximo espacio de ese tipo en esa sede."""
    _solo_admin(perfil)
    if tipo_del_catalogo(deporte, tipo) is None:
        raise DatosInvalidos({"tipo": "Elegí un tipo de la lista"})
    sugerido = espacios.siguiente(sede_id, deporte, tipo, _nombre(deporte, tipo))
    if sugerido is None:
        raise NoDisponible("la sede no está activa")
    return sugerido


def dar_de_alta_espacio(
    perfil: Perfil, datos: DatosEspacio, numero: int | None, espacios: Espacios
) -> Espacio:
    """Registra un espacio activo con el nombre compuesto del enunciado (RF 5).

    [numero] es el que vio el administrador: si otro alta lo tomó mientras tanto, lanza
    `NumeroOcupado` con el siguiente, para que lo vea antes de guardar.
    """
    _solo_admin(perfil)
    nuevo, errores = validar_espacio(datos)
    if nuevo is None:
        raise DatosInvalidos(errores)
    return espacios.insertar(nuevo, numero, _nombre(nuevo.deporte, nuevo.tipo), perfil.id)


def espacios_activos(
    espacios: Espacios,
    sede_id: int | None = None,
    deporte: str | None = None,
    tipo: str | None = None,
) -> list[Espacio]:
    """Los espacios que se pueden reservar, por sede, deporte, tipo y número; sólo los de
    [sede_id], [deporte] y [tipo] si se piden."""
    return espacios.activos(sede_id, deporte, tipo)


def editar_espacio(
    perfil: Perfil,
    espacio_id: int,
    techada: bool | None,
    iluminada: bool | None,
    precio_por_hora: int | None,
    dados: frozenset[str],
    espacios: Espacios,
) -> Espacio:
    """Corrige la condición, la iluminación o el precio de un espacio (CU-22); sólo cambia lo
    que está en [dados]. El precio nuevo rige para las reservas que vengan."""
    _solo_admin(perfil)
    cambio, errores = validar_cambio(techada, iluminada, precio_por_hora, dados=dados)
    if cambio is None:
        raise DatosInvalidos(errores)
    return espacios.actualizar(espacio_id, cambio, perfil.id)


def dar_de_baja_espacio(perfil: Perfil, espacio_id: int, espacios: Espacios) -> None:
    """Retira un espacio (CU-23): deja de verse y de poder reservarse. No se permite con
    reservas pendientes (decisión 5): la cancelación forzosa es de CU-15."""
    _solo_admin(perfil)
    espacios.dar_de_baja(espacio_id, perfil.id)
