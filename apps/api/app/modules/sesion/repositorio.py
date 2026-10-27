# kit-shape: el repositorio de perfiles y la función que lo entrega a las rutas van juntos
from typing import Annotated

from fastapi import Depends
from sqlalchemy import Connection, text

from app.modules.sesion.perfil import Perfil
from app.shared.db import Conexion


class PerfilesSql:
    """Lee el perfil de la tabla `usuario`; no la escribe."""

    def __init__(self, conn: Connection) -> None:
        self._conn = conn

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


def repositorio_perfiles(conn: Conexion) -> PerfilesSql:
    return PerfilesSql(conn)


Perfiles = Annotated[PerfilesSql, Depends(repositorio_perfiles)]
