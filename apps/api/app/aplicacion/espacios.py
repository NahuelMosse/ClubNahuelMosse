from collections.abc import Callable
from typing import Protocol

from app.aplicacion.errores import DatosInvalidos, NoDisponible, Prohibido
from app.dominio.espacios import (
    CATALOGO,
    DatosEspacio,
    Deporte,
    Espacio,
    EspacioNuevo,
    NombreSugerido,
    SedeDelEspacio,
    nombre_compuesto,
    tipo_del_catalogo,
    validar_espacio,
)
from app.dominio.usuarios import Perfil


class Espacios(Protocol):
    def activos(self) -> list[Espacio]: ...

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


def espacios_activos(espacios: Espacios) -> list[Espacio]:
    """Los espacios que se pueden reservar, por sede y por nombre."""
    return espacios.activos()
