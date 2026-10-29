# kit-shape: the profile repository and the function that hands it to the routes go together
from typing import Annotated

from fastapi import Depends
from sqlalchemy import Connection, text

from app.modules.session.profile import Profile
from app.shared.db import DbConnection
from app.shared.stored_values import contract


class ProfilesSql:
    """Reads the profile from the `app_user` table; does not write it."""

    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def active_profile(self, uid: str) -> Profile | None:
        row = self._conn.execute(
            text(
                "SELECT id, firebase_uid, first_name, last_name, email, role, dni, birth_date"
                " FROM app_user"
                " WHERE firebase_uid = :uid AND active"
            ),
            {"uid": uid},
        ).first()
        self._conn.rollback()
        if row is None:
            return None
        return Profile(
            id=row.id,
            uid=row.firebase_uid,
            first_name=row.first_name,
            last_name=row.last_name,
            email=row.email,
            role=contract(row.role),
            dni=row.dni,
            birth_date=row.birth_date,
        )


def profile_repository(conn: DbConnection) -> ProfilesSql:
    return ProfilesSql(conn)


Profiles = Annotated[ProfilesSql, Depends(profile_repository)]
