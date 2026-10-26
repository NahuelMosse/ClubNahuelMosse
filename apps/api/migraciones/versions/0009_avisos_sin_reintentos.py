"""Los avisos no se reintentan: se borran `intentos` y `tomada_en`.

Un aviso que estaba `enviando` al migrar pasa a `fallida`: sin recuperación, nada más lo tomaría.

Revision ID: 0009
Revises: 0008
"""

from alembic import op

revision = "0009"
down_revision = "0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("UPDATE notificacion SET envio = 'fallida' WHERE envio = 'enviando'")
    op.execute("ALTER TABLE notificacion DROP COLUMN IF EXISTS intentos, DROP COLUMN IF EXISTS tomada_en")


def downgrade() -> None:
    op.execute(
        "ALTER TABLE notificacion"
        " ADD COLUMN IF NOT EXISTS tomada_en timestamptz,"
        " ADD COLUMN IF NOT EXISTS intentos integer NOT NULL DEFAULT 0"
    )
