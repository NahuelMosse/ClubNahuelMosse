import re
import unicodedata

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


def nombre_compuesto(
    sede: str, calle: str, altura: int, deporte: str, tipo: str, numero: int
) -> str:
    """Nombre del espacio que pide el enunciado: sede, dirección, tipo y número.

    `nombre_compuesto("Sede Morón", "Av. Rivadavia", 19850, "Fútbol", "F5", 1)` da
    `Moron_Rivadavia_19850_Futbol_F5_1`, el formato que usa el prototipo.
    """
    partes = [
        _parte(_PREFIJO_SEDE.sub("", _ascii(sede).strip())),
        _parte(_PREFIJO_CALLE.sub("", _ascii(calle).strip())),
        str(_entero_positivo(altura, "la altura")),
        _parte(deporte),
        "".join(_palabras(tipo)).upper(),
        str(_entero_positivo(numero, "el número")),
    ]
    if not all(partes):
        raise ValueError("sede, calle, deporte y tipo no pueden quedar vacíos")
    return "_".join(partes)
