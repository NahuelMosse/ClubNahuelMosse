"""The schema in English: tables, columns, constraints, indexes, triggers, functions, the view
and the stored enum values.

Each definition that mentions a stored value is dropped and created again with the translated
text; every other one is renamed in place. The triggers are dropped first so `updated_at` of the
rows keeps its value. Going back applies the same move with the vocabulary reversed. The
migration gives up after five seconds on a held lock and can run again.

Revision ID: 0012
Revises: 0011
"""

import re
from dataclasses import dataclass, field
from typing import Any

import sqlalchemy as sa
from alembic import op

revision = "0012"
down_revision = "0011"
branch_labels = None
depends_on = None

LOCK_TIMEOUT = "5s"

TABLES = {
    "usuario": "app_user",
    "sede": "venue",
    "espacio": "space",
    "reserva": "booking",
    "enlace_recuperacion": "recovery_link",
    "correo_saliente": "outgoing_email",
    "dispositivo": "device",
    "notificacion": "notification",
    "notificacion_reserva": "notification_booking",
}

# The column that marks a soft-deleted row is `activa` in `sede` and `activo` elsewhere.
SOFT_DELETE = {"usuario": "activo", "sede": "activa", "espacio": "activo", "dispositivo": "activo"}

COMMON_COLUMNS = {
    "creado_en": "created_at",
    "modificado_en": "updated_at",
    "dado_de_baja_en": "deactivated_at",
    "dado_de_baja_por": "deactivated_by",
    "creado_por": "created_by",
    "modificado_por": "updated_by",
    "usuario_id": "user_id",
    "reserva_id": "booking_id",
    "precio_por_hora": "price_per_hour",
    "cuerpo": "body",
}

OWN_COLUMNS = {
    "usuario": {
        "correo": "email",
        "nombre": "first_name",
        "apellido": "last_name",
        "fecha_nacimiento": "birth_date",
        "rol": "role",
        "contrasena_cambiada_en": "password_changed_at",
    },
    "sede": {
        "nombre": "name",
        "calle": "street",
        "altura": "street_number",
        "apertura": "opens_at",
        "cierre": "closes_at",
        "dias": "open_days",
    },
    "espacio": {
        "sede_id": "venue_id",
        "deporte": "sport",
        "tipo": "kind",
        "numero": "number",
        "nombre": "name",
        "techada": "covered",
        "iluminada": "lit",
    },
    "reserva": {
        "espacio_id": "space_id",
        "inicio": "starts_at",
        "fin": "ends_at",
        "estado": "status",
        "cancelada_en": "canceled_at",
        "cancelada_por": "canceled_by",
        "motivo": "reason",
    },
    "enlace_recuperacion": {
        "codigo_hash": "code_hash",
        "vence_en": "expires_at",
        "usado_en": "used_at",
        "invalidado_en": "invalidated_at",
    },
    "correo_saliente": {"para": "recipient", "asunto": "subject"},
    "dispositivo": {"plataforma": "platform", "permiso": "permission_granted"},
    "notificacion": {
        "tipo": "kind",
        "titulo": "title",
        "reserva_inicio": "booking_starts_at",
        "envio": "delivery",
        "enviada_en": "sent_at",
        "leida_en": "read_at",
        "reemplazada_por": "replaced_by",
        "cantidad": "count",
        "enviando_desde": "sending_since",
    },
    "notificacion_reserva": {"notificacion_id": "notification_id"},
}

VALUES = {
    "usuario": "user",
    "activa": "active",
    "cancelada": "canceled",
    "anulada": "voided",
    "recordatorio": "reminder",
    "recordatorio_cinco": "five_minute_reminder",
    "cancelacion_forzosa": "forced_cancellation",
    "cancelacion_usuario": "user_cancellation",
    "pendiente": "pending",
    "enviando": "sending",
    "enviada": "sent",
    "sin_permiso": "no_permission",
    "sin_canal": "no_channel",
    "fallida": "failed",
}

FUNCTIONS = {
    "marcar_modificado": "touch_updated_at",
    "prohibir_borrado": "forbid_delete",
    "correo_inmutable": "email_immutable",
    "nombre_espacio_inmutable": "space_identity_immutable",
}

TRIGGERS = {
    **{f"{es}_modificado": f"{en}_updated" for es, en in TABLES.items()},
    **{
        f"{es}_sin_borrado": f"{TABLES[es]}_no_delete"
        for es in ("usuario", "sede", "espacio", "reserva")
    },
    "usuario_correo_inmutable": "app_user_email_immutable",
    "espacio_nombre_inmutable": "space_name_immutable",
}

