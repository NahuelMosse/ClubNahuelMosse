"""Los avisos no se reintentan: se borran `intentos` y `tomada_en` y se agrega `enviando_desde`.

Un aviso que estaba `enviando` al migrar pasa a `fallida`: sin recuperación, nada más lo tomaría.
`enviando_desde` dice cuándo se tomó un aviso; el que lleva demasiado en `enviando` (la API se cayó
a mitad del envío) pasa a `fallida`.

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
    op.execute(
        "ALTER TABLE notificacion DROP COLUMN IF EXISTS intentos, DROP COLUMN IF EXISTS tomada_en"
    )
    op.execute("ALTER TABLE notificacion ADD COLUMN IF NOT EXISTS enviando_desde timestamptz")


def downgrade() -> None:
    op.execute("ALTER TABLE notificacion DROP COLUMN IF EXISTS enviando_desde")
    op.execute(
        "ALTER TABLE notificacion"
        " ADD COLUMN IF NOT EXISTS tomada_en timestamptz,"
        " ADD COLUMN IF NOT EXISTS intentos integer NOT NULL DEFAULT 0"
    )
