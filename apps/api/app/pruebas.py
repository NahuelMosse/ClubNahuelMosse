# kit-shape: los modelos de los pedidos de prueba y las rutas que los usan se leen juntos
"""Lo que los escenarios necesitan ver o forzar y la app no. Sólo existe con `PRUEBAS=1`."""

from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel
from sqlalchemy import text

from app.modules.notificaciones import (
    NotificacionesSql,
    canal_push,
    enviar_recordatorios,
    repositorio_notificaciones,
)
from app.modules.recuperacion import hash_de
from app.shared.db import Conexion
from app.shared.errores import NoEncontrada
from app.shared.zona import NOMBRE_ZONA_CLUB

router = APIRouter(prefix="/_pruebas", include_in_schema=False)


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
    # De quién es la reserva; sin correo, de la primera cuenta de la base.
    correo: str | None = None
    estado: str = "activa"
    motivo: str | None = None


@router.post("/reservas", status_code=status.HTTP_204_NO_CONTENT)
def ocupar(ocupacion: Ocupacion, conn: Conexion) -> Response:
    """Una reserva cargada por fuera de la app, de [correo] o de otra persona."""
    insertadas = conn.execute(
        text(
            "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total,"
            " estado, motivo, cancelada_en)"
            " SELECT u.id, e.id, x.inicio,"
            "        x.inicio + make_interval(hours => :horas),"
            "        e.precio_por_hora, e.precio_por_hora * :horas, :estado, :motivo,"
            "        CASE WHEN CAST(:estado AS text) <> 'activa' THEN now() END"
            " FROM espacio e,"
            "      LATERAL (SELECT (CAST(:fecha AS date) + make_interval(hours => :hora))"
            f"               AT TIME ZONE '{NOMBRE_ZONA_CLUB}' AS inicio) x,"
            "      (SELECT id FROM usuario WHERE CAST(:correo AS text) IS NULL"
            "         AND id = (SELECT id FROM usuario ORDER BY id LIMIT 1)"
            "       UNION ALL"
            "       SELECT id FROM usuario WHERE activo"
            "         AND lower(correo) = lower(CAST(:correo AS text))) u"
            " WHERE e.nombre = :espacio"
        ),
        ocupacion.model_dump(),
    ).rowcount
    conn.commit()
    if insertadas != 1:
        raise NoEncontrada()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/reservas/vaciar", status_code=status.HTTP_204_NO_CONTENT)
def vaciar_reservas(conn: Conexion) -> Response:
    """El sistema queda sin ninguna reserva, ni los avisos que las mencionan: la base de la
    corrida es una sola y los escenarios del historial global parten de cero."""
    conn.execute(text("TRUNCATE notificacion_reserva, notificacion, reserva"))
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class Espacio(BaseModel):
    espacio: str


