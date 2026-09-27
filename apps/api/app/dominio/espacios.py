import re
import unicodedata

_PREFIJOS_SEDE = ("sede ",)
_PREFIJOS_CALLE = ("avenida ", "av. ", "av ", "calle ")


def _sin_prefijo(texto: str, prefijos: tuple[str, ...]) -> str:
    limpio = texto.strip()
    bajo = limpio.lower()
    for prefijo in prefijos:
        if bajo == prefijo.strip():
            return ""
        if bajo.startswith(prefijo):
            return limpio[len(prefijo) :]
    return limpio


def _parte(texto: str) -> str:
    sin_tildes = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()
    palabras = re.findall(r"[A-Za-z0-9]+", sin_tildes)
    return "".join(p[0].upper() + p[1:] for p in palabras)


def nombre_compuesto(
    sede: str, calle: str, altura: int, deporte: str, tipo: str, numero: int
) -> str:
    """Nombre del espacio que pide el enunciado: sede, dirección, tipo y número.

    `nombre_compuesto("Sede Morón", "Av. Rivadavia", 19850, "Fútbol", "F5", 1)` da
    `Moron_Rivadavia_19850_Futbol_F5_1`, el formato que usa el prototipo.
    """
    if altura <= 0 or numero <= 0:
        raise ValueError("la altura y el número tienen que ser positivos")
    partes = [
        _parte(_sin_prefijo(sede, _PREFIJOS_SEDE)),
        _parte(_sin_prefijo(calle, _PREFIJOS_CALLE)),
        str(altura),
        _parte(deporte),
        tipo.strip().upper(),
        str(numero),
    ]
    if not all(partes):
        raise ValueError("sede, calle, deporte y tipo no pueden quedar vacíos")
    return "_".join(partes)
