from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.modules.espacios import EspaciosSql
from app.modules.sedes.reglas import Sede, SedeNueva
from app.shared.db import Conexion, en_transaccion, restriccion_violada
from app.shared.errores import ConReservasFuturas, Duplicado, NoEncontrada, ReservasAfuera
from app.shared.zona import NOMBRE_ZONA_CLUB

_COLUMNAS = "s.id, s.nombre, s.calle, s.altura, s.apertura, s.cierre, s.dias"


def _sede(fila: Any, canchas: int, deportes: tuple[str, ...] = ()) -> Sede:
    return Sede(
        id=fila.id,
        nombre=fila.nombre,
        calle=fila.calle,
        altura=int(fila.altura),
        apertura=fila.apertura,
        cierre=fila.cierre,
        dias=tuple(int(d) for d in fila.dias),
        canchas=canchas,
        deportes=deportes,
    )


# Una reserva queda afuera de un horario si empieza antes de la apertura, termina después
# del cierre (a las 00:00 es la medianoche) o cae en un día que la sede no abre, contado en
# la hora del club.
_AFUERA = (
    "(({ini})::time < CAST(:{p}apertura AS time)"
    " OR ({fin}) - date_trunc('day', {ini}) > CASE WHEN CAST(:{p}cierre AS time) = '00:00'"
    " THEN interval '24 hours' ELSE CAST(:{p}cierre AS time) - time '00:00' END"
    " OR extract(isodow FROM {ini})::smallint <> ALL (CAST(:{p}dias AS smallint[])))"
)


def _afuera(prefijo: str) -> str:
    return _AFUERA.format(
        ini=f"r.inicio AT TIME ZONE '{NOMBRE_ZONA_CLUB}'",
        fin=f"r.fin AT TIME ZONE '{NOMBRE_ZONA_CLUB}'",
        p=prefijo,
    )


class SedesSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def activas(self) -> list[Sede]:
        filas = self._conn.execute(
            text(
                f"SELECT {_COLUMNAS}, count(e.id) AS canchas,"
                " coalesce(array_agg(DISTINCT e.deporte ORDER BY e.deporte)"
                " FILTER (WHERE e.id IS NOT NULL), '{}') AS deportes FROM sede s"
                " LEFT JOIN espacio e ON e.sede_id = s.id AND e.activo"
                " WHERE s.activa GROUP BY s.id ORDER BY lower(s.nombre), s.id"
            )
        ).all()
        self._conn.rollback()
        return [_sede(f, int(f.canchas), tuple(f.deportes)) for f in filas]

    def insertar(self, nueva: SedeNueva, autor: UUID) -> Sede:
        try:
            with en_transaccion(self._conn):
                fila = self._conn.execute(
                    text(
                        "INSERT INTO sede AS s (nombre, calle, altura, apertura, cierre, dias,"
                        " creado_por, modificado_por)"
                        " VALUES (:nombre, :calle, :altura, :apertura, :cierre,"
                        " CAST(:dias AS smallint[]), :autor, :autor)"
                        f" RETURNING {_COLUMNAS}"
                    ),
                    {
                        "nombre": nueva.nombre,
                        "calle": nueva.calle,
                        "altura": nueva.altura,
                        "apertura": nueva.apertura,
                        "cierre": nueva.cierre,
                        "dias": list(nueva.dias),
                        "autor": autor,
                    },
                ).one()
        except IntegrityError as e:
            indice = restriccion_violada(e)
            if indice == "sede_nombre_activa_unico":
                raise Duplicado(["nombre"]) from e
            raise
        return _sede(fila, canchas=0)

    def actualizar(self, sede_id: UUID, datos: SedeNueva, autor: UUID, confirmar: bool) -> Sede:
        valores = {
            "id": sede_id,
            "nombre": datos.nombre,
            "calle": datos.calle,
            "altura": datos.altura,
            "apertura": datos.apertura,
            "cierre": datos.cierre,
            "dias": list(datos.dias),
            "autor": autor,
        }
        try:
            with en_transaccion(self._conn):
                # Exclusiva: una reserva que se está haciendo en la sede termina antes, o espera
                # al horario nuevo y se vuelve a validar con él.
                antes = self._conn.execute(
                    text(
                        "SELECT apertura, cierre, dias FROM sede"
                        " WHERE id = :id AND activa FOR UPDATE"
                    ),
                    valores,
                ).first()
                if antes is None:
                    raise NoEncontrada("la sede ya no está activa")
                if not confirmar:
                    afuera = int(
                        self._conn.execute(
                            text(
                                "SELECT count(*) FROM reserva r"
                                " JOIN espacio e ON e.id = r.espacio_id"
                                " WHERE e.sede_id = :id AND r.estado = 'activa'"
                                " AND r.inicio > now()"
                                f" AND {_afuera('')} AND NOT {_afuera('antes_')}"
                            ),
                            valores
                            | {
                                "antes_apertura": antes.apertura,
                                "antes_cierre": antes.cierre,
                                "antes_dias": list(antes.dias),
                            },
                        ).scalar_one()
                    )
                    if afuera:
                        raise ReservasAfuera(afuera)
                self._conn.execute(
                    text(
                        "UPDATE sede SET nombre = :nombre, calle = :calle, altura = :altura,"
                        " apertura = :apertura, cierre = :cierre, dias = CAST(:dias AS smallint[]),"
                        " modificado_por = :autor, modificado_en = now() WHERE id = :id"
                    ),
                    valores,
                )
        except IntegrityError as e:
            indice = restriccion_violada(e)
            if indice == "sede_nombre_activa_unico":
                raise Duplicado(["nombre"]) from e
            raise
        guardada = next((s for s in self.activas() if s.id == sede_id), None)
        if guardada is None:
            raise NoEncontrada("la sede se dio de baja apenas se guardó")
        return guardada

    def dar_de_baja(self, sede_id: UUID, autor: UUID) -> None:
        datos = {"id": sede_id, "autor": autor}
        with en_transaccion(self._conn):
            # Exclusiva: una reserva que se está haciendo en la sede termina antes y acá se la
            # ve, o espera y encuentra la sede dada de baja.
            if (
                self._conn.execute(
                    text("SELECT 1 FROM sede WHERE id = :id AND activa FOR UPDATE"), datos
                ).first()
                is None
            ):
                raise NoEncontrada("la sede ya no está activa")
            pendientes: int = self._conn.execute(
                text(
                    "SELECT count(*) FROM reserva r JOIN espacio e ON e.id = r.espacio_id"
                    " WHERE e.sede_id = :id AND r.estado = 'activa' AND r.fin > now()"
                ),
                datos,
            ).scalar_one()
            if pendientes:
                raise ConReservasFuturas("la sede tiene reservas que todavía no terminaron")
            EspaciosSql(self._conn).dar_de_baja_de_sede(sede_id, autor)
            self._conn.execute(
                text(
                    "UPDATE sede SET activa = false, dado_de_baja_en = now(),"
                    " dado_de_baja_por = :autor, modificado_por = :autor, modificado_en = now()"
                    " WHERE id = :id"
                ),
                datos,
            )


def repositorio_sedes(conn: Conexion) -> SedesSql:
    return SedesSql(conn)
