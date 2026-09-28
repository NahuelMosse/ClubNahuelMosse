from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.aplicacion.errores import Duplicado
from app.dominio.usuarios import Perfil, PerfilEditado, Registro

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

    def perfil_activo(self, uid: str) -> Perfil | None:
        fila = self._conn.execute(
            text(
                "SELECT id, firebase_uid, nombre, apellido, correo, rol, dni, fecha_nacimiento"
                " FROM usuario"
                " WHERE firebase_uid = :uid AND activo"
            ),
            {"uid": uid},
        ).first()
        self._conn.rollback()
        if fila is None:
            return None
        return Perfil(
            id=fila.id,
            uid=fila.firebase_uid,
            nombre=fila.nombre,
            apellido=fila.apellido,
            correo=fila.correo,
            rol=fila.rol,
            dni=fila.dni,
            fecha_nacimiento=fila.fecha_nacimiento,
        )

    def id_activo_por_correo(self, correo: str) -> int | None:
        id_usuario = self._conn.execute(
            text("SELECT id FROM usuario WHERE lower(correo) = :correo AND activo"),
            {"correo": correo},
        ).scalar()
        self._conn.rollback()
        return None if id_usuario is None else int(id_usuario)

    def hacer_admin(self, id_usuario: int) -> None:
        self._conn.execute(
            text("UPDATE usuario SET rol = 'admin' WHERE id = :id AND rol <> 'admin'"),
            {"id": id_usuario},
        )
        self._conn.commit()

    def actualizar(self, id_usuario: int, editado: PerfilEditado) -> None:
        try:
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
            self._conn.commit()
        except IntegrityError as e:
            self._conn.rollback()
            indice = getattr(getattr(e.orig, "diag", None), "constraint_name", None)
            if indice in _INDICE_A_CAMPO:
                raise Duplicado([_INDICE_A_CAMPO[indice]]) from e
            raise
        except BaseException:
            self._conn.rollback()
            raise

    def dar_de_baja(self, id_usuario: int) -> bool:
        try:
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
            self._conn.execute(
                text(
                    "UPDATE reserva SET estado = 'cancelada', cancelada_en = clock_timestamp(),"
                    " cancelada_por = :id WHERE usuario_id = :id AND estado = 'activa'"
                    " AND inicio > clock_timestamp()"
                ),
                {"id": id_usuario},
            )
            self._conn.commit()
        except BaseException:
            self._conn.rollback()
            raise
        return True

    def marcar_cambio_de_contrasena(self, id_usuario: int) -> None:
        self._conn.execute(
            text("UPDATE usuario SET contrasena_cambiada_en = clock_timestamp() WHERE id = :id"),
            {"id": id_usuario},
        )
        self._conn.commit()

    def insertar(self, uid: str, registro: Registro) -> int:
        """Inserta el perfil y lo confirma: si el commit falla, el caso de uso compensa."""
        try:
            nuevo = int(
                self._conn.execute(
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
            )
            self._conn.commit()
        except IntegrityError as e:
            self._conn.rollback()
            indice = getattr(getattr(e.orig, "diag", None), "constraint_name", None)
            if indice in _INDICE_A_CAMPO:
                raise Duplicado([_INDICE_A_CAMPO[indice]]) from e
            raise
        except BaseException:
            self._conn.rollback()
            raise
        return nuevo
