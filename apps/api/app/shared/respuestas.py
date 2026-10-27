"""Las respuestas de error que comparten varios endpoints y que cada ruta elige. Las que toda la
API responde igual las convierte `errores_http`."""

from fastapi import status
from fastapi.responses import JSONResponse


def conflicto(errores: dict[str, str]) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"errores": errores})
