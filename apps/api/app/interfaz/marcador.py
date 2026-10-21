"""El marcador de página de los historiales: un texto opaco que la app devuelve tal cual."""

import base64
import binascii
from collections.abc import Sequence
from datetime import datetime
from typing import Protocol

from app.aplicacion.errores import DatosInvalidos
from app.dominio.reservas import Marcador

INVALIDO = "El marcador de página no es válido"
# Un marcador real mide unos 60 caracteres: más que esto no es uno.
_LARGO_MAXIMO = 100
_ID_MAXIMO = 2**63 - 1


class _ConClave(Protocol):
    @property
    def inicio(self) -> datetime: ...

    @property
    def id(self) -> int: ...


def codificar(marcador: Marcador) -> str:
    crudo = f"{marcador.inicio.isoformat()}|{marcador.id}".encode()
    return base64.urlsafe_b64encode(crudo).decode().rstrip("=")


def leer(valor: str) -> Marcador:
    """Lanza `DatosInvalidos` si [valor] no es un marcador que `codificar` haya armado."""
    marcador = _decodificar(valor) if 0 < len(valor) <= _LARGO_MAXIMO else None
    if marcador is None:
        raise DatosInvalidos({"despues": INVALIDO})
    return marcador


def _decodificar(valor: str) -> Marcador | None:
    try:
        crudo = base64.urlsafe_b64decode(valor + "=" * (-len(valor) % 4)).decode()
        inicio, id_, *resto = crudo.split("|")
        marcador = Marcador(datetime.fromisoformat(inicio), int(id_))
    except (binascii.Error, ValueError):
        return None
    # Sólo vale el texto exacto que arma `codificar`: nada de relleno, espacios o ceros de más.
    valido = (
        not resto
        and marcador.inicio.tzinfo is not None
        and 0 < marcador.id <= _ID_MAXIMO
        and codificar(marcador) == valor
    )
    return marcador if valido else None


def siguiente(reservas: Sequence[_ConClave], hay_mas: bool) -> str | None:
    """El marcador que lleva a la tanda que sigue a [reservas], o `None` si no hay más."""
    if not hay_mas or not reservas:
        return None
    return codificar(Marcador(reservas[-1].inicio, reservas[-1].id))
