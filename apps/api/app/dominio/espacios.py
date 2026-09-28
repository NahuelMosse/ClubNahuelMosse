import re
import unicodedata
from dataclasses import dataclass

_PREFIJO_SEDE = re.compile(r"^sede\b\s*", re.IGNORECASE)
_PREFIJO_CALLE = re.compile(r"^(avenida|avda\.?|av\.?|calle)(\s+|(?<=\.))", re.IGNORECASE)
_TRANSLITERACION = str.maketrans(
    {"ß": "ss", "ø": "o", "Ø": "O", "ł": "l", "Ł": "L", "æ": "ae", "Æ": "AE"}
)


def _ascii(texto: str) -> str:
    texto = unicodedata.normalize("NFKC", texto).translate(_TRANSLITERACION)
    return unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()


def _palabras(texto: str) -> list[str]:
    return re.findall(r"[A-Za-z0-9]+", _ascii(texto))


def _parte(texto: str) -> str:
    return "".join(p[0].upper() + p[1:] for p in _palabras(texto))


def _entero_positivo(valor: int, nombre: str) -> int:
    if isinstance(valor, bool) or not isinstance(valor, int) or valor <= 0:
        raise ValueError(f"{nombre} tiene que ser un entero positivo")
    return valor


def parte_de_sede(sede: str) -> str:
    """Lo que la sede aporta al nombre de sus espacios: «Sede Ramos Mejía» → «RamosMejia»."""
    return _parte(_PREFIJO_SEDE.sub("", _ascii(sede).strip()))


def parte_de_calle(calle: str) -> str:
    """Lo que la calle aporta al nombre de sus espacios: «Av. Rivadavia» → «Rivadavia»."""
    return _parte(_PREFIJO_CALLE.sub("", _ascii(calle).strip()))


def nombre_compuesto(
    sede: str, calle: str, altura: int, deporte: str, tipo: str, numero: int
) -> str:
    """Nombre del espacio que pide el enunciado: sede, dirección, tipo y número.

    `nombre_compuesto("Sede Morón", "Av. Rivadavia", 19850, "Fútbol", "F5", 1)` da
    `Moron_Rivadavia_19850_Futbol_F5_1`, el formato que usa el prototipo.
    """
    partes = [
        parte_de_sede(sede),
        parte_de_calle(calle),
        str(_entero_positivo(altura, "la altura")),
        _parte(deporte),
        "".join(_palabras(tipo)).upper(),
        str(_entero_positivo(numero, "el número")),
    ]
    if not all(partes):
        raise ValueError("sede, calle, deporte y tipo no pueden quedar vacíos")
    return "_".join(partes)


@dataclass(frozen=True)
class NombreSugerido:
    nombre: str
    numero: int


@dataclass(frozen=True)
class SedeDelEspacio:
    """Lo de la sede que entra en el nombre compuesto de sus espacios."""

    nombre: str
    calle: str
    altura: int


@dataclass(frozen=True)
class Tipo:
    clave: str
    nombre: str


@dataclass(frozen=True)
class Deporte:
    clave: str
    nombre: str
    tipos: tuple[Tipo, ...]


CATALOGO: tuple[Deporte, ...] = (
    Deporte(
        "Futbol",
        "Fútbol",
        (
            Tipo("F5", "Fútbol 5"),
            Tipo("F7", "Fútbol 7"),
            Tipo("F8", "Fútbol 8"),
            Tipo("F11", "Fútbol 11"),
        ),
    ),
    Deporte("Tenis", "Tenis", (Tipo("PDL", "Polvo de ladrillo"), Tipo("CEM", "Cemento"))),
    Deporte("Padel", "Pádel", (Tipo("PAD", "Pádel"),)),
    Deporte("Voley", "Vóley", (Tipo("IND", "Indoor"), Tipo("PLA", "Vóley playa"))),
    Deporte("Hockey", "Hockey", (Tipo("H7", "Hockey 7"),)),
    Deporte("Golf", "Golf", (Tipo("DR", "Driving range"), Tipo("9H", "9 hoyos"))),
)

PRECIO_MAXIMO = 9_999_999

OBLIGATORIO = "Este campo es obligatorio"


def tipo_del_catalogo(deporte: str, tipo: str) -> Tipo | None:
    for d in CATALOGO:
        if d.clave == deporte:
            return next((t for t in d.tipos if t.clave == tipo), None)
    return None


@dataclass(frozen=True)
class DatosEspacio:
    """Lo que llega del formulario, sin validar."""

    sede_id: int | None
    deporte: str
    tipo: str
    techada: bool | None
    iluminada: bool | None
    precio_por_hora: int | None


@dataclass(frozen=True)
class EspacioNuevo:
    sede_id: int
    deporte: str
    tipo: str
    techada: bool
    iluminada: bool
    precio_por_hora: int


@dataclass(frozen=True)
class Espacio:
    id: int
    nombre: str
    sede_id: int
    sede: str
    deporte: str
    tipo: str
    numero: int
    techada: bool
    iluminada: bool
    precio_por_hora: int


def validar_espacio(datos: DatosEspacio) -> tuple[EspacioNuevo | None, dict[str, str]]:
    """El espacio listo para guardar, o los errores de cada campo."""
    errores: dict[str, str] = {}
    if datos.sede_id is None:
        errores["sede_id"] = OBLIGATORIO
    deportes = {d.clave for d in CATALOGO}
    if not datos.deporte:
        errores["deporte"] = OBLIGATORIO
    elif datos.deporte not in deportes:
        errores["deporte"] = "Elegí un deporte de la lista"
    if not datos.tipo:
        errores["tipo"] = OBLIGATORIO
    elif datos.deporte in deportes and tipo_del_catalogo(datos.deporte, datos.tipo) is None:
        errores["tipo"] = "Elegí un tipo de la lista"
    if datos.techada is None:
        errores["techada"] = OBLIGATORIO
    if datos.iluminada is None:
        errores["iluminada"] = OBLIGATORIO
    precio = datos.precio_por_hora
    if precio is None:
        errores["precio_por_hora"] = OBLIGATORIO
    elif not 0 < precio <= PRECIO_MAXIMO:
        errores["precio_por_hora"] = "Ingresá un precio entre $ 1 y $ 9.999.999"
    if (
        errores
        or datos.sede_id is None
        or datos.techada is None
        or datos.iluminada is None
        or precio is None
    ):
        return None, errores
    return (
        EspacioNuevo(
            sede_id=datos.sede_id,
            deporte=datos.deporte,
            tipo=datos.tipo,
            techada=datos.techada,
            iluminada=datos.iluminada,
            precio_por_hora=precio,
        ),
        {},
    )
