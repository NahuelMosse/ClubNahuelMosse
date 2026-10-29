# kit-shape: the user repository and its dependency provider are read together
from uuid import UUID

from sqlalchemy import Connection, text
from sqlalchemy.exc import IntegrityError

from app.modules.bookings import BookingsSql
from app.modules.users.rules import EditedProfile, Registration
from app.shared.db import DbConnection, in_transaction, violated_constraint
from app.shared.errors import Duplicate
from app.shared.stored_values import stored

_INDEX_TO_FIELD = {"app_user_email_unique": "correo", "app_user_dni_unique": "dni"}


class UsersSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def duplicates(self, email: str, dni: str) -> list[str]:
        row = self._conn.execute(
            text(
                "SELECT bool_or(lower(email) = :email) AS email, bool_or(dni = :dni) AS dni"
                " FROM app_user WHERE active AND (lower(email) = :email OR dni = :dni)"
            ),
            {"email": email, "dni": dni},
        ).one()
        self._conn.rollback()
        fields = (("correo", row.email), ("dni", row.dni))
        return [field for field, repeated in fields if repeated]

    def uid_is_active(self, uid: str) -> bool:
        active = self._conn.execute(
            text("SELECT 1 FROM app_user WHERE firebase_uid = :uid AND active"), {"uid": uid}
        ).first()
        self._conn.rollback()
        return active is not None

    def active_id_by_email(self, email: str) -> UUID | None:
        user_id = self._conn.execute(
            text("SELECT id FROM app_user WHERE lower(email) = :email AND active"),
            {"email": email},
        ).scalar()
        self._conn.rollback()
        return None if user_id is None else user_id

    def make_admin(self, user_id: UUID) -> None:
        self._conn.execute(
            text("UPDATE app_user SET role = :admin WHERE id = :id AND role <> :admin"),
            {"id": user_id, "admin": stored("admin")},
        )
        self._conn.commit()

    def update(self, user_id: UUID, edited: EditedProfile) -> None:
        try:
            with in_transaction(self._conn):
                self._conn.execute(
                    text(
                        "UPDATE app_user SET first_name = :first_name, last_name = :last_name,"
                        " dni = :dni, birth_date = :birth_date WHERE id = :id AND active"
                    ),
                    {
                        "id": user_id,
                        "first_name": edited.first_name,
                        "last_name": edited.last_name,
                        "dni": edited.dni,
                        "birth_date": edited.birth_date,
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
                    "UPDATE app_user SET active = false, deactivated_at = clock_timestamp()"
                    " WHERE id = :id AND active RETURNING id"
                ),
                {"id": user_id},
            ).first()
            if deactivated is None:
                self._conn.rollback()
                return False
            BookingsSql(self._conn).cancel_future_of(user_id)
        return True

    def mark_password_changed(self, user_id: UUID) -> None:
        self._conn.execute(
            text("UPDATE app_user SET password_changed_at = clock_timestamp() WHERE id = :id"),
            {"id": user_id},
        )
        self._conn.commit()

    def insert(self, uid: str, registration: Registration) -> UUID:
        """Inserts the profile and commits it: if the commit fails, the use case compensates."""
        try:
            with in_transaction(self._conn):
                new: UUID = self._conn.execute(
                    text(
                        "INSERT INTO app_user"
                        " (firebase_uid, email, first_name, last_name, dni, birth_date)"
                        " VALUES (:uid, :email, :first_name, :last_name, :dni, :birth_date)"
                        " RETURNING id"
                    ),
                    {
                        "uid": uid,
                        "email": registration.email,
                        "first_name": registration.first_name,
                        "last_name": registration.last_name,
                        "dni": registration.dni,
                        "birth_date": registration.birth_date,
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
