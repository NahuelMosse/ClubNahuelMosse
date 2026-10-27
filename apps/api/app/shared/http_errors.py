"""Los errores del dominio que toda la API responde igual: datos inválidos es un 422 con sus
errores, prohibido un 403 y no encontrada un 404, los dos sin cuerpo. Una ruta que responde
otra cosa para alguno de ellos lo atrapa ella."""

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

from app.shared.errores import DatosInvalidos, NoEncontrada, Prohibido


async def _responder_422(_: Request, e: Exception) -> Response:
    assert isinstance(e, DatosInvalidos)
    return JSONResponse({"errores": e.errores}, status_code=422)


async def _responder_403(_: Request, __: Exception) -> Response:
    return Response(status_code=403)


async def _responder_404(_: Request, __: Exception) -> Response:
    return Response(status_code=404)


def instalar(app: FastAPI) -> None:
    app.add_exception_handler(DatosInvalidos, _responder_422)
    app.add_exception_handler(Prohibido, _responder_403)
    app.add_exception_handler(NoEncontrada, _responder_404)