INDEXES = {
    "usuario_correo_unico": "app_user_email_unique",
    "usuario_dni_unico": "app_user_dni_unique",
    "sede_nombre_activa_unico": "venue_name_active_unique",
    "dispositivo_token_activo": "device_token_active",
    "dispositivo_usuario": "device_user",
    "notificacion_recordatorio_unico": "notification_reminder_unique",
    "notificacion_recordatorio_cinco_unico": "notification_five_minute_reminder_unique",
    "notificacion_cancelacion_unica": "notification_cancellation_unique",
    "notificacion_usuario": "notification_user",
    "notificacion_forzosa_sin_leer": "notification_forced_unread",
    "notificacion_por_despachar": "notification_to_dispatch",
    "notificacion_por_reemplazada_por": "notification_by_replaced_by",
    "reserva_activa_inicio": "booking_active_starts_at",
    "reserva_por_usuario_inicio": "booking_by_user_starts_at",
    "reserva_por_inicio": "booking_by_starts_at",
    "reserva_por_cancelada_por": "booking_by_canceled_by",
    "enlace_recuperacion_por_usuario": "recovery_link_by_user",
}

# Constraints whose name is not the table plus the translated columns.
CONSTRAINTS = {
    "notificacion_cancelacion_con_reserva": "notification_cancellation_has_booking",
}

VIEWS = {"reserva_con_estado": "booking_with_status"}

# Columns that store an enum value, with the value their default holds.
VALUE_COLUMNS = (
    ("usuario", "rol"),
    ("reserva", "estado"),
    ("notificacion", "tipo"),
    ("notificacion", "envio"),
)
DEFAULTS = {("usuario", "rol"): "usuario", ("reserva", "estado"): "activa"}


@dataclass(frozen=True)
class Move:
    """Every name and value of the schema in force, with the one it takes."""

    tables: dict[str, str]
    columns: dict[str, dict[str, str]]
    values: dict[str, str]
    functions: dict[str, str]
    triggers: dict[str, str]
    indexes: dict[str, str]
    constraints: dict[str, str]
    views: dict[str, str]
    value_columns: tuple[tuple[str, str], ...]
    defaults: dict[tuple[str, str], str] = field(default_factory=dict)


def _columns_of(table: str) -> dict[str, str]:
    columns = {**COMMON_COLUMNS, **OWN_COLUMNS[table]}
    if table in SOFT_DELETE:
        columns[SOFT_DELETE[table]] = "active"
    return columns


def _inverse(names: dict[str, str]) -> dict[str, str]:
    return {new: old for old, new in names.items()}


def _reversed(move: Move) -> Move:
    return Move(
        tables=_inverse(move.tables),
        columns={move.tables[t]: _inverse(cols) for t, cols in move.columns.items()},
        values=_inverse(move.values),
        functions=_inverse(move.functions),
        triggers=_inverse(move.triggers),
        indexes=_inverse(move.indexes),
        constraints=_inverse(move.constraints),
        views=_inverse(move.views),
        value_columns=tuple((move.tables[t], move.columns[t][c]) for t, c in move.value_columns),
        defaults={
            (move.tables[t], move.columns[t][c]): move.values[value]
            for (t, c), value in move.defaults.items()
        },
    )


TO_ENGLISH = Move(
    tables=TABLES,
    columns={table: _columns_of(table) for table in TABLES},
    values=VALUES,
    functions=FUNCTIONS,
    triggers=TRIGGERS,
    indexes=INDEXES,
    constraints=CONSTRAINTS,
    views=VIEWS,
    value_columns=VALUE_COLUMNS,
    defaults=DEFAULTS,
)
TO_SPANISH = _reversed(TO_ENGLISH)

QUOTED = re.compile(r"'(\w+)'")
WORD = re.compile(r"(?<!')\b\w+\b(?!')")


def _translate(move: Move, table: str, sql: str) -> str:
    """The definition `sql` of an object of `table` with each name and value renamed."""
    sql = QUOTED.sub(lambda m: f"'{move.values.get(m[1], m[1])}'", sql)
    words = {**move.tables, **move.functions, **move.columns[table]}
    return WORD.sub(lambda m: words.get(m[0], m[0]), sql)


def _mentions_a_value(move: Move, sql: str) -> bool:
    return any(found in move.values for found in QUOTED.findall(sql))


def _constraint_name(move: Move, table: str, name: str) -> str:
    if name in move.constraints:
        return move.constraints[name]
    if not name.startswith(table):
        raise ValueError(f"constraint {name} does not start with its table {table}")
    columns = move.columns[table]
    alternatives = "|".join(sorted(map(re.escape, columns), key=len, reverse=True))
    rest = re.sub(
        rf"(?<![a-z0-9])({alternatives})(?![a-z0-9])",
        lambda m: columns[m[1]],
        name.removeprefix(table),
    )
    return move.tables[table] + rest


def _rows(sql: str) -> list[Any]:
    return op.get_bind().execute(sa.text(sql)).all()


