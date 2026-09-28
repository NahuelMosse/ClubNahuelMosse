from datetime import datetime

from sqlalchemy import Connection, text

from app.dominio.horarios import Agenda


class HorariosSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def agenda(self, espacio_id: int) -> Agenda | None:
        fila = self._conn.execute(
            text(
                "SELECT s.apertura, s.cierre, s.dias FROM espacio e"
                " JOIN sede s ON s.id = e.sede_id"
                " WHERE e.id = :id AND e.activo AND s.activa"
            ),
            {"id": espacio_id},
        ).one_or_none()
        self._conn.rollback()
        if fila is None:
            return None
        return Agenda(
            apertura=fila.apertura,
            cierre=fila.cierre,
            dias=tuple(int(d) for d in fila.dias),
        )

    def ocupadas(
        self, espacio_id: int, desde: datetime, hasta: datetime
    ) -> list[tuple[datetime, datetime]]:
        filas = self._conn.execute(
            text(
                "SELECT inicio, fin FROM reserva"
                " WHERE espacio_id = :id AND estado = 'activa'"
                " AND inicio < :hasta AND fin > :desde"
            ),
            {"id": espacio_id, "desde": desde, "hasta": hasta},
        ).all()
        self._conn.rollback()
        return [(f.inicio, f.fin) for f in filas]
