from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.aplicacion.errores import Duplicado
from app.dominio.usuarios import Registro

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
        return [campo for campo in ("correo", "dni") if getattr(fila, campo)]

    def insertar(self, uid: str, registro: Registro) -> int:
        try:
            with self._conn.begin_nested():
                return int(
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
        except IntegrityError as e:
            indice = getattr(getattr(e.orig, "diag", None), "constraint_name", None)
            if indice in _INDICE_A_CAMPO:
                raise Duplicado([_INDICE_A_CAMPO[indice]]) from e
            raise
