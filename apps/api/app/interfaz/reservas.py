from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.reservas import Cuando, mis_reservas
from app.dominio.reservas import Estado
from app.dominio.usuarios import Perfil
from app.infraestructura.db import conexion
from app.infraestructura.reservas import ReservasSql
from app.interfaz.sesion import SinSesion, usuario_actual

router = APIRouter(tags=["reservas"])


class ReservaVista(BaseModel):
    id: int
    espacio_id: int
    espacio: str
    deporte: str
    tipo: str
    sede: str
    direccion: str
    inicio: datetime
    fin: datetime
    precio_por_hora: int
    total: int
    estado: Estado
    motivo: str | None


class ListaDeReservas(BaseModel):
    reservas: list[ReservaVista]


@router.get(
    "/reservas",
    response_model=ListaDeReservas,
    responses={401: {"model": SinSesion}},
    summary="Las reservas de quien consulta",
    description=(
        "`proximas`: las activas que no terminaron, de la más cercana a la más lejana. "
        "`historial`: las completadas, canceladas y anuladas, de la más reciente a la más "
        "vieja. El total es el que se guardó al reservar."
    ),
)
def listar_reservas(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
    cuando: Annotated[Cuando, Query()] = "proximas",
) -> ListaDeReservas:
    return ListaDeReservas(
        reservas=[
            ReservaVista(
                id=r.id,
                espacio_id=r.espacio_id,
                espacio=r.espacio,
                deporte=r.deporte,
                tipo=r.tipo,
                sede=r.sede,
                direccion=r.direccion,
                inicio=r.inicio,
                fin=r.fin,
                precio_por_hora=r.precio_por_hora,
                total=r.total,
                estado=r.estado,
                motivo=r.motivo,
            )
            for r in mis_reservas(ReservasSql(conn), perfil, cuando)
        ]
    )
