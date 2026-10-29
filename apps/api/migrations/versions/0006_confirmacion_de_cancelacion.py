"""Confirmación de cancelación: un aviso por reserva cancelada y el envío en curso.

Revision ID: 0006
Revises: 0005
"""

from alembic import op

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # «enviando»: un despacho ya tomó el aviso, y otro no lo manda de nuevo.
    op.execute("ALTER TABLE notificacion DROP CONSTRAINT notificacion_envio_check")
    op.execute(
        "ALTER TABLE notificacion ADD CONSTRAINT notificacion_envio_check CHECK (envio IN"
        " ('pendiente', 'enviando', 'enviada', 'sin_permiso', 'sin_canal', 'fallida'))"
    )
    # Una reserva se cancela una sola vez: repetir el pedido no repite el aviso.
    op.execute(
        "CREATE UNIQUE INDEX notificacion_cancelacion_unica"
        " ON notificacion (reserva_id) WHERE tipo = 'cancelacion_usuario'"
    )
    op.execute(
        "ALTER TABLE notificacion ADD CONSTRAINT notificacion_cancelacion_con_reserva"
        " CHECK (tipo <> 'cancelacion_usuario' OR reserva_id IS NOT NULL)"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE notificacion DROP CONSTRAINT notificacion_cancelacion_con_reserva")
    op.execute("DROP INDEX notificacion_cancelacion_unica")
    op.execute("UPDATE notificacion SET envio = 'fallida' WHERE envio = 'enviando'")
    op.execute("ALTER TABLE notificacion DROP CONSTRAINT notificacion_envio_check")
    op.execute(
        "ALTER TABLE notificacion ADD CONSTRAINT notificacion_envio_check CHECK (envio IN"
        " ('pendiente', 'enviada', 'sin_permiso', 'sin_canal', 'fallida'))"
    )
