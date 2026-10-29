"""Índices de los historiales y de las claves foráneas, y columnas para recuperar la cola de avisos.

Revision ID: 0008
Revises: 0007
"""

from alembic import op
from sqlalchemy import text

revision = "0008"
down_revision = "0007"
branch_labels = None
depends_on = None

# Si un lock no se consigue en este tiempo la migración falla y se reintenta, en vez de dejar
# esperando (y haciendo esperar atrás) a la versión anterior que sigue atendiendo.
_ESPERA_DE_LOCK = "5s"

_INDICES = {
    # El historial propio, por socio y de la más reciente a la más vieja.
    "reserva_por_usuario_inicio": "reserva (usuario_id, inicio DESC, id DESC)",
    # El historial global y la clave del marcador de página.
    "reserva_por_inicio": "reserva (inicio DESC, id DESC)",
    "reserva_por_cancelada_por": "reserva (cancelada_por) WHERE cancelada_por IS NOT NULL",
    "notificacion_por_reemplazada_por": (
        "notificacion (reemplazada_por) WHERE reemplazada_por IS NOT NULL"
    ),
}


def _soltar_invalidos() -> None:
    """Un `CREATE INDEX CONCURRENTLY` cortado deja un índice inválido con su nombre: sin sacarlo,
    el `IF NOT EXISTS` de abajo lo daría por creado."""
    invalidos = op.get_bind().execute(
        text(
            "SELECT c.relname FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid"
            " WHERE NOT i.indisvalid AND c.relname = ANY(:nombres)"
        ),
        {"nombres": list(_INDICES)},
    )
    for nombre in [f.relname for f in invalidos]:
        op.execute(f"DROP INDEX CONCURRENTLY IF EXISTS {nombre}")


def upgrade() -> None:
    op.execute(f"SET lock_timeout = '{_ESPERA_DE_LOCK}'")
    # Expandir sin contraer: columnas con valor por defecto, que la versión anterior ignora.
    op.execute(
        "ALTER TABLE notificacion"
        " ADD COLUMN IF NOT EXISTS tomada_en timestamptz,"
        " ADD COLUMN IF NOT EXISTS intentos integer NOT NULL DEFAULT 0"
    )
    # CONCURRENTLY no corre dentro de una transacción y no bloquea las escrituras mientras arma
    # el índice.
    with op.get_context().autocommit_block():
        op.execute(f"SET lock_timeout = '{_ESPERA_DE_LOCK}'")
        _soltar_invalidos()
        for nombre, definicion in _INDICES.items():
            op.execute(f"CREATE INDEX CONCURRENTLY IF NOT EXISTS {nombre} ON {definicion}")


def downgrade() -> None:
    op.execute(f"SET lock_timeout = '{_ESPERA_DE_LOCK}'")
    with op.get_context().autocommit_block():
        op.execute(f"SET lock_timeout = '{_ESPERA_DE_LOCK}'")
        for nombre in _INDICES:
            op.execute(f"DROP INDEX CONCURRENTLY IF EXISTS {nombre}")
    op.execute(
        "ALTER TABLE notificacion DROP COLUMN IF EXISTS intentos, DROP COLUMN IF EXISTS tomada_en"
    )
