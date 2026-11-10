"""The recipient of a notice's email, read from the real database."""

from collections.abc import Callable
from uuid import UUID

from sqlalchemy import Engine, text

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import Recipient


def _create_user(engine: Engine, suffix: str) -> UUID:
    with engine.begin() as conn:
        return UUID(
            str(
                conn.execute(
                    text(
                        "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni,"
                        " birth_date) VALUES (:uid, :email, 'Ana', 'Rios', :dni,"
                        " '1990-01-01') RETURNING id"
                    ),
                    {
                        "uid": f"uid-{suffix}",
                        "email": f"ana-{suffix}@correo.com",
                        "dni": suffix[-8:].rjust(8, "0"),
                    },
                ).scalar_one()
            )
        )


def test_the_recipient_of_a_notice_comes_from_the_database_and_a_deactivated_account_has_none(
    engine: Engine, unique: Callable[[], str]
) -> None:
    """the recipient of a notice comes from the database with their email and name, and a
    deactivated account has no recipient @MAIL-03-S1 @assumption:MAIL-03-ASM-04"""
    suffix = "".join(c for c in unique() if c.isdigit()) or "1"
    user = _create_user(engine, suffix)
    with engine.connect() as conn:
        assert NotificationsSql(conn).recipient(user) == Recipient(
            email=f"ana-{suffix}@correo.com", name="Ana"
        )
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE app_user SET active = false, deactivated_at = now() WHERE id = :u"),
            {"u": user},
        )
    with engine.connect() as conn:
        assert NotificationsSql(conn).recipient(user) is None
