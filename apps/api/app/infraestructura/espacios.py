from collections.abc import Callable
from typing import Any

from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.aplicacion.errores import Duplicado, NoDisponible, NoEncontrada, NumeroOcupado
from app.dominio.espacios import (
    CambioDeEspacio,
    Espacio,
    EspacioNuevo,
    NombreSugerido,
    SedeDelEspacio,
)

COLUMNAS_DE_ESPACIO = (
    "e.id, e.nombre, e.sede_id, s.nombre AS sede, e.deporte, e.tipo, e.numero, e.techada,"
    " e.iluminada, e.precio_por_hora"
)
# Primer argumento de los candados de esta tabla: separa su espacio de claves del de otros
# candados de la base.
_CANDADO_NUMERACION = 21
# Cuánto después de su alta un espacio se reconoce como el mismo pedido repetido.
_VENTANA_DE_REINTENTO = "5 minutes"


def espacio_de_fila(fila: Any) -> Espacio:
    return Espacio(
        id=int(fila.id),
        nombre=fila.nombre,
        sede_id=int(fila.sede_id),
        sede=fila.sede,
        deporte=fila.deporte,
        tipo=fila.tipo,
        numero=int(fila.numero),
        techada=bool(fila.techada),
        iluminada=bool(fila.iluminada),
        precio_por_hora=int(fila.precio_por_hora),
    )


class EspaciosSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def activos(
        self,
        sede_id: int | None = None,
        deporte: str | None = None,
        tipo: str | None = None,
    ) -> list[Espacio]:
        filas = self._conn.execute(
            text(
                f"SELECT {COLUMNAS_DE_ESPACIO} FROM espacio e JOIN sede s ON s.id = e.sede_id"
                " WHERE e.activo AND s.activa"
                " AND (CAST(:sede AS bigint) IS NULL OR e.sede_id = :sede)"
                " AND (CAST(:deporte AS text) IS NULL OR e.deporte = :deporte)"
                " AND (CAST(:tipo AS text) IS NULL OR e.tipo = :tipo)"
                " ORDER BY lower(s.nombre), s.id, e.deporte, e.tipo, e.numero"
            ),
            {"sede": sede_id, "deporte": deporte, "tipo": tipo},
        ).all()
        self._conn.rollback()
        return [espacio_de_fila(f) for f in filas]

    def _sede(self, sede_id: int, bloquear: bool) -> SedeDelEspacio | None:
        fila = self._conn.execute(
            text(
                "SELECT nombre, calle, altura FROM sede WHERE id = :id AND activa"
                + (" FOR SHARE" if bloquear else "")
            ),
            {"id": sede_id},
        ).first()
        return None if fila is None else SedeDelEspacio(fila.nombre, fila.calle, int(fila.altura))

    def _calcular(
        self,
        sede_id: int,
        sede: SedeDelEspacio,
        deporte: str,
        tipo: str,
        nombre: Callable[[SedeDelEspacio, int], str],
    ) -> NombreSugerido:
        numero = int(
            self._conn.execute(
                text(
                    "SELECT coalesce(max(numero), 0) + 1 FROM espacio"
                    " WHERE sede_id = :sede AND deporte = :deporte AND tipo = :tipo"
                ),
                {"sede": sede_id, "deporte": deporte, "tipo": tipo},
            ).scalar_one()
        )
        # Otra sede puede armar el mismo nombre compuesto (una dada de baja y vuelta a crear
        # igual, o «Haedo» y «Sede Haedo» en la misma calle): ese número se saltea.
        while self._conn.execute(
            text("SELECT 1 FROM espacio WHERE nombre = :n"), {"n": nombre(sede, numero)}
        ).first():
            numero += 1
        return NombreSugerido(nombre(sede, numero), numero)

    def siguiente(
        self,
        sede_id: int,
        deporte: str,
        tipo: str,
        nombre: Callable[[SedeDelEspacio, int], str],
    ) -> NombreSugerido | None:
        try:
            sede = self._sede(sede_id, bloquear=False)
            return None if sede is None else self._calcular(sede_id, sede, deporte, tipo, nombre)
        finally:
            self._conn.rollback()

    def _repetido(self, nuevo: EspacioNuevo, numero: int, autor: int) -> Espacio | None:
        fila = self._conn.execute(
            text(
                f"SELECT {COLUMNAS_DE_ESPACIO} FROM espacio e JOIN sede s ON s.id = e.sede_id"
                " WHERE e.sede_id = :sede AND e.deporte = :deporte AND e.tipo = :tipo"
                " AND e.numero = :numero AND e.activo AND e.creado_por = :autor"
                " AND e.techada = :techada AND e.iluminada = :iluminada"
                " AND e.precio_por_hora = :precio"
                f" AND e.creado_en > now() - interval '{_VENTANA_DE_REINTENTO}'"
            ),
            {
                "sede": nuevo.sede_id,
                "deporte": nuevo.deporte,
                "tipo": nuevo.tipo,
                "numero": numero,
                "autor": autor,
                "techada": nuevo.techada,
                "iluminada": nuevo.iluminada,
                "precio": nuevo.precio_por_hora,
            },
        ).first()
        return None if fila is None else espacio_de_fila(fila)

    def insertar(
        self,
        nuevo: EspacioNuevo,
        numero: int | None,
        nombre: Callable[[SedeDelEspacio, int], str],
        autor: int,
    ) -> Espacio:
        try:
            # La sede se toma compartida para que no se dé de baja en el medio, y la
            # numeración de ese tipo en esa sede, exclusiva: dos altas a la vez no calculan
            # el mismo número.
            sede = self._sede(nuevo.sede_id, bloquear=True)
            if sede is None:
                raise NoDisponible("la sede no está activa")
            self._conn.execute(
                text("SELECT pg_advisory_xact_lock(:espacio, hashtext(:c))"),
                {
                    "espacio": _CANDADO_NUMERACION,
                    "c": f"{nuevo.sede_id}:{nuevo.deporte}:{nuevo.tipo}",
                },
            )
            siguiente = self._calcular(nuevo.sede_id, sede, nuevo.deporte, nuevo.tipo, nombre)
            if numero is not None and numero != siguiente.numero:
                repetido = self._repetido(nuevo, numero, autor)
                self._conn.rollback()
                if repetido is not None:
                    return repetido
                raise NumeroOcupado(siguiente.numero, siguiente.nombre)
            fila = self._conn.execute(
                text(
                    "WITH nuevo AS ("
                    " INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                    " iluminada, precio_por_hora, creado_por, modificado_por)"
                    " VALUES (:sede, :deporte, :tipo, :numero, :nombre, :techada, :iluminada,"
                    " :precio, :autor, :autor) RETURNING *)"
                    f" SELECT {COLUMNAS_DE_ESPACIO} FROM nuevo e JOIN sede s ON s.id = e.sede_id"
                ),
                {
                    "sede": nuevo.sede_id,
                    "deporte": nuevo.deporte,
                    "tipo": nuevo.tipo,
                    "numero": siguiente.numero,
                    "nombre": siguiente.nombre,
                    "techada": nuevo.techada,
                    "iluminada": nuevo.iluminada,
                    "precio": nuevo.precio_por_hora,
                    "autor": autor,
                },
            ).one()
            self._conn.commit()
        except IntegrityError as e:
            self._conn.rollback()
            indice = getattr(getattr(e.orig, "diag", None), "constraint_name", None)
            # Un alta de otra sede tomó el mismo nombre entre el cálculo y el INSERT.
            if indice == "espacio_nombre_key":
                raise Duplicado(["nombre"]) from e
            raise
        except BaseException:
            self._conn.rollback()
            raise
        return espacio_de_fila(fila)

    def actualizar(self, espacio_id: int, cambio: CambioDeEspacio, autor: int) -> Espacio:
        datos = {
            "id": espacio_id,
            "techada": cambio.techada,
            "iluminada": cambio.iluminada,
            "precio": cambio.precio_por_hora,
            "autor": autor,
        }
        try:
            # La sede compartida y después la fila del espacio, el orden de una reserva: la
            # que se está guardando toma el precio de antes o el de ahora, entero.
            sede = self._conn.execute(
                text(
                    "SELECT s.id FROM sede s JOIN espacio e ON e.sede_id = s.id"
                    " WHERE e.id = :id AND e.activo AND s.activa FOR SHARE OF s"
                ),
                datos,
            ).first()
            if sede is None:
                raise NoEncontrada("el espacio ya no está activo")
            # El espacio pudo darse de baja entre el chequeo y acá: si no se tocó ninguna
            # fila, no se guardó nada.
            if (
                self._conn.execute(
                    text(
                        "UPDATE espacio SET"
                        " techada = coalesce(CAST(:techada AS boolean), techada),"
                        " iluminada = coalesce(CAST(:iluminada AS boolean), iluminada),"
                        " precio_por_hora = coalesce(CAST(:precio AS integer), precio_por_hora),"
                        " modificado_por = :autor, modificado_en = now()"
                        " WHERE id = :id AND activo RETURNING id"
                    ),
                    datos,
                ).first()
                is None
            ):
                raise NoEncontrada("el espacio se dio de baja mientras tanto")
            fila = self._conn.execute(
                text(
                    f"SELECT {COLUMNAS_DE_ESPACIO} FROM espacio e JOIN sede s ON s.id = e.sede_id"
                    " WHERE e.id = :id"
                ),
                datos,
            ).one()
            self._conn.commit()
        except BaseException:
            self._conn.rollback()
            raise
        return espacio_de_fila(fila)
