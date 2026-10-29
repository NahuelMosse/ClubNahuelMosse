"""Enlaces de recuperación de contraseña y correos que salen.

Revision ID: 0003
Revises: 0002
"""

from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE enlace_recuperacion (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            usuario_id bigint NOT NULL REFERENCES usuario (id),
            -- Sólo el hash: con la base en la mano no se puede usar un enlace vigente.
            codigo_hash text NOT NULL UNIQUE,
            emitido_en timestamptz NOT NULL DEFAULT clock_timestamp(),
            vence_en timestamptz NOT NULL,
            usado_en timestamptz,
            invalidado_en timestamptz,
            CHECK (vence_en > emitido_en)
        )
        """
    )
    op.execute(
        "CREATE INDEX enlace_recuperacion_por_usuario"
        " ON enlace_recuperacion (usuario_id, emitido_en)"
    )
    op.execute(
        """
        CREATE TABLE correo_saliente (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            para text NOT NULL,
            asunto text NOT NULL,
            cuerpo text NOT NULL,
            creado_en timestamptz NOT NULL DEFAULT clock_timestamp()
        )
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE correo_saliente")
    op.execute("DROP TABLE enlace_recuperacion")
