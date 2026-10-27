# kit-shape: el repositorio de reservas y la función que lo entrega a las rutas van juntos
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Row, text
from sqlalchemy.exc import IntegrityError

from app.modules.availability import AvailabilitySql, OpeningHours, opening_hours_of_row
from app.modules.notificaciones import (
    DatosDeReserva,
    NotificacionesSql,
    encolar_cancelacion_forzosa,
    mensaje_cancelacion,
)
from app.modules.reservas.reglas import (
    POR_PAGINA,
    Contadores,
    Cuando,
    FiltrosHistorial,
    HistorialDeReservas,
    Reserva,
    ReservaHistorial,
)
from app.shared.club_timezone import CLUB_TIMEZONE_NAME
from app.shared.db import RETRY_WINDOW, DbConnection, in_transaction
from app.shared.errors import (
    ConcurrentChange,
    NotFound,
    OpeningHoursChanged,
    SlotTaken,
    Unavailable,
)

# SQLSTATE de la restricción de exclusión: otra reserva activa pisa el horario.
EXCLUSION_VIOLATION = "23P01"

# El total de una reserva: el precio por las horas completas entre el inicio y el fin.
_TOTAL_SQL = (
    ":precio * (extract(epoch FROM CAST(:fin AS timestamptz)"
    " - CAST(:inicio AS timestamptz))::integer / 3600)"
)

_COLUMNAS_COMUNES = (
    "r.id, r.espacio_id, e.sede_id, e.nombre AS espacio, e.deporte, e.tipo,"
    " s.nombre AS sede, s.calle || ' ' || s.altura AS direccion, r.inicio, r.fin,"
    " r.precio_por_hora, r.total, r.estado_actual AS estado, r.motivo,"
)
_COLUMNAS = f"{_COLUMNAS_COMUNES} (r.estado_actual = 'activa' AND r.inicio > now()) AS cancelable"
_COLUMNAS_HISTORIAL = (
    f"{_COLUMNAS_COMUNES}"
    " r.usuario_id, u.nombre || ' ' || u.apellido AS usuario, r.creado_en, r.cancelada_en,"
    " administrador.nombre || ' ' || administrador.apellido AS cancelada_por_nombre,"
    " (NOT e.activo OR NOT s.activa) AS espacio_de_baja,"
    " (r.estado_actual = 'activa' AND r.inicio > now()) AS anulable,"
    # Un aviso pendiente todavía no consta en la trazabilidad.
    " CASE WHEN aviso.envio IN ('pendiente', 'enviando') THEN NULL ELSE aviso.envio END"
    " AS aviso_envio,"
    " CASE WHEN aviso.envio IN ('pendiente', 'enviando') THEN NULL"
    " WHEN aviso.envio = 'enviada' THEN aviso.enviada_en ELSE aviso.creado_en END AS aviso_en"
)
_DE_RESERVA = (
    " FROM reserva_con_estado r"
    " JOIN espacio e ON e.id = r.espacio_id"
    " JOIN sede s ON s.id = e.sede_id"
)
# Lo que los filtros del historial global miran: alcanza para contar.
_JOIN_FILTROS = f"{_DE_RESERVA} JOIN usuario u ON u.id = r.usuario_id"
_JOIN_HISTORIAL = (
    f"{_JOIN_FILTROS}"
    " LEFT JOIN usuario administrador ON administrador.id = r.cancelada_por"
    " LEFT JOIN notificacion_reserva vinculo ON vinculo.reserva_id = r.id"
    " LEFT JOIN notificacion aviso ON aviso.id = vinculo.notificacion_id"
)
_SEDE_COMPARTIDA = (
    "SELECT s.apertura, s.cierre, s.dias FROM sede s JOIN espacio e"
    " ON e.sede_id = s.id WHERE e.id = :espacio AND s.activa FOR SHARE OF s"
)

# Los días del filtro se cortan a medianoche del club, no de la sesión de Postgres (UTC).
_ZONA_CLUB = f"'{CLUB_TIMEZONE_NAME}'"


@contextmanager
def _horario_ocupado() -> Iterator[None]:
    """Una superposición con otra reserva activa sale como `SlotTaken`."""
    try:
        yield
    except IntegrityError as e:
        if getattr(e.orig, "sqlstate", None) == EXCLUSION_VIOLATION:
            raise SlotTaken("otra reserva activa pisa ese horario") from e
        raise


