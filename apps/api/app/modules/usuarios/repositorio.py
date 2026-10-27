# kit-shape: el repositorio de usuarios y su proveedor de dependencia se leen juntos
from uuid import UUID

from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.modules.reservas import ReservasSql
from app.modules.usuarios.reglas import PerfilEditado, Registro
from app.shared.db import Conexion, en_transaccion, restriccion_violada
from app.shared.errores import Duplicado

_INDICE_A_CAMPO = {"usuario_correo_unico": "correo", "usuario_dni_unico": "dni"}


class UsuariosSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def duplicados(self, correo: str, dni: str) -> list[str]:
        fila = self._conn.execute(
            text(
                "SELECT bool_or(lower(correo) = :correo) AS correo, bool_or(dni = :dni) AS dni"
                " FROM usuario WHERE activo AND (lower(correo) = :correo OR dni = :dni)"
            ),
            {"correo": correo, "dni": dni},
        ).one()
        self._conn.rollback()
        return [campo for campo in ("correo", "dni") if getattr(fila, campo)]

    def uid_activo(self, uid: str) -> bool:
        activo = self._conn.execute(
            text("SELECT 1 FROM usuario WHERE firebase_uid = :uid AND activo"), {"uid": uid}
        ).first()
        self._conn.rollback()
        return activo is not None

    def id_activo_por_correo(self, correo: str) -> UUID | None:
        id_usuario = self._conn.execute(
            text("SELECT id FROM usuario WHERE lower(correo) = :correo AND activo"),
            {"correo": correo},
        ).scalar()
        self._conn.rollback()
        return None if id_usuario is None else id_usuario

    def hacer_admin(self, id_usuario: UUID) -> None:
        self._conn.execute(
            text("UPDATE usuario SET rol = 'admin' WHERE id = :id AND rol <> 'admin'"),
            {"id": id_usuario},
        )
        self._conn.commit()

    def actualizar(self, id_usuario: UUID, editado: PerfilEditado) -> None:
        try:
            with en_transaccion(self._conn):
                self._conn.execute(
                    text(
                        "UPDATE usuario SET nombre = :nombre, apellido = :apellido, dni = :dni,"
                        " fecha_nacimiento = :nacimiento WHERE id = :id AND activo"
                    ),
                    {
                        "id": id_usuario,
                        "nombre": editado.nombre,
                        "apellido": editado.apellido,
                        "dni": editado.dni,
                        "nacimiento": editado.fecha_nacimiento,
                    },
                )
        except IntegrityError as e:
            indice = restriccion_violada(e)
            if indice in _INDICE_A_CAMPO:
                raise Duplicado([_INDICE_A_CAMPO[indice]]) from e
            raise

    def dar_de_baja(self, id_usuario: UUID) -> bool:
        with en_transaccion(self._conn):
            # Primero la cuenta: su bloqueo ordena lo que venga después, y una cuenta que ya
            # estaba de baja no se vuelve a procesar.
            dada = self._conn.execute(
                text(
                    "UPDATE usuario SET activo = false, dado_de_baja_en = clock_timestamp()"
                    " WHERE id = :id AND activo RETURNING id"
                ),
                {"id": id_usuario},
            ).first()
            if dada is None:
                self._conn.rollback()
                return False
            ReservasSql(self._conn).cancelar_futuras_de(id_usuario)
        return True

    def marcar_cambio_de_contrasena(self, id_usuario: UUID) -> None:
        self._conn.execute(
            text("UPDATE usuario SET contrasena_cambiada_en = clock_timestamp() WHERE id = :id"),
            {"id": id_usuario},
        )
        self._conn.commit()

    def insertar(self, uid: str, registro: Registro) -> UUID:
        """Inserta el perfil y lo confirma: si el commit falla, el caso de uso compensa."""
        try:
            with en_transaccion(self._conn):
                nuevo: UUID = self._conn.execute(
                    text(
                        "INSERT INTO usuario"
                        " (firebase_uid, correo, nombre, apellido, dni, fecha_nacimiento)"
                        " VALUES (:uid, :correo, :nombre, :apellido, :dni, :nacimiento)"
                        " RETURNING id"
                    ),
                    {
                        "uid": uid,
                        "correo": registro.correo,
                        "nombre": registro.nombre,
                        "apellido": registro.apellido,
                        "dni": registro.dni,
                        "nacimiento": registro.fecha_nacimiento,
                    },
                ).scalar_one()
        except IntegrityError as e:
            indice = restriccion_violada(e)
            if indice in _INDICE_A_CAMPO:
                raise Duplicado([_INDICE_A_CAMPO[indice]]) from e
            raise
        return nuevo


# Un repositorio por pedido: arma sobre la conexión que FastAPI resuelve una vez.
def repositorio_usuarios(conn: Conexion) -> UsuariosSql:
    return UsuariosSql(conn)
