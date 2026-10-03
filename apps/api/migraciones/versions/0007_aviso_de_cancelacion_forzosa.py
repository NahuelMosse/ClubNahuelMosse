"""Aviso de cancelación forzosa: qué reservas cubre cada aviso.

Revision ID: 0007
Revises: 0006
"""

from alembic import op

revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Un aviso agrupado cubre varias reservas, así que el vínculo no vive en `notificacion`.
    # Una reserva tiene a lo sumo un aviso: repetir la anulación no lo repite, y el estado del
    # envío de ese aviso es el que consta en la trazabilidad de la reserva.
    op.execute(
        """
        CREATE TABLE notificacion_reserva (
            notificacion_id bigint NOT NULL REFERENCES notificacion (id),
            reserva_id bigint NOT NULL UNIQUE REFERENCES reserva (id),
            PRIMARY KEY (notificacion_id, reserva_id)
        )
        """
    )
    # Buscar el aviso de anulación sin leer de una persona, para agrupar el siguiente.
    op.execute(
        "CREATE INDEX notificacion_forzosa_sin_leer ON notificacion (usuario_id, id DESC)"
        " WHERE tipo = 'cancelacion_forzosa' AND leida_en IS NULL"
    )


def downgrade() -> None:
    op.execute("DROP INDEX notificacion_forzosa_sin_leer")
    op.execute("DROP TABLE notificacion_reserva")
