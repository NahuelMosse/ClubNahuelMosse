# kit-shape: the link repository and the function that hands it to the routes go together
from uuid import UUID

from sqlalchemy import Connection, text

from app.modules.password_recovery.rules import ClaimedLink, Recipient
from app.shared.db import DbConnection, in_transaction

# A link is valid if it was not used or replaced, has not expired, the account is still active
# and the password did not change after it was issued.
_VALID = """
    l.used_at IS NULL
    AND l.invalidated_at IS NULL
    AND l.expires_at > clock_timestamp()
    AND u.active
    AND (u.password_changed_at IS NULL OR u.password_changed_at < l.created_at)
"""


class LinksSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def recipient(self, email: str) -> Recipient | None:
        row = self._conn.execute(
            text(
                "SELECT id, first_name, email FROM app_user"
                " WHERE lower(email) = :email AND active"
            ),
            {"email": email},
        ).first()
        self._conn.rollback()
        return None if row is None else Recipient(row.id, row.first_name, row.email)

    def issue(
        self, user_id: UUID, code_hash: str, validity_minutes: int, max_per_hour: int
    ) -> bool:
        with in_transaction(self._conn):
            # The lock orders simultaneous requests of the same account: the second one counts
            # and invalidates only once the first one is done.
            self._conn.execute(
                text("SELECT pg_advisory_xact_lock(hashtextextended(CAST(:user_id AS text), 0))"),
                {"user_id": user_id},
            )
            issued: int = self._conn.execute(
                text(
                    "SELECT count(*) FROM recovery_link WHERE user_id = :user_id"
                    " AND created_at > clock_timestamp() - interval '1 hour'"
                ),
                {"user_id": user_id},
            ).scalar_one()
            if issued >= max_per_hour:
                self._conn.rollback()
                return False
            # Also the one in use: if the change fails and it is released, it is no longer valid.
            self._conn.execute(
                text(
                    "UPDATE recovery_link SET invalidated_at = clock_timestamp()"
                    " WHERE user_id = :user_id AND invalidated_at IS NULL"
                ),
                {"user_id": user_id},
            )
            # The expiry comes from the database clock, the same one it is compared with.
            self._conn.execute(
                text(
                    "INSERT INTO recovery_link (user_id, code_hash, expires_at)"
                    " VALUES (:user_id, :code_hash,"
                    " clock_timestamp() + make_interval(mins => :minutes))"
                ),
                {"user_id": user_id, "code_hash": code_hash, "minutes": validity_minutes},
            )
        return True

    def valid(self, code_hash: str) -> bool:
        row = self._conn.execute(
            text(
                "SELECT 1 FROM recovery_link l JOIN app_user u ON u.id = l.user_id"
                f" WHERE l.code_hash = :code_hash AND {_VALID}"
            ),
            {"code_hash": code_hash},
        ).first()
        self._conn.rollback()
        return row is not None

    def claim(self, code_hash: str) -> ClaimedLink | None:
        with in_transaction(self._conn):
            row = self._conn.execute(
                text(
                    "UPDATE recovery_link l SET used_at = clock_timestamp()"
                    " FROM app_user u WHERE u.id = l.user_id AND l.code_hash = :code_hash"
                    f" AND {_VALID}"
                    " RETURNING l.id, u.id AS user_id, u.firebase_uid"
                ),
                {"code_hash": code_hash},
            ).first()
        if row is None:
            return None
        return ClaimedLink(row.id, row.user_id, row.firebase_uid)

    def release(self, link_id: UUID) -> None:
        self._conn.execute(
            text("UPDATE recovery_link SET used_at = NULL WHERE id = :id"), {"id": link_id}
        )
        self._conn.commit()


def link_repository(conn: DbConnection) -> LinksSql:
    return LinksSql(conn)
