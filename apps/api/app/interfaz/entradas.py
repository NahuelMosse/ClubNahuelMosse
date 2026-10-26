"""Lo que entra por HTTP: el identificador numérico, la hora `HH:MM` y la respuesta a un dato
de forma inválida."""

import re
from datetime import time
from typing import Annotated

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import Field

# Un número de fila de la base: cabe en un bigint.
ID_MAXIMO = 2**63 - 1
Identificador = Annotated[int, Field(ge=1, le=ID_MAXIMO)]

_HORA = re.compile(r"\d{2}:\d{2}", re.ASCII)


def leer_hora(valor: str) -> time | None:
    """`HH:MM` y nada más: `fromisoformat` también acepta zonas y formatos que no van."""
    if not _HORA.fullmatch(valor):
        return None
    try:
        return time.fromisoformat(valor)
    except ValueError:
        return None


_MENSAJES = {
    # Un sustituto suelto (`\ud800`): pydantic ya lo rechaza, no se puede guardar en UTF-8.
    "string_unicode": "Tiene caracteres no permitidos",
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
