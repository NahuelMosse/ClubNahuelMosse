"""Dos sedes activas no pueden llamarse igual.

Revision ID: 0004
Revises: 0003
"""

from alembic import op

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE UNIQUE INDEX sede_nombre_activa_unico ON sede (lower(nombre)) WHERE activa")


def downgrade() -> None:
    op.execute("DROP INDEX sede_nombre_activa_unico")
