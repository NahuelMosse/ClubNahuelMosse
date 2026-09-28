from typing import Any

from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.aplicacion.errores import Duplicado
from app.dominio.sedes import Sede, SedeNueva

_COLUMNAS = "s.id, s.nombre, s.calle, s.altura, s.apertura, s.cierre, s.dias"


def _sede(fila: Any, canchas: int, deportes: tuple[str, ...] = ()) -> Sede:
    return Sede(
        id=int(fila.id),
        nombre=fila.nombre,
        calle=fila.calle,
        altura=int(fila.altura),
        apertura=fila.apertura,
        cierre=fila.cierre,
        dias=tuple(int(d) for d in fila.dias),
        canchas=canchas,
        deportes=deportes,
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

    def insertar(self, nueva: SedeNueva, autor: int) -> Sede:
        try:
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
            self._conn.commit()
        except IntegrityError as e:
            self._conn.rollback()
            indice = getattr(getattr(e.orig, "diag", None), "constraint_name", None)
            if indice == "sede_nombre_activa_unico":
                raise Duplicado(["nombre"]) from e
            raise
        except BaseException:
            self._conn.rollback()
            raise
        return _sede(fila, canchas=0)
