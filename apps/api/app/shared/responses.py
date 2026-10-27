"""Error responses shared by several endpoints, each route choosing its own. The ones the whole
API answers the same way are converted by `http_errors`."""

from fastapi import status
from fastapi.responses import JSONResponse


def conflict(errors: dict[str, str]) -> JSONResponse:
    return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"errores": errors})
