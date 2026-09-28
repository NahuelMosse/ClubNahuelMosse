"""Lo que los escenarios necesitan ver o forzar y la app no. Sólo existe con `PRUEBAS=1`."""

from datetime import date
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


class Ocupacion(BaseModel):
    espacio: str
    fecha: date
    hora: int
    horas: int = 1


@router.post("/reservas", status_code=status.HTTP_204_NO_CONTENT)
def ocupar(ocupacion: Ocupacion, conn: Conexion) -> Response:
    """Una reserva de otra persona: la primera cuenta de la base."""
    conn.execute(
        text(
            "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
            " SELECT (SELECT min(id) FROM usuario), e.id, x.inicio,"
            "        x.inicio + make_interval(hours => :horas),"
            "        e.precio_por_hora, e.precio_por_hora * :horas"
            " FROM espacio e,"
            "      LATERAL (SELECT (CAST(:fecha AS date) + make_interval(hours => :hora))"
            "               AT TIME ZONE 'America/Argentina/Buenos_Aires' AS inicio) x"
            " WHERE e.nombre = :espacio"
        ),
        ocupacion.model_dump(),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


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
