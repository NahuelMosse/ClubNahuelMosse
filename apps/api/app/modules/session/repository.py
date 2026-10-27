# kit-shape: the profile repository and the function that hands it to the routes go together
from typing import Annotated

from fastapi import Depends
from sqlalchemy import Connection, text

from app.modules.session.profile import Profile
from app.shared.db import DbConnection


class ProfilesSql:
    """Reads the profile from the `usuario` table; does not write it."""

    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def active_profile(self, uid: str) -> Profile | None:
        row = self._conn.execute(
            text(
                "SELECT id, firebase_uid, nombre, apellido, correo, rol, dni, fecha_nacimiento"
                " FROM usuario"
                " WHERE firebase_uid = :uid AND activo"
            ),
            {"uid": uid},
        ).first()
        self._conn.rollback()
        if row is None:
            return None
        return Profile(
            id=row.id,
            uid=row.firebase_uid,
            first_name=row.nombre,
            last_name=row.apellido,
            email=row.correo,
            role=row.rol,
            dni=row.dni,
            birth_date=row.fecha_nacimiento,
        )


def profile_repository(conn: DbConnection) -> ProfilesSql:
    return ProfilesSql(conn)


Profiles = Annotated[ProfilesSql, Depends(profile_repository)]
