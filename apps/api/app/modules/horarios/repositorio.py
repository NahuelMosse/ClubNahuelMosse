from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.modules.espacios import COLUMNAS_DE_ESPACIO, Espacio, espacio_de_fila
from app.modules.horarios.reglas import Agenda
from app.shared.db import Conexion


def agenda_de_fila(fila: Any) -> Agenda:
    """Los días van en tupla: la agenda se compara con `!=` contra otra para saber si cambió."""
    return Agenda(apertura=fila.apertura, cierre=fila.cierre, dias=tuple(int(d) for d in fila.dias))


class HorariosSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def agenda(self, espacio_id: UUID) -> Agenda | None:
        fila = self._conn.execute(
            text(
                "SELECT s.apertura, s.cierre, s.dias FROM espacio e"
                " JOIN sede s ON s.id = e.sede_id"
                " WHERE e.id = :id AND e.activo AND s.activa"
            ),
            {"id": espacio_id},
        ).one_or_none()
        self._conn.rollback()
        return None if fila is None else agenda_de_fila(fila)

    def agenda_de_sede(self, sede_id: UUID) -> Agenda | None:
        fila = self._conn.execute(
            text("SELECT apertura, cierre, dias FROM sede WHERE id = :id AND activa"),
            {"id": sede_id},
        ).one_or_none()
        self._conn.rollback()
        return None if fila is None else agenda_de_fila(fila)

    def libres(
        self, sede_id: UUID, deporte: str, tipo: str | None, inicio: datetime, fin: datetime
    ) -> list[Espacio]:
        filas = self._conn.execute(
            text(
                f"SELECT {COLUMNAS_DE_ESPACIO} FROM espacio e JOIN sede s ON s.id = e.sede_id"
                " WHERE e.activo AND s.activa AND e.sede_id = :sede AND e.deporte = :deporte"
                " AND (CAST(:tipo AS text) IS NULL OR e.tipo = :tipo)"
                " AND NOT EXISTS (SELECT 1 FROM reserva r WHERE r.espacio_id = e.id"
                " AND r.estado = 'activa' AND r.inicio < :fin AND r.fin > :inicio)"
                " ORDER BY e.deporte, e.tipo, e.numero"
            ),
            {"sede": sede_id, "deporte": deporte, "tipo": tipo, "inicio": inicio, "fin": fin},
        ).all()
        self._conn.rollback()
        return [espacio_de_fila(f) for f in filas]

    def ocupadas(
        self,
        espacio_id: UUID,
        desde: datetime,
        hasta: datetime,
        salvo: tuple[UUID, UUID] | None = None,
    ) -> list[tuple[datetime, datetime]]:
        reserva, usuario = salvo or (None, None)
        filas = self._conn.execute(
            text(
                "SELECT inicio, fin FROM reserva"
                " WHERE espacio_id = :id AND estado = 'activa'"
                " AND inicio < :hasta AND fin > :desde"
                " AND (CAST(:reserva AS uuid) IS NULL"
                "      OR NOT (id = :reserva AND usuario_id = CAST(:usuario AS uuid)))"
            ),
            {
                "id": espacio_id,
                "desde": desde,
                "hasta": hasta,
                "reserva": reserva,
                "usuario": usuario,
            },
        ).all()
        self._conn.rollback()
        return [(f.inicio, f.fin) for f in filas]


def repositorio_horarios(conn: Conexion) -> HorariosSql:
    return HorariosSql(conn)
