# kit-shape: the user repository and its dependency provider are read together
from uuid import UUID

from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.modules.reservas import ReservasSql
from app.modules.users.rules import EditedProfile, Registration
from app.shared.db import DbConnection, in_transaction, violated_constraint
from app.shared.errors import Duplicate

_INDEX_TO_FIELD = {"usuario_correo_unico": "correo", "usuario_dni_unico": "dni"}


class UsersSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def duplicates(self, email: str, dni: str) -> list[str]:
        row = self._conn.execute(
            text(
                "SELECT bool_or(lower(correo) = :correo) AS correo, bool_or(dni = :dni) AS dni"
                " FROM usuario WHERE activo AND (lower(correo) = :correo OR dni = :dni)"
            ),
            {"correo": email, "dni": dni},
        ).one()
        self._conn.rollback()
        return [field for field in ("correo", "dni") if getattr(row, field)]

    def uid_is_active(self, uid: str) -> bool:
        active = self._conn.execute(
            text("SELECT 1 FROM usuario WHERE firebase_uid = :uid AND activo"), {"uid": uid}
        ).first()
        self._conn.rollback()
        return active is not None

    def active_id_by_email(self, email: str) -> UUID | None:
        user_id = self._conn.execute(
            text("SELECT id FROM usuario WHERE lower(correo) = :correo AND activo"),
            {"correo": email},
        ).scalar()
        self._conn.rollback()
        return None if user_id is None else user_id

    def make_admin(self, user_id: UUID) -> None:
        self._conn.execute(
            text("UPDATE usuario SET rol = 'admin' WHERE id = :id AND rol <> 'admin'"),
            {"id": user_id},
        )
        self._conn.commit()

    def update(self, user_id: UUID, edited: EditedProfile) -> None:
        try:
            with in_transaction(self._conn):
                self._conn.execute(
                    text(
                        "UPDATE usuario SET nombre = :nombre, apellido = :apellido, dni = :dni,"
                        " fecha_nacimiento = :nacimiento WHERE id = :id AND activo"
                    ),
                    {
                        "id": user_id,
                        "nombre": edited.first_name,
                        "apellido": edited.last_name,
                        "dni": edited.dni,
                        "nacimiento": edited.birth_date,
                    },
                )
        except IntegrityError as e:
            constraint = violated_constraint(e)
            if constraint in _INDEX_TO_FIELD:
                raise Duplicate([_INDEX_TO_FIELD[constraint]]) from e
            raise

    def deactivate(self, user_id: UUID) -> bool:
        with in_transaction(self._conn):
            # The account first: its lock orders whatever comes next, and an account that was
            # already deactivated is not processed again.
            deactivated = self._conn.execute(
                text(
                    "UPDATE usuario SET activo = false, dado_de_baja_en = clock_timestamp()"
                    " WHERE id = :id AND activo RETURNING id"
                ),
                {"id": user_id},
            ).first()
            if deactivated is None:
                self._conn.rollback()
                return False
            ReservasSql(self._conn).cancelar_futuras_de(user_id)
        return True

    def mark_password_changed(self, user_id: UUID) -> None:
        self._conn.execute(
            text("UPDATE usuario SET contrasena_cambiada_en = clock_timestamp() WHERE id = :id"),
            {"id": user_id},
        )
        self._conn.commit()

    def insert(self, uid: str, registration: Registration) -> UUID:
        """Inserts the profile and commits it: if the commit fails, the use case compensates."""
        try:
            with in_transaction(self._conn):
                new: UUID = self._conn.execute(
                    text(
                        "INSERT INTO usuario"
                        " (firebase_uid, correo, nombre, apellido, dni, fecha_nacimiento)"
                        " VALUES (:uid, :correo, :nombre, :apellido, :dni, :nacimiento)"
                        " RETURNING id"
                    ),
                    {
                        "uid": uid,
                        "correo": registration.email,
                        "nombre": registration.first_name,
                        "apellido": registration.last_name,
                        "dni": registration.dni,
                        "nacimiento": registration.birth_date,
                    },
                ).scalar_one()
        except IntegrityError as e:
            constraint = violated_constraint(e)
            if constraint in _INDEX_TO_FIELD:
                raise Duplicate([_INDEX_TO_FIELD[constraint]]) from e
            raise
        return new


# One repository per request: built on the connection FastAPI resolves once.
def user_repository(conn: DbConnection) -> UsersSql:
    return UsersSql(conn)
