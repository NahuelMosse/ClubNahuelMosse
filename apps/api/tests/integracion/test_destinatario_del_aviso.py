"""El destinatario del correo de un aviso, leído de la base real."""

from collections.abc import Callable
from uuid import UUID

from sqlalchemy import Engine, text

from app.modules.notificaciones.reglas import Destinatario
from app.modules.notificaciones.repositorio import NotificacionesSql


def _crear_usuario(motor: Engine, sufijo: str) -> UUID:
    with motor.begin() as conn:
        return UUID(
            str(
                conn.execute(
                    text(
                        "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni,"
                        " fecha_nacimiento) VALUES (:uid, :correo, 'Ana', 'Rios', :dni,"
                        " '1990-01-01') RETURNING id"
                    ),
                    {
                        "uid": f"uid-{sufijo}",
                        "correo": f"ana-{sufijo}@correo.com",
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
        assert NotificacionesSql(conn).destinatario(usuario) == Destinatario(
            correo=f"ana-{sufijo}@correo.com", nombre="Ana"
        )
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE usuario SET activo = false, dado_de_baja_en = now() WHERE id = :u"),
            {"u": usuario},
        )
    with motor.connect() as conn:
        assert NotificacionesSql(conn).destinatario(usuario) is None
