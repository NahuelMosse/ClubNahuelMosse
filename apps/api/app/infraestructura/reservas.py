from sqlalchemy import Connection, text

from app.aplicacion.reservas import Cuando
from app.dominio.reservas import Reserva


class ReservasSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def de_usuario(self, usuario_id: int, cuando: Cuando) -> list[Reserva]:
        proximas = cuando == "proximas"
        filas = self._conn.execute(
            text(
                "SELECT r.id, r.espacio_id, e.nombre AS espacio, e.deporte, e.tipo,"
                " s.nombre AS sede, s.calle || ' ' || s.altura AS direccion, r.inicio, r.fin,"
                " r.precio_por_hora, r.total, r.estado_actual AS estado, r.motivo"
                " FROM reserva_con_estado r JOIN espacio e ON e.id = r.espacio_id"
                " JOIN sede s ON s.id = e.sede_id"
                " WHERE r.usuario_id = :usuario"
                + (
                    " AND r.estado_actual = 'activa' ORDER BY r.inicio, r.id"
                    if proximas
                    else " AND r.estado_actual <> 'activa' ORDER BY r.inicio DESC, r.id DESC"
                )
            ),
            {"usuario": usuario_id},
        ).all()
        self._conn.rollback()
        return [
            Reserva(
                id=int(f.id),
                espacio_id=int(f.espacio_id),
                espacio=f.espacio,
                deporte=f.deporte,
                tipo=f.tipo,
                sede=f.sede,
                direccion=f.direccion,
                inicio=f.inicio,
                fin=f.fin,
                precio_por_hora=int(f.precio_por_hora),
                total=int(f.total),
                estado=f.estado,
                motivo=f.motivo,
            )
            for f in filas
        ]
