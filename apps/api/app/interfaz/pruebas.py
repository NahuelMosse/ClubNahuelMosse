"""Lo que los escenarios necesitan ver o forzar y la app no. Sólo existe con `PRUEBAS=1`."""

from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel
from sqlalchemy import Connection, text

from app.aplicacion.recuperacion import hash_de
from app.infraestructura.db import conexion

router = APIRouter(prefix="/_pruebas", include_in_schema=False)
Conexion = Annotated[Connection, Depends(conexion, scope="function")]


class Correo(BaseModel):
    asunto: str
    cuerpo: str


class Buzon(BaseModel):
    correos: list[Correo]


@router.get("/correos")
def buzon(para: str, conn: Conexion) -> Buzon:
    filas = conn.execute(
        text("SELECT asunto, cuerpo FROM correo_saliente WHERE para = :p ORDER BY id"),
        {"p": para.strip().lower()},
    ).all()
    return Buzon(correos=[Correo(asunto=f.asunto, cuerpo=f.cuerpo) for f in filas])


@router.post("/recuperacion/{codigo}/vencer", status_code=status.HTTP_204_NO_CONTENT)
def vencer(codigo: str, conn: Conexion) -> Response:
    conn.execute(
        text(
            "UPDATE enlace_recuperacion SET emitido_en = clock_timestamp() - interval '1 hour',"
            " vence_en = clock_timestamp() - interval '30 minutes' WHERE codigo_hash = :h"
        ),
        {"h": hash_de(codigo)},
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
