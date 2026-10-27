# kit-shape: the link repository and the function that hands it to the routes go together
from uuid import UUID

from sqlalchemy import Connection, text

from app.modules.password_recovery.rules import ClaimedLink, Recipient
from app.shared.db import DbConnection, in_transaction

# A link is valid if it was not used or replaced, has not expired, the account is still active
# and the password did not change after it was issued.
_VALID = """
    e.usado_en IS NULL
    AND e.invalidado_en IS NULL
    AND e.vence_en > clock_timestamp()
    AND u.activo
    AND (u.contrasena_cambiada_en IS NULL OR u.contrasena_cambiada_en < e.creado_en)
"""


class LinksSql:
    def __init__(self, conn: Connection) -> None:
        self._conn = conn

    def recipient(self, email: str) -> Recipient | None:
        row = self._conn.execute(
            text("SELECT id, nombre, correo FROM usuario WHERE lower(correo) = :c AND activo"),
            {"c": email},
        ).first()
        self._conn.rollback()
        return None if row is None else Recipient(row.id, row.nombre, row.correo)

    def issue(
        self, user_id: UUID, code_hash: str, validity_minutes: int, max_per_hour: int
    ) -> bool:
        with in_transaction(self._conn):
            # The lock orders simultaneous requests of the same account: the second one counts
            # and invalidates only once the first one is done.
            self._conn.execute(
                text("SELECT pg_advisory_xact_lock(hashtextextended(CAST(:u AS text), 0))"),
                {"u": user_id},
            )
            issued: int = self._conn.execute(
                text(
                    "SELECT count(*) FROM enlace_recuperacion WHERE usuario_id = :u"
                    " AND creado_en > clock_timestamp() - interval '1 hour'"
                ),
                {"u": user_id},
            ).scalar_one()
            if issued >= max_per_hour:
                self._conn.rollback()
                return False
            # Also the one in use: if the change fails and it is released, it is no longer valid.
            self._conn.execute(
                text(
                    "UPDATE enlace_recuperacion SET invalidado_en = clock_timestamp()"
                    " WHERE usuario_id = :u AND invalidado_en IS NULL"
                ),
                {"u": user_id},
            )
            # The expiry comes from the database clock, the same one it is compared with.
            self._conn.execute(
                text(
                    "INSERT INTO enlace_recuperacion (usuario_id, codigo_hash, vence_en)"
                    " VALUES (:u, :h, clock_timestamp() + make_interval(mins => :m))"
                ),
                {"u": user_id, "h": code_hash, "m": validity_minutes},
            )
        return True

    def valid(self, code_hash: str) -> bool:
        row = self._conn.execute(
            text(
                "SELECT 1 FROM enlace_recuperacion e JOIN usuario u ON u.id = e.usuario_id"
                f" WHERE e.codigo_hash = :h AND {_VALID}"
            ),
            {"h": code_hash},
        ).first()
        self._conn.rollback()
        return row is not None

    def claim(self, code_hash: str) -> ClaimedLink | None:
        with in_transaction(self._conn):
            row = self._conn.execute(
                text(
                    "UPDATE enlace_recuperacion e SET usado_en = clock_timestamp()"
                    " FROM usuario u WHERE u.id = e.usuario_id AND e.codigo_hash = :h"
                    f" AND {_VALID}"
                    " RETURNING e.id, u.id AS usuario_id, u.firebase_uid"
                ),
                {"h": code_hash},
            ).first()
        if row is None:
            return None
        return ClaimedLink(row.id, row.usuario_id, row.firebase_uid)

    def release(self, link_id: UUID) -> None:
        self._conn.execute(
            text("UPDATE enlace_recuperacion SET usado_en = NULL WHERE id = :id"), {"id": link_id}
        )
        self._conn.commit()


def link_repository(conn: DbConnection) -> LinksSql:
    return LinksSql(conn)