def _read_constraints(move: Move) -> list[Any]:
    rows = _rows(
        "SELECT c.conrelid::regclass::text, c.conname, pg_get_constraintdef(c.oid)"
        " FROM pg_constraint c WHERE c.connamespace = 'public'::regnamespace"
        " AND c.contype IN ('c', 'x')"
    )
    return [r for r in rows if r[0] in move.tables and _mentions_a_value(move, r[2])]


def _read_indexes(move: Move) -> list[Any]:
    rows = _rows(
        "SELECT tablename, indexname, indexdef FROM pg_indexes WHERE schemaname = 'public'"
        " AND indexname NOT IN (SELECT conname FROM pg_constraint)"
    )
    return [r for r in rows if r[0] in move.tables]


def _read_triggers() -> list[Any]:
    return _rows(
        "SELECT c.relname, t.tgname, pg_get_triggerdef(t.oid) FROM pg_trigger t"
        " JOIN pg_class c ON c.oid = t.tgrelid"
        " WHERE NOT t.tgisinternal AND c.relnamespace = 'public'::regnamespace"
    )


def _translate_values(move: Move) -> None:
    cases = " ".join(f"WHEN '{old}' THEN '{new}'" for old, new in move.values.items())
    olds = ", ".join(f"'{old}'" for old in move.values)
    for table, column in move.value_columns:
        op.execute(
            f"UPDATE {table} SET {column} = CASE {column} {cases} ELSE {column} END"
            f" WHERE {column} IN ({olds})"
        )


def _rename_tables_and_columns(move: Move) -> None:
    for table, new_table in move.tables.items():
        actual = _rows(
            f"SELECT column_name FROM information_schema.columns WHERE table_name = '{table}'"
        )
        for (column,) in actual:
            if column in move.columns[table]:
                new_column = move.columns[table][column]
                op.execute(f"ALTER TABLE {table} RENAME COLUMN {column} TO {new_column}")
        op.execute(f"ALTER TABLE {table} RENAME TO {new_table}")


def _rename_constraints(move: Move) -> None:
    for table, new_table in move.tables.items():
        for (name,) in _rows(
            f"SELECT conname FROM pg_constraint WHERE conrelid = 'public.{new_table}'::regclass"
        ):
            new_name = _constraint_name(move, table, name)
            if new_name != name:
                op.execute(f"ALTER TABLE {new_table} RENAME CONSTRAINT {name} TO {new_name}")


def _create_definitions(move: Move, constraints: list[Any], indexes: list[Any]) -> None:
    for table, name, definition in constraints:
        op.execute(
            f"ALTER TABLE {move.tables[table]} ADD CONSTRAINT {_constraint_name(move, table, name)}"
            f" {_translate(move, table, definition)}"
        )
    for table, name, definition in indexes:
        if _mentions_a_value(move, definition):
            renamed = re.sub(r"INDEX \w+", f"INDEX {move.indexes[name]}", definition, count=1)
            op.execute(_translate(move, table, renamed))


def _drop_definitions(
    move: Move, constraints: list[Any], indexes: list[Any], triggers: list[Any]
) -> None:
    for view in move.views:
        op.execute(f"DROP VIEW {view}")
    for table, name, _ in triggers:
        op.execute(f"DROP TRIGGER {name} ON {table}")
    for table, name, _ in constraints:
        op.execute(f"ALTER TABLE {table} DROP CONSTRAINT {name}")
    for _, name, definition in indexes:
        if _mentions_a_value(move, definition):
            op.execute(f"DROP INDEX {name}")
    for function in move.functions:
        op.execute(f"DROP FUNCTION {function}()")


def _rename_in_place(move: Move, indexes: list[Any]) -> None:
    _rename_tables_and_columns(move)
    _rename_constraints(move)
    for _, name, definition in indexes:
        if not _mentions_a_value(move, definition):
            op.execute(f"ALTER INDEX {name} RENAME TO {move.indexes[name]}")
    for (table, column), value in move.defaults.items():
        op.execute(
            f"ALTER TABLE {move.tables[table]} ALTER COLUMN {move.columns[table][column]}"
            f" SET DEFAULT '{move.values[value]}'"
        )


def _create_triggers(move: Move, triggers: list[Any]) -> None:
    for table, name, definition in triggers:
        head = f"CREATE TRIGGER {move.triggers[name]}"
        op.execute(_translate(move, table, re.sub(r"^CREATE TRIGGER \w+", head, definition)))


def _migrate(move: Move, target_functions: list[str], target_view: str) -> None:
    op.execute(f"SET LOCAL lock_timeout = '{LOCK_TIMEOUT}'")
    constraints = _read_constraints(move)
    indexes = _read_indexes(move)
    triggers = _read_triggers()

    _drop_definitions(move, constraints, indexes, triggers)
    _translate_values(move)
    _rename_in_place(move, indexes)

    for statement in target_functions:
        op.execute(statement)
    _create_definitions(move, constraints, indexes)
    _create_triggers(move, triggers)
    op.execute(target_view)


