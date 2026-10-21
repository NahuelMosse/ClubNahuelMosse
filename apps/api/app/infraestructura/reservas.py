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
from app.dominio.notificaciones import mensaje_cancelacion
from app.dominio.reservas import (
    POR_PAGINA,
    Contadores,
    FiltrosHistorial,
    HistorialDeReservas,
    Marcador,
    Reserva,
    ReservaHistorial,
    TandaDeReservas,
)
from app.infraestructura.horarios import HorariosSql
from app.infraestructura.notificaciones import encolar_cancelacion_forzosa

_COLUMNAS = (
    "r.id, r.espacio_id, e.sede_id, e.nombre AS espacio, e.deporte, e.tipo,"
    " s.nombre AS sede, s.calle || ' ' || s.altura AS direccion, r.inicio, r.fin,"
    " r.precio_por_hora, r.total, r.estado_actual AS estado, r.motivo,"
    " (r.estado_actual = 'activa' AND r.inicio > now()) AS cancelable"
)
_COLUMNAS_HISTORIAL = (
    "r.id, r.espacio_id, e.sede_id, e.nombre AS espacio, e.deporte, e.tipo,"
    " s.nombre AS sede, s.calle || ' ' || s.altura AS direccion, r.inicio, r.fin,"
    " r.precio_por_hora, r.total, r.estado_actual AS estado, r.motivo,"
    " r.usuario_id, u.nombre || ' ' || u.apellido AS usuario, r.creado_en, r.cancelada_en,"
    " administrador.nombre || ' ' || administrador.apellido AS cancelada_por_nombre,"
    " (NOT e.activo OR NOT s.activa) AS espacio_de_baja,"
    " (r.estado_actual = 'activa' AND r.inicio > now()) AS anulable,"
    # Un aviso pendiente todavía no consta en la trazabilidad.
    " CASE WHEN aviso.envio IN ('pendiente', 'enviando') THEN NULL ELSE aviso.envio END"
    " AS aviso_envio,"
    " CASE WHEN aviso.envio IN ('pendiente', 'enviando') THEN NULL"
    " WHEN aviso.envio = 'enviada' THEN aviso.enviada_en ELSE aviso.creada_en END AS aviso_en"
)
# Lo que los filtros del historial global miran: alcanza para contar.
_JOIN_FILTROS = (
    " FROM reserva_con_estado r"
    " JOIN espacio e ON e.id = r.espacio_id"
    " JOIN sede s ON s.id = e.sede_id"
    " JOIN usuario u ON u.id = r.usuario_id"
)
_JOIN_HISTORIAL = (
    f"{_JOIN_FILTROS}"
    " LEFT JOIN usuario administrador ON administrador.id = r.cancelada_por"
    " LEFT JOIN notificacion_reserva vinculo ON vinculo.reserva_id = r.id"
    " LEFT JOIN notificacion aviso ON aviso.id = vinculo.notificacion_id"
)
# Cuánto después de hecha una reserva se reconoce como el mismo pedido repetido.
_VENTANA_DE_REINTENTO = "5 minutes"

# Los días del filtro se cortan a medianoche del club, no de la sesión de Postgres (UTC).
_ZONA_CLUB = "'America/Argentina/Buenos_Aires'"


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


def _reserva_historial(f: Any) -> ReservaHistorial:
    return ReservaHistorial(
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
        usuario_id=int(f.usuario_id),
        usuario=f.usuario,
        creado_en=f.creado_en,
        cancelada_en=f.cancelada_en,
        cancelada_por_nombre=f.cancelada_por_nombre,
        espacio_de_baja=bool(f.espacio_de_baja),
        anulable=bool(f.anulable),
        aviso_envio=f.aviso_envio,
        aviso_en=f.aviso_en,
    )


def _agenda(fila: Any) -> Agenda:
    return Agenda(apertura=fila.apertura, cierre=fila.cierre, dias=tuple(int(d) for d in fila.dias))


class ReservasSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def de_usuario(
        self,
        usuario_id: int,
        cuando: Cuando,
        despues: Marcador | None = None,
        limite: int = POR_PAGINA,
    ) -> TandaDeReservas:
        proximas = cuando == "proximas"
        # Se piden `limite + 1`: la que sobra no se entrega, sólo dice que hay más.
        parametros: dict[str, Any] = {"usuario": usuario_id, "limite": limite + 1}
        despues_de = ""
        if despues is not None:
            despues_de = f" AND (r.inicio, r.id) {'>' if proximas else '<'} (:inicio, :id)"
            parametros |= {"inicio": despues.inicio, "id": despues.id}
        filas = self._conn.execute(
            text(
                f"SELECT {_COLUMNAS} FROM reserva_con_estado r"
                " JOIN espacio e ON e.id = r.espacio_id JOIN sede s ON s.id = e.sede_id"
                f" WHERE r.usuario_id = :usuario{despues_de}"
                + (
                    " AND r.estado_actual = 'activa' ORDER BY r.inicio, r.id"
                    if proximas
                    else " AND r.estado_actual <> 'activa' ORDER BY r.inicio DESC, r.id DESC"
                )
                + " LIMIT :limite"
            ),
            parametros,
        ).all()
        self._conn.rollback()
        return TandaDeReservas(
            reservas=[_reserva(f) for f in filas[:limite]], hay_mas=len(filas) > limite
        )

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
            reserva = self._una(reserva_id)
            # La confirmación se encola en la misma transacción: si la cancelación no se
            # completa no queda aviso, y el índice único evita repetirlo.
            aviso = mensaje_cancelacion(reserva)
            self._conn.execute(
                text(
                    "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                    " reserva_inicio, envio) VALUES (:usuario, 'cancelacion_usuario', :titulo,"
                    " :cuerpo, :id, :inicio, 'pendiente')"
                    " ON CONFLICT (reserva_id) WHERE tipo = 'cancelacion_usuario' DO NOTHING"
                ),
                datos | {"titulo": aviso.titulo, "cuerpo": aviso.cuerpo, "inicio": reserva.inicio},
            )
            self._conn.commit()
        except BaseException:
            self._conn.rollback()
            raise
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

    def anular(
        self, admin_id: int, reserva_id: int, motivo: str, espacio_id: int, inicio: datetime
    ) -> ReservaHistorial:
        datos: dict[str, Any] = {
            "admin": admin_id,
            "id": reserva_id,
            "motivo": motivo,
            "espacio": espacio_id,
            "inicio": inicio,
        }
        try:
            # Se mira sin bloquear a quién pertenece la reserva para tomar los bloqueos en el
            # orden de siempre: la cuenta y la sede compartidas, el espacio exclusivo y recién
            # entonces la reserva. Si la reserva se movió de espacio en el medio, el espacio
            # bloqueado ya no es el suyo y se rechaza como cambiada.
            previa = self._conn.execute(
                text(
                    "SELECT r.usuario_id, r.espacio_id, e.sede_id FROM reserva r"
                    " JOIN espacio e ON e.id = r.espacio_id WHERE r.id = :id"
                ),
                datos,
            ).first()
            if previa is None:
                raise NoEncontrada("no hay una reserva con ese número")
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
                raise NoEncontrada("no hay una reserva con ese número")
            if (
                fila.estado == "anulada"
                and fila.cancelada_por == admin_id
                and fila.motivo == motivo
            ):
                self._conn.rollback()
                return self._detalle(reserva_id)
            if fila.estado != "activa" or fila.empezo or not fila.como_se_vio:
                raise Cambiado("la reserva ya no está activa, ya empezó o cambió")
            self._conn.execute(
                text(
                    "UPDATE reserva SET estado = 'anulada', motivo = :motivo,"
                    " cancelada_en = now(), cancelada_por = :admin WHERE id = :id"
                ),
                datos,
            )
            # El aviso se encola en la misma transacción, después de los bloqueos de siempre.
            encolar_cancelacion_forzosa(self._conn, int(previa.usuario_id), [reserva_id])
            self._conn.commit()
        except BaseException:
            self._conn.rollback()
            raise
        return self._detalle(reserva_id)

    def _detalle(self, reserva_id: int) -> ReservaHistorial:
        fila = self._conn.execute(
            text(f"SELECT {_COLUMNAS_HISTORIAL}{_JOIN_HISTORIAL} WHERE r.id = :id"),
            {"id": reserva_id},
        ).one()
        self._conn.rollback()
        return _reserva_historial(fila)

    def historial(self, filtros: FiltrosHistorial) -> HistorialDeReservas:
        comunes: list[str] = []
        parametros: dict[str, Any] = {}
        if filtros.sede_id is not None:
            comunes.append("e.sede_id = :sede_id")
            parametros["sede_id"] = filtros.sede_id
        if filtros.deporte is not None:
            comunes.append("e.deporte = :deporte")
            parametros["deporte"] = filtros.deporte
        if filtros.desde is not None:
            comunes.append(
                f"r.inicio >= (CAST(:desde AS date)::timestamp AT TIME ZONE {_ZONA_CLUB})"
            )
            parametros["desde"] = filtros.desde
        if filtros.hasta is not None:
            comunes.append(
                f"r.inicio < ((CAST(:hasta AS date) + 1)::timestamp AT TIME ZONE {_ZONA_CLUB})"
            )
            parametros["hasta"] = filtros.hasta
        if filtros.q is not None and filtros.q.strip():
            comunes.append(
                "(u.nombre || ' ' || u.apellido ILIKE :q ESCAPE '\\'"
                " OR s.nombre ILIKE :q ESCAPE '\\' OR e.nombre ILIKE :q ESCAPE '\\')"
            )
            literal = (
                filtros.q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
            )
            parametros["q"] = f"%{literal}%"
        where_comun = " AND ".join(["true", *comunes])
        condiciones = list(comunes)
        total_de = "count(*)"
        if filtros.estado is not None:
            condiciones.append("r.estado_actual = :estado")
            parametros["estado"] = filtros.estado
            total_de = "count(*) FILTER (WHERE r.estado_actual = :estado)"
        where = " AND ".join(["true", *condiciones])

        # El total y los cuatro contadores salen de una sola pasada por las filas que pasan los
        # filtros comunes, sin las uniones que sólo hacen falta para mostrar cada reserva.
        fila_contadores = self._conn.execute(
            text(
                f"SELECT {total_de} AS total, count(*) AS todas,"
                " count(*) FILTER (WHERE r.estado_actual = 'activa') AS activas,"
                " count(*) FILTER (WHERE r.estado_actual = 'completada') AS completadas,"
                " count(*) FILTER (WHERE r.estado_actual = 'anulada') AS anuladas"
                f"{_JOIN_FILTROS} WHERE {where_comun}"
            ),
            parametros,
        ).one()
        pagina = max(1, filtros.pagina)
        # Con marcador, la página sigue a la última reserva vista; sin él, cuenta `pagina` (las
        # apps ya instaladas). Se piden POR_PAGINA + 1: la que sobra sólo dice que hay más.
        if filtros.despues is not None:
            where += " AND (r.inicio, r.id) < (:inicio, :id)"
            parametros |= {"inicio": filtros.despues.inicio, "id": filtros.despues.id}
            salteadas = 0
        else:
            salteadas = (pagina - 1) * POR_PAGINA
        filas = self._conn.execute(
            text(
                f"SELECT {_COLUMNAS_HISTORIAL}{_JOIN_HISTORIAL} WHERE {where}"
                " ORDER BY r.inicio DESC, r.id DESC LIMIT :limite OFFSET :offset"
            ),
            parametros | {"limite": POR_PAGINA + 1, "offset": salteadas},
        ).all()
        self._conn.rollback()
        return HistorialDeReservas(
            reservas=[_reserva_historial(f) for f in filas[:POR_PAGINA]],
            total=int(fila_contadores.total),
            pagina=pagina,
            por_pagina=POR_PAGINA,
            contadores=Contadores(
                todas=int(fila_contadores.todas),
                activas=int(fila_contadores.activas),
                completadas=int(fila_contadores.completadas),
                anuladas=int(fila_contadores.anuladas),
            ),
            hay_mas=len(filas) > POR_PAGINA,
        )

    def una_de_cualquiera(self, reserva_id: int) -> ReservaHistorial | None:
        fila = self._conn.execute(
            text(f"SELECT {_COLUMNAS_HISTORIAL}{_JOIN_HISTORIAL} WHERE r.id = :id"),
            {"id": reserva_id},
        ).first()
        self._conn.rollback()
        return None if fila is None else _reserva_historial(fila)
