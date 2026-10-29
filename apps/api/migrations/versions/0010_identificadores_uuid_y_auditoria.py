"""Claves UUIDv7 en todas las tablas y auditoría (creado_en, modificado_en) en las nueve.

Las filas que ya existen reciben un UUID versión 7 con marca de tiempo cero armado con su id viejo
(conserva el orden y deja lo viejo antes de lo nuevo). Volver atrás falla si hay filas con ids
creados después.

Revision ID: 0010
Revises: 0009
"""

from alembic import op

revision = "0010"
down_revision = "0009"
branch_labels = None
depends_on = None

TABLAS_CON_ID = (
    "usuario",
    "sede",
    "espacio",
    "reserva",
    "enlace_recuperacion",
    "correo_saliente",
    "dispositivo",
    "notificacion",
)

# (tabla, columna, tabla a la que apunta): las 17 referencias entre tablas.
REFERENCIAS = (
    ("sede", "creado_por", "usuario"),
    ("sede", "modificado_por", "usuario"),
    ("sede", "dado_de_baja_por", "usuario"),
    ("espacio", "sede_id", "sede"),
    ("espacio", "creado_por", "usuario"),
    ("espacio", "modificado_por", "usuario"),
    ("espacio", "dado_de_baja_por", "usuario"),
    ("reserva", "usuario_id", "usuario"),
    ("reserva", "espacio_id", "espacio"),
    ("reserva", "cancelada_por", "usuario"),
    ("enlace_recuperacion", "usuario_id", "usuario"),
    ("dispositivo", "usuario_id", "usuario"),
    ("notificacion", "usuario_id", "usuario"),
    ("notificacion", "reserva_id", "reserva"),
    ("notificacion", "reemplazada_por", "notificacion"),
    ("notificacion_reserva", "notificacion_id", "notificacion"),
    ("notificacion_reserva", "reserva_id", "reserva"),
)

# Las tablas que no tenían el disparador de `modificado_en` (0001 lo puso en las otras cuatro).
SIN_DISPARADOR = (
    "enlace_recuperacion",
    "correo_saliente",
    "dispositivo",
    "notificacion",
    "notificacion_reserva",
)

# `reserva.*` se congela al crear la vista: se recrea tal cual en 0001.
VISTA = """
    CREATE VIEW reserva_con_estado AS
    SELECT reserva.*,
           CASE WHEN estado = 'activa' AND fin <= now() THEN 'completada' ELSE estado END
               AS estado_actual
    FROM reserva
"""

HEREDADO = "'00000000-0000-7000-'"


def _soltar_referencias() -> None:
    for tabla, columna, _ in REFERENCIAS:
        op.execute(f"ALTER TABLE {tabla} DROP CONSTRAINT {tabla}_{columna}_fkey")


def _crear_referencias() -> None:
    for tabla, columna, destino in REFERENCIAS:
        op.execute(
            f"ALTER TABLE {tabla} ADD CONSTRAINT {tabla}_{columna}_fkey"
            f" FOREIGN KEY ({columna}) REFERENCES {destino} (id)"
        )


def _crear_disparadores() -> None:
    for tabla in SIN_DISPARADOR:
        op.execute(
            f"CREATE TRIGGER {tabla}_modificado BEFORE UPDATE ON {tabla}"
            " FOR EACH ROW EXECUTE FUNCTION marcar_modificado()"
        )


def _auditoria_arriba() -> None:
    op.execute("ALTER TABLE enlace_recuperacion RENAME COLUMN emitido_en TO creado_en")
    op.execute("ALTER TABLE notificacion RENAME COLUMN creada_en TO creado_en")
    op.execute("ALTER TABLE dispositivo RENAME COLUMN registrado_en TO creado_en")
    op.execute("ALTER TABLE dispositivo RENAME COLUMN actualizado_en TO modificado_en")
    for tabla, defecto in (
        ("enlace_recuperacion", "clock_timestamp()"),
        ("correo_saliente", "clock_timestamp()"),
        ("notificacion", "now()"),
    ):
        op.execute(f"ALTER TABLE {tabla} ADD COLUMN modificado_en timestamptz DEFAULT {defecto}")
        op.execute(f"UPDATE {tabla} SET modificado_en = creado_en")
        op.execute(f"ALTER TABLE {tabla} ALTER COLUMN modificado_en SET NOT NULL")
    op.execute(
        "ALTER TABLE notificacion_reserva"
        " ADD COLUMN creado_en timestamptz NOT NULL DEFAULT now(),"
        " ADD COLUMN modificado_en timestamptz NOT NULL DEFAULT now()"
    )
    _crear_disparadores()