ENGLISH_FUNCTIONS = [
    """
    CREATE FUNCTION touch_updated_at() RETURNS trigger AS $$
    BEGIN
        NEW.created_at := OLD.created_at;
        NEW.updated_at := clock_timestamp();
        RETURN NEW;
    END $$ LANGUAGE plpgsql
    """,
    """
    CREATE FUNCTION forbid_delete() RETURNS trigger AS $$
    BEGIN
        RAISE EXCEPTION 'removals are logical: % is never deleted', TG_TABLE_NAME
            USING ERRCODE = 'restrict_violation';
    END $$ LANGUAGE plpgsql
    """,
    """
    CREATE FUNCTION email_immutable() RETURNS trigger AS $$
    BEGIN
        IF NEW.email IS DISTINCT FROM OLD.email THEN
            RAISE EXCEPTION 'the email of a user cannot be changed'
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
    END $$ LANGUAGE plpgsql
    """,
    """
    CREATE FUNCTION space_identity_immutable() RETURNS trigger AS $$
    BEGIN
        IF (NEW.name, NEW.venue_id, NEW.sport, NEW.kind, NEW.number)
           IS DISTINCT FROM (OLD.name, OLD.venue_id, OLD.sport, OLD.kind, OLD.number) THEN
            RAISE EXCEPTION 'the identity of a space does not change'
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
    END $$ LANGUAGE plpgsql
    """,
    """
    CREATE OR REPLACE FUNCTION uuid_v7() RETURNS uuid AS $$
    DECLARE
        ms numeric := extract(epoch FROM clock_timestamp()) * 1000;
        whole bigint := floor(ms);
        fraction integer := floor((ms - whole) * 4096);
        bytes bytea := uuid_send(gen_random_uuid());
    BEGIN
        FOR i IN 0..5 LOOP
            bytes := set_byte(bytes, i, ((whole >> (8 * (5 - i))) & 255)::integer);
        END LOOP;
        bytes := set_byte(bytes, 6, 112 | (fraction >> 8));
        bytes := set_byte(bytes, 7, fraction & 255);
        bytes := set_byte(bytes, 8, (get_byte(bytes, 8) & 63) | 128);
        RETURN encode(bytes, 'hex')::uuid;
    END $$ LANGUAGE plpgsql VOLATILE
    """,
]

ENGLISH_VIEW = """
    CREATE VIEW booking_with_status AS
    SELECT booking.*,
           CASE WHEN status = 'active' AND ends_at <= now() THEN 'completed' ELSE status END
               AS current_status
    FROM booking
"""

SPANISH_FUNCTIONS = [
    """
    CREATE FUNCTION marcar_modificado() RETURNS trigger AS $$
    BEGIN
        NEW.creado_en := OLD.creado_en;
        NEW.modificado_en := clock_timestamp();
        RETURN NEW;
    END $$ LANGUAGE plpgsql
    """,
    """
    CREATE FUNCTION prohibir_borrado() RETURNS trigger AS $$
    BEGIN
        RAISE EXCEPTION 'las bajas son lógicas: % no se borra', TG_TABLE_NAME
            USING ERRCODE = 'restrict_violation';
    END $$ LANGUAGE plpgsql
    """,
    """
    CREATE FUNCTION correo_inmutable() RETURNS trigger AS $$
    BEGIN
        IF NEW.correo IS DISTINCT FROM OLD.correo THEN
            RAISE EXCEPTION 'el correo de un usuario no se puede cambiar'
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
    END $$ LANGUAGE plpgsql
    """,
    """
    CREATE FUNCTION nombre_espacio_inmutable() RETURNS trigger AS $$
    BEGIN
        IF (NEW.nombre, NEW.sede_id, NEW.deporte, NEW.tipo, NEW.numero)
           IS DISTINCT FROM (OLD.nombre, OLD.sede_id, OLD.deporte, OLD.tipo, OLD.numero) THEN
            RAISE EXCEPTION 'la identidad de un espacio no cambia'
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
    END $$ LANGUAGE plpgsql
    """,
    """
    CREATE OR REPLACE FUNCTION uuid_v7() RETURNS uuid AS $$
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
    """,
]

SPANISH_VIEW = """
    CREATE VIEW reserva_con_estado AS
    SELECT reserva.*,
           CASE WHEN estado = 'activa' AND fin <= now() THEN 'completada' ELSE estado END
               AS estado_actual
    FROM reserva
"""


def upgrade() -> None:
    _migrate(TO_ENGLISH, ENGLISH_FUNCTIONS, ENGLISH_VIEW)


def downgrade() -> None:
    _migrate(TO_SPANISH, SPANISH_FUNCTIONS, SPANISH_VIEW)
