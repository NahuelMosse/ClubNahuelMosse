"""El aviso de cinco minutos antes: un tipo más de notificación, con su regla y su índice único.

Volver atrás borra los avisos de ese tipo.

Revision ID: 0011
Revises: 0010
"""

from alembic import op

revision = "0011"
down_revision = "0010"
branch_labels = None
depends_on = None


def _tipos(tipos: str, recordatorios: str) -> None:
    op.execute("ALTER TABLE notificacion DROP CONSTRAINT notificacion_tipo_check")
    op.execute(
        f"ALTER TABLE notificacion ADD CONSTRAINT notificacion_tipo_check CHECK (tipo IN ({tipos}))"
    )
    op.execute("ALTER TABLE notificacion DROP CONSTRAINT notificacion_check")
    op.execute(
        "ALTER TABLE notificacion ADD CONSTRAINT notificacion_check"
        f" CHECK (tipo NOT IN ({recordatorios})"
        " OR (reserva_id IS NOT NULL AND reserva_inicio IS NOT NULL))"
    )


def upgrade() -> None:
    _tipos(
        "'recordatorio', 'recordatorio_cinco', 'cancelacion_forzosa', 'cancelacion_usuario'",
        "'recordatorio', 'recordatorio_cinco'",
    )
    op.execute(
        "CREATE UNIQUE INDEX notificacion_recordatorio_cinco_unico"
        " ON notificacion (reserva_id, reserva_inicio) WHERE tipo = 'recordatorio_cinco'"
    )


def downgrade() -> None:
    op.execute("DROP INDEX notificacion_recordatorio_cinco_unico")
    op.execute("DELETE FROM notificacion WHERE tipo = 'recordatorio_cinco'")
    _tipos("'recordatorio', 'cancelacion_forzosa', 'cancelacion_usuario'", "'recordatorio'")
