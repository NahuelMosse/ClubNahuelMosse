"""Lo que entra por HTTP: los tipos de texto y número acotados de los modelos de pedido y la
respuesta a un dato de forma inválida. Un solo lugar para los largos y para la regla de
caracteres."""

import unicodedata
from typing import Annotated

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import AfterValidator, Field, StringConstraints
from pydantic_core import PydanticCustomError

CARACTERES_NO_PERMITIDOS = "caracteres_no_permitidos"
_SALTOS = "\n\r\t"


def _sin_control(valor: str, permitidos: str = "") -> str:
    """Rechaza NUL y demás caracteres de control. `permitidos` deja pasar saltos de línea y
    tabulaciones en los párrafos."""
    for caracter in valor:
        if caracter not in permitidos and unicodedata.category(caracter) == "Cc":
            raise PydanticCustomError(CARACTERES_NO_PERMITIDOS, "Tiene caracteres no permitidos")
    return valor


def _linea(valor: str) -> str:
    return _sin_control(valor)


def _parrafo(valor: str) -> str:
    return _sin_control(valor, _SALTOS)


# Una línea de texto sin caracteres de control, con su largo máximo. Los largos de dominio
# (nombre, dirección, motivo) los sigue validando el dominio con su mensaje: acá sólo va una
# cota que corta lo desmesurado.
Texto40 = Annotated[str, StringConstraints(max_length=40), AfterValidator(_linea)]
Texto120 = Annotated[str, StringConstraints(max_length=120), AfterValidator(_linea)]
Busqueda = Annotated[str, StringConstraints(max_length=100), AfterValidator(_linea)]
Correo = Annotated[str, StringConstraints(max_length=254), AfterValidator(_linea)]
Clave = Annotated[str, StringConstraints(max_length=128), AfterValidator(_linea)]
Codigo = Clave
TokenDeDispositivo = Annotated[str, StringConstraints(max_length=4096), AfterValidator(_linea)]
Parrafo = Annotated[str, StringConstraints(max_length=1000), AfterValidator(_parrafo)]

# Un número de fila de la base: cabe en un bigint.
Identificador = Annotated[int, Field(ge=1, le=2**63 - 1)]

_MENSAJES = {
    CARACTERES_NO_PERMITIDOS: "Tiene caracteres no permitidos",
    # Un sustituto suelto (`\ud800`): pydantic ya lo rechaza, no se puede guardar en UTF-8.
    "string_unicode": "Tiene caracteres no permitidos",
    "string_too_long": "Es demasiado largo",
    "too_long": "Tiene demasiados elementos",
    "missing": "Falta este dato",
    "json_invalid": "El cuerpo no es JSON válido",
    "greater_than_equal": "Está fuera del rango permitido",
    "less_than_equal": "Está fuera del rango permitido",
}
_GENERICO = "El dato no es válido"
_ORIGENES = {"body", "query", "path", "header", "cookie"}


def _campo(ubicacion: tuple[int | str, ...]) -> str:
    """El nombre del campo que falló: lo que sigue a `body`, `query` o `path`."""
    resto = ubicacion[1:] if ubicacion and ubicacion[0] in _ORIGENES else ubicacion
    return resto[0] if resto and isinstance(resto[0], str) else "cuerpo"


def errores_de_forma(e: RequestValidationError) -> dict[str, str]:
    """Un mensaje por campo, sin repetir lo que llegó."""
    errores: dict[str, str] = {}
    for error in e.errors():
        errores.setdefault(_campo(error["loc"]), _MENSAJES.get(error["type"], _GENERICO))
    return errores


async def _responder(_: Request, e: Exception) -> JSONResponse:
    assert isinstance(e, RequestValidationError)
    if any(error["type"] == "json_invalid" for error in e.errors()):
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"errores": {"cuerpo": _MENSAJES["json_invalid"]}},
        )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
        content={"errores": errores_de_forma(e)},
    )


def instalar(app: FastAPI) -> None:
    """Un dato de forma inválida responde 422 con `{"errores": {campo: mensaje}}`; un cuerpo que
    no es JSON, 400."""
    app.add_exception_handler(RequestValidationError, _responder)
