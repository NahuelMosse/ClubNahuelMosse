"""Las respuestas de error que comparten todos los endpoints."""

from fastapi import Response, status
from fastapi.responses import JSONResponse


def sin_permiso() -> Response:
    return Response(status_code=status.HTTP_403_FORBIDDEN)


def no_encontrado() -> Response:
    return Response(status_code=status.HTTP_404_NOT_FOUND)


def datos_invalidos(errores: dict[str, str]) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": errores}
    )


def conflicto(errores: dict[str, str]) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"errores": errores})
