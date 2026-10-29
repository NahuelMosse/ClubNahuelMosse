"""What comes in over HTTP: the UUID identifier, the `HH:MM` time and the response to a
malformed value."""

import re
from datetime import time
from typing import Annotated
from uuid import UUID

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import Field

Identifier = Annotated[UUID, Field()]

_TIME = re.compile(r"\d{2}:\d{2}", re.ASCII)


def parse_time(value: str) -> time | None:
    """`HH:MM` and nothing else: `fromisoformat` also accepts zones and formats that do not fit."""
    if not _TIME.fullmatch(value):
        return None
    try:
        return time.fromisoformat(value)
    except ValueError:
        return None


_MESSAGES = {
    # A lone surrogate (`\ud800`): pydantic already rejects it, it cannot be saved as UTF-8.
    "string_unicode": "Tiene caracteres no permitidos",
    "too_long": "Tiene demasiados elementos",
    "missing": "Falta este dato",
    "json_invalid": "El cuerpo no es JSON válido",
    "greater_than_equal": "Está fuera del rango permitido",
    "less_than_equal": "Está fuera del rango permitido",
}
_GENERIC = "El dato no es válido"
_SOURCES = {"body", "query", "path", "header", "cookie"}


def _field(location: tuple[int | str, ...]) -> str:
    """The name of the field that failed: what follows `body`, `query` or `path`."""
    rest = location[1:] if location and location[0] in _SOURCES else location
    return rest[0] if rest and isinstance(rest[0], str) else "body"


def shape_errors(e: RequestValidationError) -> dict[str, str]:
    """One message per field, without repeating what arrived."""
    errors: dict[str, str] = {}
    for error in e.errors():
        errors.setdefault(_field(error["loc"]), _MESSAGES.get(error["type"], _GENERIC))
    return errors


async def _respond(_: Request, e: Exception) -> JSONResponse:
    assert isinstance(e, RequestValidationError)
    if any(error["type"] == "json_invalid" for error in e.errors()):
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"errors": {"body": _MESSAGES["json_invalid"]}},
        )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
        content={"errors": shape_errors(e)},
    )


def install(app: FastAPI) -> None:
    """A malformed value answers 422 with `{"errors": {field: message}}`; a body that is
    not JSON, 400."""
    app.add_exception_handler(RequestValidationError, _respond)