def _auditoria_abajo() -> None:
    for tabla in SIN_DISPARADOR:
        op.execute(f"DROP TRIGGER {tabla}_modificado ON {tabla}")
    op.execute("ALTER TABLE notificacion_reserva DROP COLUMN creado_en, DROP COLUMN modificado_en")
    for tabla in ("enlace_recuperacion", "correo_saliente", "notificacion"):
        op.execute(f"ALTER TABLE {tabla} DROP COLUMN modificado_en")
    op.execute("ALTER TABLE dispositivo RENAME COLUMN modificado_en TO actualizado_en")
    op.execute("ALTER TABLE dispositivo RENAME COLUMN creado_en TO registrado_en")
    op.execute("ALTER TABLE notificacion RENAME COLUMN creado_en TO creada_en")
    op.execute("ALTER TABLE enlace_recuperacion RENAME COLUMN creado_en TO emitido_en")


def upgrade() -> None:
    # Como `uuid_v7()` de Postgres 18: 48 bits de milisegundos y 12 bits de fracción de
    # milisegundo, para que dos filas del mismo milisegundo salgan en orden.
    op.execute(
        """
        CREATE FUNCTION uuid_v7() RETURNS uuid AS $$
        DECLARE
            ms numeric := extract(epoch FROM clock_timestamp()) * 1000;
            entero bigint := floor(ms);
            fraccion integer := floor((ms - entero) * 4096);
            bytes bytea := uuid_send(gen_random_uuid());
        BEGIN
            FOR i IN 0..5 LOOP
                bytes := set_byte(bytes, i, ((entero >> (8 * (5 - i))) & 255)::integer);
            END LOOP;
            bytes := set_byte(bytes, 6, 112 | (fraccion >> 8));
            bytes := set_byte(bytes, 7, fraccion & 255);
            bytes := set_byte(bytes, 8, (get_byte(bytes, 8) & 63) | 128);
            RETURN encode(bytes, 'hex')::uuid;
        END $$ LANGUAGE plpgsql VOLATILE
        """
    )
    op.execute(
        f"""
        CREATE FUNCTION id_heredado(viejo bigint) RETURNS uuid AS $$
            SELECT ({HEREDADO} || substr(h, 1, 4) || '-' || substr(h, 5))::uuid
            FROM (SELECT lpad(to_hex(viejo + (-9223372036854775807 - 1)), 16, '0') AS h) AS t
        $$ LANGUAGE sql IMMUTABLE STRICT
        """
    )
    op.execute("DROP VIEW reserva_con_estado")
    _soltar_referencias()
    for tabla in TABLAS_CON_ID:
        op.execute(f"ALTER TABLE {tabla} ALTER COLUMN id DROP IDENTITY")
        op.execute(f"ALTER TABLE {tabla} ALTER COLUMN id TYPE uuid USING id_heredado(id)")
        op.execute(f"ALTER TABLE {tabla} ALTER COLUMN id SET DEFAULT uuid_v7()")
    for tabla, columna, _ in REFERENCIAS:
        op.execute(
            f"ALTER TABLE {tabla} ALTER COLUMN {columna} TYPE uuid USING id_heredado({columna})"
        )
    _crear_referencias()
    _auditoria_arriba()
    op.execute(VISTA)
    op.execute("DROP FUNCTION id_heredado(bigint)")


def downgrade() -> None:
    op.execute(
        f"""
        CREATE FUNCTION id_original(nuevo uuid) RETURNS bigint AS $$
        BEGIN
            IF substr(nuevo::text, 1, 19) <> {HEREDADO} THEN
                RAISE EXCEPTION
                    'no se puede volver atrás: hay filas creadas después de la migración 0010'
                    USING ERRCODE = 'check_violation';
            END IF;
            RETURN ('x' || right(replace(nuevo::text, '-', ''), 16))::bit(64)::bigint
                & 4611686018427387903;
        END $$ LANGUAGE plpgsql IMMUTABLE STRICT
        """
    )
    op.execute("DROP VIEW reserva_con_estado")
    _soltar_referencias()
    for tabla in TABLAS_CON_ID:
        op.execute(f"ALTER TABLE {tabla} ALTER COLUMN id DROP DEFAULT")
        op.execute(f"ALTER TABLE {tabla} ALTER COLUMN id TYPE bigint USING id_original(id)")
        op.execute(f"ALTER TABLE {tabla} ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY")
        op.execute(
            f"SELECT setval(pg_get_serial_sequence('{tabla}', 'id'),"
            f" coalesce((SELECT max(id) FROM {tabla}), 0) + 1, false)"
        )
    for tabla, columna, _ in REFERENCIAS:
        op.execute(
            f"ALTER TABLE {tabla} ALTER COLUMN {columna} TYPE bigint USING id_original({columna})"
        )
    _crear_referencias()
    _auditoria_abajo()
    op.execute(VISTA)
    op.execute("DROP FUNCTION id_original(uuid)")
    op.execute("DROP FUNCTION uuid_v7()")