def _condiciones_comunes(filtros: FiltrosHistorial) -> tuple[list[str], dict[str, Any]]:
    """Las condiciones que valen para el total y para los contadores, y sus parámetros."""
    condiciones: list[str] = []
    parametros: dict[str, Any] = {}
    if filtros.sede_id is not None:
        condiciones.append("e.sede_id = :sede_id")
        parametros["sede_id"] = filtros.sede_id
    if filtros.deporte is not None:
        condiciones.append("e.deporte = :deporte")
        parametros["deporte"] = filtros.deporte
    if filtros.desde is not None:
        condiciones.append(
            f"r.inicio >= (CAST(:desde AS date)::timestamp AT TIME ZONE {_ZONA_CLUB})"
        )
        parametros["desde"] = filtros.desde
    if filtros.hasta is not None:
        condiciones.append(
            f"r.inicio < ((CAST(:hasta AS date) + 1)::timestamp AT TIME ZONE {_ZONA_CLUB})"
        )
        parametros["hasta"] = filtros.hasta
    if filtros.q is not None and filtros.q.strip():
        condiciones.append(
            "(u.nombre || ' ' || u.apellido ILIKE :q ESCAPE '\\'"
            " OR s.nombre ILIKE :q ESCAPE '\\' OR e.nombre ILIKE :q ESCAPE '\\')"
        )
        literal = filtros.q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        parametros["q"] = f"%{literal}%"
    return condiciones, parametros


class ReservasSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def de_usuario(self, usuario_id: UUID, cuando: Cuando) -> list[Reserva]:
        orden = (
            " AND r.estado_actual = 'activa' ORDER BY r.inicio, r.id"
            if cuando == "proximas"
            else " AND r.estado_actual <> 'activa' ORDER BY r.inicio DESC, r.id DESC"
        )
        filas = self._conn.execute(
            text(f"SELECT {_COLUMNAS}{_DE_RESERVA} WHERE r.usuario_id = :usuario{orden}"),
            {"usuario": usuario_id},
        ).all()
        self._conn.rollback()
        return [Reserva(**f._mapping) for f in filas]

    def agenda(self, espacio_id: UUID) -> OpeningHours | None:
        return AvailabilitySql(self._conn).opening_hours(espacio_id)

    def _id_repetida(self, datos: dict[str, Any]) -> UUID | None:
        """La reserva activa que el mismo pedido ya hizo hace un momento, si la hay."""
        fila = self._conn.execute(
            text(
                "SELECT id FROM reserva WHERE usuario_id = :usuario"
                " AND espacio_id = :espacio AND inicio = :inicio AND fin = :fin"
                " AND estado = 'activa'"
                f" AND creado_en > now() - interval '{RETRY_WINDOW}'"
            ),
            datos,
        ).first()
        return None if fila is None else fila.id

    def repetida(
        self, usuario_id: UUID, espacio_id: UUID, inicio: datetime, fin: datetime
    ) -> Reserva | None:
        id_repetida = self._id_repetida(
            {"usuario": usuario_id, "espacio": espacio_id, "inicio": inicio, "fin": fin}
        )
        reserva = None if id_repetida is None else self._una(id_repetida)
        self._conn.rollback()
        return reserva

    def _una(self, reserva_id: UUID) -> Reserva:
        fila = self._conn.execute(
            text(f"SELECT {_COLUMNAS}{_DE_RESERVA} WHERE r.id = :id"), {"id": reserva_id}
        ).one()
        return Reserva(**fila._mapping)

    def propia(self, usuario_id: UUID, reserva_id: UUID) -> Reserva | None:
        fila = self._conn.execute(
            text(f"SELECT {_COLUMNAS}{_DE_RESERVA} WHERE r.id = :id AND r.usuario_id = :usuario"),
            {"id": reserva_id, "usuario": usuario_id},
        ).first()
        self._conn.rollback()
        return None if fila is None else Reserva(**fila._mapping)

    def tipo_de_espacio(self, espacio_id: UUID) -> tuple[UUID, str, str] | None:
        fila = self._conn.execute(
            text("SELECT sede_id, deporte, tipo FROM espacio WHERE id = :id"),
            {"id": espacio_id},
        ).first()
        self._conn.rollback()
        return None if fila is None else (fila.sede_id, fila.deporte, fila.tipo)

    def _sede_vigente(self, datos: dict[str, Any], agenda: OpeningHours) -> Row[Any] | None:
        """Toma compartida la sede del espacio, que así fija su horario: si cambió desde que se
        validó la reserva, se vuelve a validar con el nuevo."""
        sede = self._conn.execute(text(_SEDE_COMPARTIDA), datos).first()
        if sede is not None and opening_hours_of_row(sede) != agenda:
            raise OpeningHoursChanged("la sede cambió de horario")
        return sede

    def mover(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
        self,
        usuario_id: UUID,
        reserva_id: UUID,
        antes: tuple[UUID, datetime],
        espacio_id: UUID,
        inicio: datetime,
        fin: datetime,
        agenda: OpeningHours,
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
        with _horario_ocupado(), in_transaction(self._conn):
            # Como al reservar: sede compartida, espacios exclusivos (por número: dos cambios
            # cruzados entre las mismas canchas se esperan en vez de trabarse) y la reserva.
            sede = self._sede_vigente(datos, agenda)
            espacios = self._bloquear_espacios(datos)
            self._exigir_reserva_movible(datos)
            espacio = espacios.get(espacio_id)
            if sede is None or espacio is None or not espacio.activo:
                raise Unavailable("el espacio nuevo ya no está activo")
            # El horario anterior se libera en la misma transacción que toma el nuevo: si el
            # nuevo choca con otra reserva, no cambia nada.
            self._conn.execute(
                text(
                    "UPDATE reserva SET espacio_id = :espacio, inicio = :inicio, fin = :fin,"
                    f" precio_por_hora = :precio, total = {_TOTAL_SQL} WHERE id = :id"
                ),
                datos | {"precio": int(espacio.precio_por_hora)},
            )
        reserva = self._una(reserva_id)
        self._conn.rollback()
        return reserva

    def _bloquear_espacios(self, datos: dict[str, Any]) -> dict[UUID, Row[Any]]:
        filas = self._conn.execute(
            text(
                "SELECT id, precio_por_hora, activo FROM espacio"
                " WHERE id IN (:antes, :espacio) ORDER BY id FOR NO KEY UPDATE"
            ),
            datos,
        )
        return {e.id: e for e in filas}

    def _exigir_reserva_movible(self, datos: dict[str, Any]) -> None:
        fila = self._conn.execute(
            text(
                "SELECT estado, inicio <= now() AS empezo,"
                " espacio_id = :antes AND inicio = :desde_antes AS donde_estaba"
                " FROM reserva WHERE id = :id AND usuario_id = :usuario FOR UPDATE"
            ),
            datos,
        ).first()
        if fila is None:
            raise NotFound("no hay una reserva suya con ese número")
        if fila.estado != "activa" or fila.empezo or not fila.donde_estaba:
            raise ConcurrentChange("la reserva ya no está activa, ya empezó o ya se movió")

    def cancelar(self, usuario_id: UUID, reserva_id: UUID) -> Reserva:
        datos = {"usuario": usuario_id, "id": reserva_id}
        with in_transaction(self._conn):
            fila = self._conn.execute(
                text(
                    "SELECT estado, cancelada_por, inicio <= now() AS empezo FROM reserva"
                    " WHERE id = :id AND usuario_id = :usuario FOR UPDATE"
                ),
                datos,
            ).first()
            if fila is None:
                raise NotFound("no hay una reserva suya con ese número")
            if fila.estado == "cancelada" and fila.cancelada_por == usuario_id:
                self._conn.rollback()
                return self._una(reserva_id)
            if fila.estado != "activa" or fila.empezo:
                raise ConcurrentChange("la reserva ya no está activa o ya empezó")
            self._conn.execute(
                text(
                    "UPDATE reserva SET estado = 'cancelada', cancelada_en = now(),"
                    " cancelada_por = :usuario WHERE id = :id"
                ),
                datos,
            )
            reserva = self._una(reserva_id)
            # La confirmación se encola en la misma transacción: si la cancelación no se
            # completa no queda aviso, y el índice único evita repetirlo.
            datos_de_reserva = DatosDeReserva(
                reserva.id, reserva.deporte, reserva.tipo, reserva.sede, reserva.inicio
            )
            NotificacionesSql(self._conn).encolar_cancelacion_usuario(
                usuario_id, reserva_id, reserva.inicio, mensaje_cancelacion(datos_de_reserva)
            )
        return reserva

    def cancelar_futuras_de(self, usuario_id: UUID) -> None:
        """Cancela las reservas activas que todavía no empezaron de una cuenta que se da de
        baja, dentro de la transacción de quien llama: sin commit."""
        self._conn.execute(
            text(
                "UPDATE reserva SET estado = 'cancelada', cancelada_en = clock_timestamp(),"
                " cancelada_por = :id WHERE usuario_id = :id AND estado = 'activa'"
                " AND inicio > clock_timestamp()"
            ),
            {"id": usuario_id},
        )

    def _bloquear_para_alta(self, datos: dict[str, Any], agenda: OpeningHours) -> Row[Any]:
        """La cuenta y la sede se toman compartidas, para que ninguna se dé de baja en el
        medio; el espacio, exclusivo: dos reservas del mismo espacio pasan de a una. Sin eso,
        cada una ve en el índice de la exclusión la fila sin confirmar de la otra y la base
        aborta a una por bloqueo mutuo en vez de rechazarla por superposición. La sede va
        antes que el espacio, el orden de una baja de sede. Devuelve el espacio."""
        cuenta = self._conn.execute(
            text("SELECT 1 FROM usuario WHERE id = :usuario AND activo FOR SHARE"), datos
        ).first()
        sede = self._sede_vigente(datos, agenda)
        espacio = self._conn.execute(
            text(
                "SELECT precio_por_hora FROM espacio WHERE id = :espacio AND activo"
                " FOR NO KEY UPDATE"
            ),
            datos,
        ).first()
        if cuenta is None or sede is None or espacio is None:
            raise Unavailable("la cuenta o el espacio ya no están activos")
        return espacio

    def insertar(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
        self,
        usuario_id: UUID,
        espacio_id: UUID,
        inicio: datetime,
        fin: datetime,
        agenda: OpeningHours,
    ) -> Reserva:
        datos = {"usuario": usuario_id, "espacio": espacio_id, "inicio": inicio, "fin": fin}
        with _horario_ocupado(), in_transaction(self._conn):
            espacio = self._bloquear_para_alta(datos, agenda)
            repetida = self._id_repetida(datos)
            if repetida is not None:
                self._conn.rollback()
                return self._una(repetida)
            nueva: UUID = self._conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    f" total) VALUES (:usuario, :espacio, :inicio, :fin, :precio, {_TOTAL_SQL})"
                    " RETURNING id"
                ),
                datos | {"precio": int(espacio.precio_por_hora)},
            ).scalar_one()
        reserva = self._una(nueva)
        self._conn.rollback()
        return reserva

    def _bloquear_para_anular(self, datos: dict[str, Any]) -> Row[Any]:
        """Se mira sin bloquear a quién pertenece la reserva para tomar los bloqueos en el
        orden de siempre: la cuenta y la sede compartidas, el espacio exclusivo y recién
        entonces la reserva. Si la reserva se movió de espacio en el medio, el espacio
        bloqueado ya no es el suyo y se rechaza como cambiada. Completa `datos` con la
        cuenta, la sede y el espacio y devuelve la fila de la reserva."""
        previa = self._conn.execute(
            text(
                "SELECT r.usuario_id, r.espacio_id, e.sede_id FROM reserva r"
                " JOIN espacio e ON e.id = r.espacio_id WHERE r.id = :id"
            ),
            datos,
        ).first()
        if previa is None:
            raise NotFound("no hay una reserva con ese número")
        datos |= {
            "usuario": previa.usuario_id,
            "sede": previa.sede_id,
            "espacio_previo": previa.espacio_id,
        }
        self._conn.execute(text("SELECT 1 FROM usuario WHERE id = :usuario FOR SHARE"), datos)
        self._conn.execute(text("SELECT 1 FROM sede WHERE id = :sede FOR SHARE"), datos)
        self._conn.execute(
            text("SELECT 1 FROM espacio WHERE id = :espacio_previo FOR NO KEY UPDATE"), datos
        )
        return previa

    def _bloquear_reserva_a_anular(self, datos: dict[str, Any]) -> Row[Any]:
        fila = self._conn.execute(
            text(
                "SELECT estado, motivo, cancelada_por, inicio <= now() AS empezo,"
                " espacio_id = :espacio_previo AND espacio_id = :espacio"
                " AND inicio = CAST(:inicio AS timestamptz) AS como_se_vio"
                " FROM reserva WHERE id = :id FOR UPDATE"
            ),
            datos,
        ).first()
        if fila is None:
            raise NotFound("no hay una reserva con ese número")
        return fila

    def anular(  # noqa: PLR0913, PLR0917 -- firma pública fijada por sus llamadores
        self, admin_id: UUID, reserva_id: UUID, motivo: str, espacio_id: UUID, inicio: datetime
    ) -> ReservaHistorial:
        datos: dict[str, Any] = {
            "admin": admin_id,
            "id": reserva_id,
            "motivo": motivo,
            "espacio": espacio_id,
            "inicio": inicio,
        }
        with in_transaction(self._conn):
            previa = self._bloquear_para_anular(datos)
            fila = self._bloquear_reserva_a_anular(datos)
            if (
                fila.estado == "anulada"
                and fila.cancelada_por == admin_id
                and fila.motivo == motivo
            ):
                self._conn.rollback()
                return self._detalle(reserva_id)
            if fila.estado != "activa" or fila.empezo or not fila.como_se_vio:
                raise ConcurrentChange("la reserva ya no está activa, ya empezó o cambió")
            self._conn.execute(
                text(
                    "UPDATE reserva SET estado = 'anulada', motivo = :motivo,"
                    " cancelada_en = now(), cancelada_por = :admin WHERE id = :id"
                ),
                datos,
            )
            # El aviso se encola en la misma transacción, después de los bloqueos de siempre.
            encolar_cancelacion_forzosa(self._conn, previa.usuario_id, [reserva_id])
        return self._detalle(reserva_id)

    def _detalle(self, reserva_id: UUID) -> ReservaHistorial:
        detalle = self.una_de_cualquiera(reserva_id)
        if detalle is None:
            raise NotFound("no hay una reserva con ese número")
        return detalle

    def _contar(
        self, comunes: list[str], total_de: str, parametros: dict[str, Any]
    ) -> tuple[int, Contadores]:
        """El total y los cuatro contadores salen de una sola pasada por las filas que pasan
        los filtros comunes, sin las uniones que sólo hacen falta para mostrar cada reserva."""
        fila = self._conn.execute(
            text(
                f"SELECT {total_de} AS total, count(*) AS todas,"
                " count(*) FILTER (WHERE r.estado_actual = 'activa') AS activas,"
                " count(*) FILTER (WHERE r.estado_actual = 'completada') AS completadas,"
                " count(*) FILTER (WHERE r.estado_actual = 'anulada') AS anuladas"
                f"{_JOIN_FILTROS} WHERE {' AND '.join(['true', *comunes])}"
            ),
            parametros,
        ).one()
        contadores = Contadores(
            todas=int(fila.todas),
            activas=int(fila.activas),
            completadas=int(fila.completadas),
            anuladas=int(fila.anuladas),
        )
        return int(fila.total), contadores

    def historial(self, filtros: FiltrosHistorial) -> HistorialDeReservas:
        comunes, parametros = _condiciones_comunes(filtros)
        condiciones = list(comunes)
        total_de = "count(*)"
        if filtros.estado is not None:
            condiciones.append("r.estado_actual = :estado")
            parametros["estado"] = filtros.estado
            total_de = "count(*) FILTER (WHERE r.estado_actual = :estado)"
        total, contadores = self._contar(comunes, total_de, parametros)
        pagina = max(1, filtros.pagina)
        filas = self._conn.execute(
            text(
                f"SELECT {_COLUMNAS_HISTORIAL}{_JOIN_HISTORIAL}"
                f" WHERE {' AND '.join(['true', *condiciones])}"
                " ORDER BY r.inicio DESC, r.id DESC LIMIT :limite OFFSET :offset"
            ),
            parametros | {"limite": POR_PAGINA, "offset": (pagina - 1) * POR_PAGINA},
        ).all()
        self._conn.rollback()
        return HistorialDeReservas(
            reservas=[ReservaHistorial(**f._mapping) for f in filas],
            total=total,
            pagina=pagina,
            por_pagina=POR_PAGINA,
            contadores=contadores,
        )

    def una_de_cualquiera(self, reserva_id: UUID) -> ReservaHistorial | None:
        fila = self._conn.execute(
            text(f"SELECT {_COLUMNAS_HISTORIAL}{_JOIN_HISTORIAL} WHERE r.id = :id"),
            {"id": reserva_id},
        ).first()
        self._conn.rollback()
        return None if fila is None else ReservaHistorial(**fila._mapping)


def repositorio_reservas(conn: DbConnection) -> ReservasSql:
    return ReservasSql(conn)
