"""`enviando_desde`: cuándo se tomó un aviso para enviarlo.

Un aviso que lleva demasiado en `enviando` (la API se cayó a mitad del envío) pasa a `fallida`.

Revision ID: 0010
Revises: 0009
"""

from alembic import op

revision = "0010"
down_revision = "0009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TABLE notificacion ADD COLUMN IF NOT EXISTS enviando_desde timestamptz")


def downgrade() -> None:
    op.execute("ALTER TABLE notificacion DROP COLUMN IF EXISTS enviando_desde")
