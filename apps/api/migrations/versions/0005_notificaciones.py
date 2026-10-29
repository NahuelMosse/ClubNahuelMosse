"""Dispositivos con notificaciones y el centro de notificaciones.

Revision ID: 0005
Revises: 0004
"""

from alembic import op

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Un teléfono con la app instalada. La baja es lógica: al cerrar la sesión el dispositivo
    # deja de recibir avisos, pero queda cuándo se registró y cuándo se fue.
    op.execute(
        """
        CREATE TABLE dispositivo (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            usuario_id bigint NOT NULL REFERENCES usuario (id),
            token text NOT NULL CHECK (btrim(token) <> ''),
            plataforma text NOT NULL CHECK (plataforma IN ('android', 'ios')),
            -- lo que el sistema operativo contestó sobre el permiso de notificaciones
            permiso boolean NOT NULL,
            activo boolean NOT NULL DEFAULT true,
            registrado_en timestamptz NOT NULL DEFAULT now(),
            actualizado_en timestamptz NOT NULL DEFAULT now(),
            dado_de_baja_en timestamptz,
            CHECK (activo = (dado_de_baja_en IS NULL))
        )
        """
    )
    # Un token pertenece a una sola cuenta a la vez: si otra inicia sesión en el mismo teléfono,
    # el registro pasa a ella.
    op.execute("CREATE UNIQUE INDEX dispositivo_token_activo ON dispositivo (token) WHERE activo")
    op.execute("CREATE INDEX dispositivo_usuario ON dispositivo (usuario_id) WHERE activo")

    op.execute(
        """
        CREATE TABLE notificacion (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            usuario_id bigint NOT NULL REFERENCES usuario (id),
            tipo text NOT NULL
                CHECK (tipo IN ('recordatorio', 'cancelacion_forzosa', 'cancelacion_usuario')),
            titulo text NOT NULL CHECK (btrim(titulo) <> ''),
            cuerpo text NOT NULL CHECK (btrim(cuerpo) <> ''),
            reserva_id bigint REFERENCES reserva (id),
            -- el horario al que refiere: si la reserva se mueve, es otro aviso
            reserva_inicio timestamptz,
            envio text NOT NULL
                CHECK (envio IN ('pendiente', 'enviada', 'sin_permiso', 'sin_canal', 'fallida')),
            creada_en timestamptz NOT NULL DEFAULT now(),
            enviada_en timestamptz,
            leida_en timestamptz,
            CHECK (tipo <> 'recordatorio'
                   OR (reserva_id IS NOT NULL AND reserva_inicio IS NOT NULL))
        )
        """
    )
    op.execute(
        "CREATE UNIQUE INDEX notificacion_recordatorio_unico"
        " ON notificacion (reserva_id, reserva_inicio) WHERE tipo = 'recordatorio'"
    )
    op.execute("CREATE INDEX notificacion_usuario ON notificacion (usuario_id, creada_en DESC)")
    # El barrido busca las reservas activas que empiezan en la hora que viene.
    op.execute("CREATE INDEX reserva_activa_inicio ON reserva (inicio) WHERE estado = 'activa'")


def downgrade() -> None:
    op.execute("DROP INDEX reserva_activa_inicio")
    op.execute("DROP TABLE notificacion")
    op.execute("DROP TABLE dispositivo")
