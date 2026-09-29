from datetime import datetime
from typing import Any

from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.aplicacion.errores import (
    AgendaCambiada,
    Cambiado,
    HorarioOcupado,
    NoDisponible,
    NoEncontrada,
)
from app.aplicacion.reservas import Cuando
from app.dominio.horarios import Agenda
from app.dominio.reservas import Reserva
from app.infraestructura.horarios import HorariosSql

_COLUMNAS = (
    "r.id, r.espacio_id, e.sede_id, e.nombre AS espacio, e.deporte, e.tipo,"
    " s.nombre AS sede, s.calle || ' ' || s.altura AS direccion, r.inicio, r.fin,"
    " r.precio_por_hora, r.total, r.estado_actual AS estado, r.motivo,"
    " (r.estado_actual = 'activa' AND r.inicio > now()) AS cancelable"
)
# Cuánto después de hecha una reserva se reconoce como el mismo pedido repetido.
_VENTANA_DE_REINTENTO = "5 minutes"


def _reserva(f: Any) -> Reserva:
    return Reserva(
        id=int(f.id),
        espacio_id=int(f.espacio_id),
        sede_id=int(f.sede_id),
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
        cancelable=bool(f.cancelable),
    )


def _agenda(fila: Any) -> Agenda:
    return Agenda(apertura=fila.apertura, cierre=fila.cierre, dias=tuple(int(d) for d in fila.dias))


class ReservasSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def de_usuario(self, usuario_id: int, cuando: Cuando) -> list[Reserva]:
        proximas = cuando == "proximas"
        filas = self._conn.execute(
            text(
                f"SELECT {_COLUMNAS} FROM reserva_con_estado r"
                " JOIN espacio e ON e.id = r.espacio_id JOIN sede s ON s.id = e.sede_id"
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
        return [_reserva(f) for f in filas]

    def agenda(self, espacio_id: int) -> Agenda | None:
        return HorariosSql(self._conn).agenda(espacio_id)

    def repetida(
        self, usuario_id: int, espacio_id: int, inicio: datetime, fin: datetime
    ) -> Reserva | None:
        fila = self._conn.execute(
            text(
                "SELECT id FROM reserva WHERE usuario_id = :usuario"
                " AND espacio_id = :espacio AND inicio = :inicio AND fin = :fin"
                " AND estado = 'activa'"
                f" AND creado_en > now() - interval '{_VENTANA_DE_REINTENTO}'"
            ),
            {"usuario": usuario_id, "espacio": espacio_id, "inicio": inicio, "fin": fin},
        ).first()
        reserva = None if fila is None else self._una(int(fila.id))
        self._conn.rollback()
        return reserva

    def _una(self, reserva_id: int) -> Reserva:
        fila = self._conn.execute(
            text(
                f"SELECT {_COLUMNAS} FROM reserva_con_estado r JOIN espacio e"
                " ON e.id = r.espacio_id JOIN sede s ON s.id = e.sede_id WHERE r.id = :id"
            ),
            {"id": reserva_id},
        ).one()
        return _reserva(fila)

    def propia(self, usuario_id: int, reserva_id: int) -> Reserva | None:
        fila = self._conn.execute(
            text(
                f"SELECT {_COLUMNAS} FROM reserva_con_estado r JOIN espacio e"
                " ON e.id = r.espacio_id JOIN sede s ON s.id = e.sede_id"
                " WHERE r.id = :id AND r.usuario_id = :usuario"
            ),
            {"id": reserva_id, "usuario": usuario_id},
        ).first()
        self._conn.rollback()
        return None if fila is None else _reserva(fila)

    def tipo_de_espacio(self, espacio_id: int) -> tuple[int, str, str] | None:
        fila = self._conn.execute(
            text("SELECT sede_id, deporte, tipo FROM espacio WHERE id = :id"),
            {"id": espacio_id},
        ).first()
        self._conn.rollback()
        return None if fila is None else (int(fila.sede_id), fila.deporte, fila.tipo)

    def mover(
        self,
        usuario_id: int,
        reserva_id: int,
        antes: tuple[int, datetime],
        espacio_id: int,
        inicio: datetime,
        fin: datetime,
        agenda: Agenda,
    ) -> Reserva:
        datos = {
            "usuario": usuario_id,
            "id": reserva_id,
            "antes": antes[0],
            "desde_antes": antes[1],
            "espacio": espacio_id,
            "inicio": inicio,
            "fin": fin,
        }
        try:
            # El mismo orden que al reservar, la sede compartida y después los espacios
            # exclusivos, y recién entonces la reserva. Los dos espacios van por número: dos
            # cambios cruzados entre las mismas canchas se esperan en vez de trabarse.
            sede = self._conn.execute(
                text(
                    "SELECT s.apertura, s.cierre, s.dias FROM sede s JOIN espacio e"
                    " ON e.sede_id = s.id WHERE e.id = :espacio AND s.activa FOR SHARE OF s"
                ),
                datos,
            ).first()
            if sede is not None and _agenda(sede) != agenda:
                raise AgendaCambiada("la sede cambió de horario")
            espacios = {
                e.id: e
                for e in self._conn.execute(
                    text(
                        "SELECT id, precio_por_hora, activo FROM espacio"
                        " WHERE id IN (:antes, :espacio) ORDER BY id FOR NO KEY UPDATE"
                    ),
                    datos,
                )
            }
            fila = self._conn.execute(
                text(
                    "SELECT estado, inicio <= now() AS empezo,"
                    " espacio_id = :antes AND inicio = :desde_antes AS donde_estaba"
                    " FROM reserva WHERE id = :id AND usuario_id = :usuario FOR UPDATE"
                ),
                datos,
            ).first()
            if fila is None:
                raise NoEncontrada("no hay una reserva suya con ese número")
            if fila.estado != "activa" or fila.empezo or not fila.donde_estaba:
                raise Cambiado("la reserva ya no está activa, ya empezó o ya se movió")
            espacio = espacios.get(espacio_id)
            if sede is None or espacio is None or not espacio.activo:
                raise NoDisponible("el espacio nuevo ya no está activo")
            # El horario anterior se libera en la misma transacción que toma el nuevo: si el
            # nuevo choca con otra reserva, no cambia nada.
            self._conn.execute(
                text(
                    "UPDATE reserva SET espacio_id = :espacio, inicio = :inicio, fin = :fin,"
                    " precio_por_hora = :precio,"
                    " total = :precio * (extract(epoch FROM CAST(:fin AS timestamptz)"
                    " - CAST(:inicio AS timestamptz))::integer / 3600)"
                    " WHERE id = :id"
                ),
                datos | {"precio": int(espacio.precio_por_hora)},
            )
            self._conn.commit()
        except IntegrityError as e:
            self._conn.rollback()
            if getattr(e.orig, "sqlstate", None) == "23P01":
                raise HorarioOcupado("otra reserva activa pisa ese horario") from e
            raise
        except BaseException:
            self._conn.rollback()
            raise
        reserva = self._una(reserva_id)
        self._conn.rollback()
        return reserva

    def cancelar(self, usuario_id: int, reserva_id: int) -> Reserva:
        datos = {"usuario": usuario_id, "id": reserva_id}
        try:
            fila = self._conn.execute(
                text(
                    "SELECT estado, cancelada_por, inicio <= now() AS empezo FROM reserva"
                    " WHERE id = :id AND usuario_id = :usuario FOR UPDATE"
                ),
                datos,
            ).first()
            if fila is None:
                raise NoEncontrada("no hay una reserva suya con ese número")
            if fila.estado == "cancelada" and fila.cancelada_por == usuario_id:
                self._conn.rollback()
                return self._una(reserva_id)
            if fila.estado != "activa" or fila.empezo:
                raise Cambiado("la reserva ya no está activa o ya empezó")
            self._conn.execute(
                text(
                    "UPDATE reserva SET estado = 'cancelada', cancelada_en = now(),"
                    " cancelada_por = :usuario WHERE id = :id"
                ),
                datos,
            )
            self._conn.commit()
        except BaseException:
            self._conn.rollback()
            raise
        reserva = self._una(reserva_id)
        self._conn.rollback()
        return reserva

    def insertar(
        self, usuario_id: int, espacio_id: int, inicio: datetime, fin: datetime, agenda: Agenda
    ) -> Reserva:
        datos = {"usuario": usuario_id, "espacio": espacio_id, "inicio": inicio, "fin": fin}
        try:
            # La cuenta y la sede se toman compartidas, para que ninguna se dé de baja en el
            # medio; el espacio, exclusivo: dos reservas del mismo espacio pasan de a una. Sin
            # eso, cada una ve en el índice de la exclusión la fila sin confirmar de la otra
            # y la base aborta a una por bloqueo mutuo en vez de rechazarla por
            # superposición. La sede va antes que el espacio, el orden de una baja de sede.
            cuenta = self._conn.execute(
                text("SELECT 1 FROM usuario WHERE id = :usuario AND activo FOR SHARE"), datos
            ).first()
            # La sede compartida también fija su horario: si cambió desde que se validó la
            # reserva, se vuelve a validar con el nuevo.
            sede = self._conn.execute(
                text(
                    "SELECT s.apertura, s.cierre, s.dias FROM sede s JOIN espacio e"
                    " ON e.sede_id = s.id WHERE e.id = :espacio AND s.activa FOR SHARE OF s"
                ),
                datos,
            ).first()
            if sede is not None and _agenda(sede) != agenda:
                raise AgendaCambiada("la sede cambió de horario")
            espacio = self._conn.execute(
                text(
                    "SELECT precio_por_hora FROM espacio WHERE id = :espacio AND activo"
                    " FOR NO KEY UPDATE"
                ),
                datos,
            ).first()
            if cuenta is None or sede is None or espacio is None:
                raise NoDisponible("la cuenta o el espacio ya no están activos")
            repetida = self._conn.execute(
                text(
                    "SELECT id FROM reserva WHERE usuario_id = :usuario"
                    " AND espacio_id = :espacio AND inicio = :inicio AND fin = :fin"
                    " AND estado = 'activa'"
                    f" AND creado_en > now() - interval '{_VENTANA_DE_REINTENTO}'"
                ),
                datos,
            ).first()
            if repetida is not None:
                self._conn.rollback()
                return self._una(int(repetida.id))
            nueva: int = self._conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    " total) VALUES (:usuario, :espacio, :inicio, :fin, :precio,"
                    " :precio * (extract(epoch FROM CAST(:fin AS timestamptz)"
                    " - CAST(:inicio AS timestamptz))::integer / 3600)) RETURNING id"
                ),
                datos | {"precio": int(espacio.precio_por_hora)},
            ).scalar_one()
            self._conn.commit()
        except IntegrityError as e:
            self._conn.rollback()
            if getattr(e.orig, "sqlstate", None) == "23P01":
                raise HorarioOcupado("otra reserva activa pisa ese horario") from e
            raise
        except BaseException:
            self._conn.rollback()
            raise
        reserva = self._una(int(nueva))
        self._conn.rollback()
        return reserva
