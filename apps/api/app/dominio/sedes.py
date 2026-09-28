import re
from dataclasses import dataclass
from datetime import time

LARGO_NOMBRE = 60
LARGO_DIRECCION = 80
MEDIANOCHE = time(0, 0)
DIAS_DE_LA_SEMANA = frozenset(range(1, 8))

_CALLE_Y_ALTURA = re.compile(r"^(?P<calle>.*\S)\s+(?P<altura>\d{1,6})$", re.ASCII)


@dataclass(frozen=True)
class DatosSede:
    """Lo que llega del formulario, sin validar."""

    nombre: str
    direccion: str
    apertura: time | None
    cierre: time | None
    dias: tuple[int, ...]


@dataclass(frozen=True)
class SedeNueva:
    nombre: str
    calle: str
    altura: int
    apertura: time
    cierre: time
    dias: tuple[int, ...]


@dataclass(frozen=True)
class Sede:
    id: int
    nombre: str
    calle: str
    altura: int
    apertura: time
    cierre: time
    dias: tuple[int, ...]
    canchas: int

    @property
    def direccion(self) -> str:
        return f"{self.calle} {self.altura}"


def _en_punto(hora: time) -> bool:
    return hora.minute == 0 and hora.second == 0 and hora.microsecond == 0


def _errores_de_horario(apertura: time | None, cierre: time | None) -> dict[str, str]:
    errores: dict[str, str] = {}
    if apertura is None:
        errores["apertura"] = "El horario de apertura es obligatorio"
    elif not _en_punto(apertura):
        errores["apertura"] = "Elegí una hora en punto"
    if cierre is None:
        errores["cierre"] = "El horario de cierre es obligatorio"
    elif not _en_punto(cierre):
        errores["cierre"] = "Elegí una hora en punto"
    elif apertura is not None and cierre != MEDIANOCHE and cierre <= apertura:
        # Cerrar a las 00:00 es cerrar a la medianoche del mismo día.
        errores["cierre"] = "El cierre tiene que ser después de la apertura"
    return errores


def validar_sede(datos: DatosSede) -> tuple[SedeNueva | None, dict[str, str]]:
    """La sede lista para guardar, o los errores de cada campo."""
    errores: dict[str, str] = {}
    nombre = " ".join(datos.nombre.split())
    if not nombre:
        errores["nombre"] = "El nombre es obligatorio"
    elif len(nombre) > LARGO_NOMBRE:
        errores["nombre"] = f"Usá hasta {LARGO_NOMBRE} caracteres"

    direccion = " ".join(datos.direccion.split())
    partes = _CALLE_Y_ALTURA.match(direccion)
    if not direccion:
        errores["direccion"] = "La dirección es obligatoria"
    elif len(direccion) > LARGO_DIRECCION:
        errores["direccion"] = f"Usá hasta {LARGO_DIRECCION} caracteres"
    elif partes is None or int(partes["altura"]) == 0:
        errores["direccion"] = "Escribí la calle y la altura"

    errores |= _errores_de_horario(datos.apertura, datos.cierre)

    dias = tuple(sorted(set(datos.dias)))
    if not dias or not set(dias) <= DIAS_DE_LA_SEMANA:
        errores["dias"] = "Elegí los días que abre"

    if errores or partes is None or datos.apertura is None or datos.cierre is None:
        return None, errores
    return (
        SedeNueva(
            nombre=nombre,
            calle=partes["calle"],
            altura=int(partes["altura"]),
            apertura=datos.apertura,
            cierre=datos.cierre,
            dias=dias,
        ),
        {},
    )
