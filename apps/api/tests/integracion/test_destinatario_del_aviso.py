"""El destinatario del correo de un aviso, leído de la base real."""

from collections.abc import Callable
from uuid import UUID

from sqlalchemy import Engine, text

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import Recipient


def _crear_usuario(motor: Engine, sufijo: str) -> UUID:
    with motor.begin() as conn:
        return UUID(
            str(
                conn.execute(
                    text(
                        "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni,"
                        " birth_date) VALUES (:uid, :email, 'Ana', 'Rios', :dni,"
                        " '1990-01-01') RETURNING id"
                    ),
                    {
                        "uid": f"uid-{sufijo}",
                        "email": f"ana-{sufijo}@correo.com",
                        "dni": sufijo[-8:].rjust(8, "0"),
                    },
                ).scalar_one()
            )
        )


def test_el_destinatario_de_un_aviso_sale_de_la_base_y_una_cuenta_de_baja_no_tiene(
    motor: Engine, unico: Callable[[], str]
) -> None:
    """el destinatario de un aviso sale de la base con su correo y nombre, y una cuenta dada
    de baja no tiene destinatario @MAIL-03-S1 @assumption:MAIL-03-ASM-04"""
    sufijo = "".join(c for c in unico() if c.isdigit()) or "1"
    usuario = _crear_usuario(motor, sufijo)
    with motor.connect() as conn:
        assert NotificationsSql(conn).recipient(usuario) == Recipient(
            email=f"ana-{sufijo}@correo.com", name="Ana"
        )
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE app_user SET active = false, deactivated_at = now() WHERE id = :u"),
            {"u": usuario},
        )
    with motor.connect() as conn:
        assert NotificationsSql(conn).recipient(usuario) is None
