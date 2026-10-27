"""Domain errors the whole API answers the same way: invalid data is a 422 with its errors,
forbidden a 403 and not found a 404, both without a body. A route that answers something else
for one of them catches it itself."""

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

from app.shared.errors import Forbidden, InvalidData, NotFound


async def _respond_422(_: Request, e: Exception) -> Response:
    assert isinstance(e, InvalidData)
    return JSONResponse({"errores": e.errors}, status_code=422)


async def _respond_403(_: Request, __: Exception) -> Response:
    return Response(status_code=403)


async def _respond_404(_: Request, __: Exception) -> Response:
    return Response(status_code=404)


def install(app: FastAPI) -> None:
    app.add_exception_handler(InvalidData, _respond_422)
    app.add_exception_handler(Forbidden, _respond_403)
    app.add_exception_handler(NotFound, _respond_404)
