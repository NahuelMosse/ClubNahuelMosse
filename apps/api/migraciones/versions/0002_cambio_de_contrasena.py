"""Cuándo cambió cada usuario su contraseña por última vez.

La contraseña vive en Firebase; la base guarda el rastro del cambio.

Revision ID: 0002
Revises: 0001
"""

from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TABLE usuario ADD COLUMN contrasena_cambiada_en timestamptz")


def downgrade() -> None:
    op.execute("ALTER TABLE usuario DROP COLUMN contrasena_cambiada_en")