@router.post("/reservas/empezar", status_code=status.HTTP_204_NO_CONTENT)
def empezar(pedido: Espacio, conn: Conexion) -> Response:
    """La próxima reserva activa de [espacio] pasa a empezar en la hora en curso del club,
    como si el tiempo hubiera corrido mientras la app estaba abierta."""
    conn.execute(
        text(
            "UPDATE reserva r SET fin = x.ahora + (r.fin - r.inicio), inicio = x.ahora"
            f" FROM (SELECT date_trunc('hour', now(), '{NOMBRE_ZONA_CLUB}')"
            "                  AS ahora) x"
            " WHERE r.id = (SELECT r2.id FROM reserva r2 JOIN espacio e ON e.id = r2.espacio_id"
            "               WHERE e.nombre = :espacio AND r2.estado = 'activa'"
            "               ORDER BY r2.inicio LIMIT 1)"
        ),
        pedido.model_dump(),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/reservas/anular", status_code=status.HTTP_204_NO_CONTENT)
def anular(pedido: Espacio, conn: Conexion) -> Response:
    """El club anula las reservas activas de [espacio], como lo haría un administrador."""
    conn.execute(
        text(
            "UPDATE reserva r SET estado = 'anulada', motivo = 'mantenimiento de la cancha',"
            " cancelada_en = now(), cancelada_por = (SELECT id FROM usuario ORDER BY id LIMIT 1)"
            " FROM espacio e WHERE e.id = r.espacio_id AND e.nombre = :espacio"
            " AND r.estado = 'activa'"
        ),
        pedido.model_dump(),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class NombreDeSede(BaseModel):
    nombre: str


@router.post("/sedes/baja", status_code=status.HTTP_204_NO_CONTENT)
def dar_de_baja_sede(pedido: NombreDeSede, conn: Conexion) -> Response:
    """La sede [nombre] deja de estar activa, como si la diera de baja otro administrador."""
    conn.execute(
        text(
            "UPDATE sede SET activa = false, dado_de_baja_en = now(),"
            " dado_de_baja_por = (SELECT id FROM usuario ORDER BY id LIMIT 1)"
            " WHERE nombre = :nombre AND activa"
        ),
        pedido.model_dump(),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/espacios/baja", status_code=status.HTTP_204_NO_CONTENT)
def dar_de_baja_espacio(pedido: Espacio, conn: Conexion) -> Response:
    """El espacio [espacio] deja de estar activo, como si lo diera de baja otro administrador."""
    conn.execute(
        text(
            "UPDATE espacio SET activo = false, dado_de_baja_en = now(),"
            " dado_de_baja_por = (SELECT id FROM usuario ORDER BY id LIMIT 1)"
            " WHERE nombre = :espacio AND activo"
        ),
        pedido.model_dump(),
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/recuperacion/{codigo}/vencer", status_code=status.HTTP_204_NO_CONTENT)
def vencer(codigo: str, conn: Conexion) -> Response:
    conn.execute(
        text(
            "UPDATE enlace_recuperacion SET creado_en = clock_timestamp() - interval '1 hour',"
            " vence_en = clock_timestamp() - interval '30 minutes' WHERE codigo_hash = :h"
        ),
        {"h": hash_de(codigo)},
    )
    conn.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class Barrido(BaseModel):
    # Sólo las reservas de esta cuenta; sin correo, las de todas.
    correo: str | None = None
    # La hora en que se hace correr el barrido; sin ella, la de ahora.
    ahora: datetime | None = None


class Registrados(BaseModel):
    registrados: int


@router.post("/recordatorios")
def barrer(
    pedido: Barrido,
    conn: Conexion,
    notificaciones: Annotated[NotificacionesSql, Depends(repositorio_notificaciones)],
) -> Registrados:
    """El barrido de recordatorios corriendo a la hora [ahora], como si el reloj del servidor
    fuera ésa."""
    usuario = None
    if pedido.correo is not None:
        usuario = conn.execute(
            text("SELECT id FROM usuario WHERE activo AND lower(correo) = lower(:c)"),
            {"c": pedido.correo},
        ).scalar_one_or_none()
        conn.rollback()
        if usuario is None:
            return Registrados(registrados=0)
    ahora = pedido.ahora or datetime.now().astimezone()
    return Registrados(
        registrados=enviar_recordatorios(notificaciones, canal_push(), ahora, usuario)
    )


class Dispositivo(BaseModel):
    permiso: bool


class Dispositivos(BaseModel):
    dispositivos: list[Dispositivo]


@router.get("/dispositivos")
def dispositivos(correo: str, conn: Conexion) -> Dispositivos:
    """Los teléfonos que hoy tienen registrados la cuenta [correo], con su permiso."""
    filas = conn.execute(
        text(
            "SELECT d.permiso FROM dispositivo d JOIN usuario u ON u.id = d.usuario_id"
            " WHERE d.activo AND u.activo AND lower(u.correo) = lower(:c) ORDER BY d.id"
        ),
        {"c": correo.strip()},
    ).all()
    conn.rollback()
    return Dispositivos(dispositivos=[Dispositivo(permiso=f.permiso) for f in filas])
