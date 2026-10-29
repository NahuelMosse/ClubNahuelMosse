"""The database after revision 0012: every name and stored value in English, same behavior."""

import re
import threading
from collections.abc import Callable
from typing import Any

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import Connection, Engine, text
from sqlalchemy.exc import IntegrityError, OperationalError
from test_datos import _capturar
from test_datos_migraciones import base_propia  # noqa: F401  (fixture)

Base = tuple[Engine, AlembicConfig]

TABLES = {
    "alembic_version", "app_user", "venue", "space", "booking", "recovery_link",
    "outgoing_email", "device", "notification", "notification_booking",
}  # fmt: skip

AUDIT = {"created_at", "updated_at"}
SOFT_DELETE = {"active", "deactivated_at"}
COLUMNS = {
    "alembic_version": {"version_num"},
    "app_user": {
        "id", "firebase_uid", "email", "first_name", "last_name", "dni", "birth_date", "role",
        "password_changed_at", *AUDIT, *SOFT_DELETE,
    },
    "venue": {
        "id", "name", "street", "street_number", "opens_at", "closes_at", "open_days",
        "created_by", "updated_by", "deactivated_by", *AUDIT, *SOFT_DELETE,
    },
    "space": {
        "id", "venue_id", "sport", "kind", "number", "name", "covered", "lit", "price_per_hour",
        "created_by", "updated_by", "deactivated_by", *AUDIT, *SOFT_DELETE,
    },
    "booking": {
        "id", "user_id", "space_id", "starts_at", "ends_at", "price_per_hour", "total", "status",
        "canceled_at", "canceled_by", "reason", *AUDIT,
    },
    "recovery_link": {
        "id", "user_id", "code_hash", "expires_at", "used_at", "invalidated_at", *AUDIT,
    },
    "outgoing_email": {"id", "recipient", "subject", "body", *AUDIT},
    "device": {
        "id", "user_id", "token", "platform", "permission_granted", *AUDIT, *SOFT_DELETE,
    },
    "notification": {
        "id", "user_id", "kind", "title", "body", "booking_id", "booking_starts_at", "delivery",
        "sent_at", "read_at", "replaced_by", "count", "sending_since", *AUDIT,
    },
    "notification_booking": {"notification_id", "booking_id", *AUDIT},
}  # fmt: skip

CONSTRAINTS = {
    "alembic_version_pkc",
    "app_user_pkey", "app_user_firebase_uid_key", "app_user_last_name_check", "app_user_check",
    "app_user_dni_check", "app_user_first_name_check", "app_user_role_check",
    "venue_pkey", "venue_street_number_check", "venue_street_check", "venue_check",
    "venue_check1", "venue_check2", "venue_open_days_check", "venue_name_check",
    "venue_created_by_fkey", "venue_deactivated_by_fkey", "venue_updated_by_fkey",
    "space_pkey", "space_name_key", "space_venue_id_sport_kind_number_key", "space_check",
    "space_sport_check", "space_number_check", "space_price_per_hour_check", "space_kind_check",
    "space_created_by_fkey", "space_deactivated_by_fkey", "space_updated_by_fkey",
    "space_venue_id_fkey",
    "booking_pkey", "booking_check", "booking_check1", "booking_check2", "booking_check3",
    "booking_status_check", "booking_price_per_hour_check", "booking_space_id_tstzrange_excl",
    "booking_canceled_by_fkey", "booking_space_id_fkey", "booking_user_id_fkey",
    "recovery_link_pkey", "recovery_link_code_hash_key", "recovery_link_check",
    "recovery_link_user_id_fkey",
    "outgoing_email_pkey",
    "device_pkey", "device_check", "device_platform_check", "device_token_check",
    "device_user_id_fkey",
    "notification_pkey", "notification_cancellation_has_booking", "notification_count_check",
    "notification_check", "notification_body_check", "notification_delivery_check",
    "notification_kind_check", "notification_title_check", "notification_replaced_by_fkey",
    "notification_booking_id_fkey", "notification_user_id_fkey",
    "notification_booking_pkey", "notification_booking_booking_id_key",
    "notification_booking_notification_id_fkey", "notification_booking_booking_id_fkey",
}  # fmt: skip

INDEX_PREDICATES = {
    "device_token_active": "WHERE active",
    "device_user": "WHERE active",
    "recovery_link_by_user": "(user_id, created_at)",
    "notification_cancellation_unique": "WHERE (kind = 'user_cancellation'::text)",
    "notification_forced_unread": "WHERE ((kind = 'forced_cancellation'::text)",
    "notification_to_dispatch": "WHERE ((delivery = 'pending'::text) AND (kind <> 'reminder'::text)",
    "notification_by_replaced_by": "WHERE (replaced_by IS NOT NULL)",
    "notification_five_minute_reminder_unique": "WHERE (kind = 'five_minute_reminder'::text)",
    "notification_reminder_unique": "WHERE (kind = 'reminder'::text)",
    "notification_user": "(user_id, created_at DESC)",
    "booking_active_starts_at": "WHERE (status = 'active'::text)",
    "booking_by_canceled_by": "WHERE (canceled_by IS NOT NULL)",
    "booking_by_starts_at": "(starts_at DESC, id DESC)",
    "booking_by_user_starts_at": "(user_id, starts_at DESC, id DESC)",
    "venue_name_active_unique": "(lower(name)) WHERE active",
    "app_user_email_unique": "(lower(email)) WHERE active",
    "app_user_dni_unique": "(dni) WHERE active",
}

FUNCTIONS = {"touch_updated_at", "forbid_delete", "email_immutable", "space_identity_immutable",
             "uuid_v7"}  # fmt: skip
TRIGGERS = {
    "outgoing_email_updated", "device_updated", "recovery_link_updated", "space_updated",
    "space_name_immutable", "space_no_delete", "notification_updated",
    "notification_booking_updated", "booking_updated", "booking_no_delete", "venue_updated",
    "venue_no_delete", "app_user_email_immutable", "app_user_updated", "app_user_no_delete",
}  # fmt: skip


def _at_head(base_propia: Base) -> Engine:  # noqa: F811
    base, alembic = base_propia
    command.upgrade(alembic, "head")
    return base


def _names(base: Engine, sql: str) -> set[str]:
    with base.connect() as conn:
        return {row[0] for row in conn.execute(text(sql))}


def test_every_table_is_named_in_english(base_propia: Base) -> None:  # noqa: F811
    """every table is named in English after the migration @ENG-17-S1"""
    base = _at_head(base_propia)

    tables = _names(
        base,
        "SELECT table_name FROM information_schema.tables"
        " WHERE table_schema = 'public' AND table_type = 'BASE TABLE'",
    )

    assert tables == TABLES


def test_every_column_is_named_in_english(base_propia: Base) -> None:  # noqa: F811
    """every column is named in English after the migration @ENG-17-S1"""
    base = _at_head(base_propia)

    with base.connect() as conn:
        rows = conn.execute(
            text(
                "SELECT table_name, column_name FROM information_schema.columns"
                " WHERE table_schema = 'public' AND table_name IN"
                " (SELECT table_name FROM information_schema.tables WHERE table_type = 'BASE TABLE')"
            )
        ).all()

    found: dict[str, set[str]] = {}
    for table, column in rows:
        found.setdefault(table, set()).add(column)
    assert found == COLUMNS


def _seed_english(conn: Connection) -> dict[str, Any]:
    user = conn.execute(
        text(
            "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni, birth_date)"
            " VALUES ('uid-ana', 'ana@club.com', 'Ana', 'Rios', '30111222', '1990-01-01')"
            " RETURNING id"
        )
    ).scalar_one()
    venue = conn.execute(
        text(
            "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
            " VALUES ('Sede Haedo', 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
            " RETURNING id"
        )
    ).scalar_one()
    space = conn.execute(
        text(
            "INSERT INTO space (venue_id, sport, kind, number, name, covered, lit, price_per_hour)"
            " VALUES (:v, 'Futbol', 'F5', 1, 'Haedo_Vergara_1850_Futbol_F5_1', false, true, 38000)"
            " RETURNING id"
        ),
        {"v": venue},
    ).scalar_one()
    return {"user": user, "venue": venue, "space": space}


def _book(conn: Connection, ids: dict[str, Any], day: int, status: str = "active") -> Any:
    reason = "mantenimiento" if status == "voided" else None
    return conn.execute(
        text(
            "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total,"
            " status, reason) SELECT :u, :s, h, h + interval '1 hour', 38000, 38000, :st, :r"
            " FROM (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
            " + make_interval(days => :d) AS h) AS t RETURNING id"
        ),
        {"u": ids["user"], "s": ids["space"], "d": day, "st": status, "r": reason},
    ).scalar_one()


def _rejected(base: Engine, sql: str, params: dict[str, Any] | None = None) -> str:
    with pytest.raises(IntegrityError) as caught, base.begin() as conn:
        conn.execute(text(sql), params or {})
    return str(caught.value.orig.sqlstate)  # type: ignore[union-attr]


def test_every_stored_value_is_in_english_and_the_old_ones_are_rejected(
    base_propia: Base,  # noqa: F811
) -> None:
    """every stored text value is in English and the old ones are rejected @ENG-17-S1 @assumption:ENG-17-ASM-02"""
    base = _at_head(base_propia)
    with base.begin() as conn:
        ids = _seed_english(conn)
        _book(conn, ids, 1)
        _book(conn, ids, 2, "canceled")
        _book(conn, ids, 3, "voided")
        for kind in ("reminder", "five_minute_reminder"):
            conn.execute(
                text(
                    "INSERT INTO notification (user_id, kind, title, body, booking_id,"
                    " booking_starts_at, delivery) SELECT :u, :k, 't', 'b', id, starts_at, 'pending'"
                    " FROM booking WHERE status = 'active'"
                ),
                {"u": ids["user"], "k": kind},
            )
        defaults = conn.execute(
            text("SELECT (SELECT role FROM app_user), (SELECT min(status) FROM booking)")
        ).one()
    assert defaults == ("user", "active")

    assert _rejected(base, "UPDATE booking SET status = 'activa'") == "23514"
    assert _rejected(base, "UPDATE app_user SET role = 'usuario'") == "23514"
    assert _rejected(base, "UPDATE notification SET delivery = 'pendiente'") == "23514"
    assert _rejected(base, "UPDATE notification SET kind = 'recordatorio_cinco'") == "23514"
    assert _rejected(base, "UPDATE notification SET delivery = 'no_permission', kind = 'x'") == "23514"
    for delivery in ("sending", "sent", "no_permission", "no_channel", "failed"):
        with base.begin() as conn:
            conn.execute(text("UPDATE notification SET delivery = :d"), {"d": delivery})


def test_every_named_constraint_is_in_english(base_propia: Base) -> None:  # noqa: F811
    """every named constraint is in English @ENG-17-S1 @assumption:ENG-17-ASM-03"""
    base = _at_head(base_propia)

    names = _names(
        base,
        "SELECT conname FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace"
        " WHERE n.nspname = 'public'",
    )

    assert names == CONSTRAINTS


def test_every_partial_index_is_in_english_and_filters_on_the_english_value(
    base_propia: Base,  # noqa: F811
) -> None:
    """every partial index is in English and filters on the English value @ENG-17-S1"""
    base = _at_head(base_propia)

    with base.connect() as conn:
        found = dict(
            conn.execute(
                text(
                    "SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = 'public'"
                    " AND indexname NOT IN (SELECT conname FROM pg_constraint)"
                )
            ).all()
        )

    assert set(found) == set(INDEX_PREDICATES)
    for name, fragment in INDEX_PREDICATES.items():
        assert fragment in found[name], name


def test_every_function_and_trigger_is_in_english_and_keeps_its_behavior(
    base_propia: Base,  # noqa: F811
) -> None:
    """every function and trigger is in English and keeps its behavior @ENG-17-S1 @assumption:ENG-17-ASM-04"""
    base = _at_head(base_propia)
    assert _names(
        base,
        "SELECT proname FROM pg_proc p JOIN pg_language l ON l.oid = p.prolang"
        " WHERE pronamespace = 'public'::regnamespace AND l.lanname = 'plpgsql'",
    ) == FUNCTIONS
    assert _names(base, "SELECT tgname FROM pg_trigger WHERE NOT tgisinternal") == TRIGGERS
    with base.begin() as conn:
        ids = _seed_english(conn)
        booking = _book(conn, ids, 1)

    assert _rejected(base, "UPDATE space SET name = 'otro'") == "23514"
    assert _rejected(base, "UPDATE app_user SET email = 'otra@club.com'") == "23514"
    assert _rejected(base, "DELETE FROM booking") == "23001"
    with base.begin() as conn:
        before = conn.execute(text("SELECT created_at, updated_at FROM venue")).one()
        conn.execute(text("UPDATE venue SET created_at = now() + interval '1 day', street = 'X'"))
        after = conn.execute(text("SELECT created_at, updated_at FROM venue")).one()
        generated = conn.execute(text("SELECT uuid_v7()::text")).scalar_one()
    assert after[0] == before[0] and after[1] > before[1]
    assert generated[14] == "7" and booking is not None


def test_the_view_is_booking_with_status_and_computes_completed(
    base_propia: Base,  # noqa: F811
) -> None:
    """the view is booking_with_status and computes completed @ENG-17-S1"""
    base = _at_head(base_propia)
    with base.begin() as conn:
        ids = _seed_english(conn)
        _book(conn, ids, -3)
        _book(conn, ids, 2)
        _book(conn, ids, 3, "canceled")

    with base.connect() as conn:
        columns = [
            row[0]
            for row in conn.execute(
                text(
                    "SELECT column_name FROM information_schema.columns"
                    " WHERE table_name = 'booking_with_status' ORDER BY ordinal_position"
                )
            )
        ]
        statuses = conn.execute(
            text("SELECT status, current_status FROM booking_with_status ORDER BY starts_at")
        ).all()
        views = {r[0] for r in conn.execute(text("SELECT viewname FROM pg_views WHERE schemaname='public'"))}

    assert views == {"booking_with_status"}
    assert columns[-1] == "current_status"
    assert set(columns[:-1]) == COLUMNS["booking"]
    assert statuses == [("active", "completed"), ("active", "active"), ("canceled", "canceled")]


def test_the_double_booking_exclusion_rejects_two_overlapping_active_bookings(
    base_propia: Base,  # noqa: F811
) -> None:
    """the double-booking exclusion rejects two overlapping active bookings after the migration @ENG-17-S2"""
    base = _at_head(base_propia)
    with base.begin() as conn:
        ids = _seed_english(conn)
        _book(conn, ids, 1)

    with pytest.raises(IntegrityError) as caught, base.begin() as conn:
        _book(conn, ids, 1)

    assert caught.value.orig.sqlstate == "23P01"  # type: ignore[union-attr]
    assert "booking_space_id_tstzrange_excl" in str(caught.value.orig)


def test_a_canceled_booking_overlapping_an_active_one_is_accepted(
    base_propia: Base,  # noqa: F811
) -> None:
    """a canceled booking overlapping an active one is accepted after the migration @ENG-17-S2"""
    base = _at_head(base_propia)
    with base.begin() as conn:
        ids = _seed_english(conn)
        _book(conn, ids, 1)
        _book(conn, ids, 1, "canceled")
        _book(conn, ids, 1, "canceled")

    with base.connect() as conn:
        count = conn.execute(text("SELECT count(*) FROM booking")).scalar_one()
    assert count == 3


def _seed_spanish(base: Engine) -> None:
    with base.begin() as conn:
        for uid, correo, dni, rol in (("a", "ana@club.com", "30111222", "usuario"),
                                      ("b", "root@club.com", "30111223", "admin")):  # fmt: skip
            conn.execute(
                text(
                    "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni,"
                    " fecha_nacimiento, rol) VALUES (:u, :c, 'Ana', 'Rios', :d, '1990-01-01', :r)"
                ),
                {"u": uid, "c": correo, "d": dni, "r": rol},
            )
        conn.execute(
            text(
                "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES ('Sede Haedo', 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
            )
        )
        conn.execute(
            text(
                "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada, iluminada,"
                " precio_por_hora) SELECT id, 'Futbol', 'F5', 1, 'Haedo_1', false, true, 38000"
                " FROM sede"
            )
        )
        for dia, estado in ((1, "activa"), (2, "cancelada"), (3, "anulada")):
            conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    " total, estado, motivo) SELECT u.id, e.id, h, h + interval '1 hour', 38000,"
                    " 38000, :e, CASE WHEN :e = 'anulada' THEN 'mantenimiento' END"
                    " FROM (SELECT id FROM usuario WHERE rol = 'usuario') u, espacio e,"
                    " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
                    " + make_interval(days => :d) AS h) t"
                ),
                {"e": estado, "d": dia},
            )
        _seed_spanish_notifications(conn)
        conn.execute(
            text("INSERT INTO correo_saliente (para, asunto, cuerpo) VALUES ('a@b.com','s','c')")
        )
        conn.execute(
            text(
                "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
                " SELECT id, 'tok', 'ios', true FROM usuario WHERE rol = 'usuario'"
            )
        )


def _seed_spanish_notifications(conn: Connection) -> None:
    with_booking = (
        ("recordatorio", "pendiente", "activa"), ("recordatorio_cinco", "enviada", "activa"),
        ("cancelacion_usuario", "fallida", "cancelada"),
    )  # fmt: skip
    for tipo, envio, estado in with_booking:
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                " reserva_inicio, envio) SELECT u.id, :t, 'Título', 'Cuerpo', r.id,"
                " CASE WHEN :t LIKE 'recordatorio%' THEN r.inicio END, :e"
                " FROM usuario u, reserva r WHERE u.rol = 'usuario' AND r.estado = :s"
            ),
            {"t": tipo, "e": envio, "s": estado},
        )
    for envio in ("sin_permiso", "sin_canal", "enviando"):
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio)"
                " SELECT id, 'cancelacion_forzosa', 'Título', 'Cuerpo', :e FROM usuario"
                " WHERE rol = 'usuario'"
            ),
            {"e": envio},
        )


def _stored(base: Engine, spanish: bool) -> dict[str, Any]:
    names = (
        ("usuario", "rol", "reserva", "estado", "notificacion", "tipo", "envio", "modificado_en")
        if spanish
        else ("app_user", "role", "booking", "status", "notification", "kind", "delivery",
              "updated_at")
    )  # fmt: skip
    user, role, booking, status, notification, kind, delivery, updated = names
    with base.connect() as conn:
        tally = lambda t, c: sorted(  # noqa: E731
            conn.execute(text(f"SELECT {c}, count(*) FROM {t} GROUP BY {c}")).all()
        )
        counts = {
            t: conn.execute(text(f"SELECT count(*) FROM {t}")).scalar_one()
            for t in (user, booking, notification)
        }
        stamps = [
            sorted(conn.execute(text(f"SELECT id, {updated} FROM {t}")).all())
            for t in (user, booking, notification)
        ]
        return {
            "counts": counts, "roles": tally(user, role), "status": tally(booking, status),
            "kind": tally(notification, kind), "delivery": tally(notification, delivery),
            "stamps": stamps,
        }  # fmt: skip


TRANSLATED = {
    "usuario": "user", "activa": "active", "cancelada": "canceled", "anulada": "voided",
    "recordatorio": "reminder", "recordatorio_cinco": "five_minute_reminder",
    "cancelacion_forzosa": "forced_cancellation", "cancelacion_usuario": "user_cancellation",
    "pendiente": "pending", "enviando": "sending", "enviada": "sent",
    "sin_permiso": "no_permission", "sin_canal": "no_channel", "fallida": "failed",
}  # fmt: skip


def _english_tally(rows: list[Any]) -> list[Any]:
    return sorted((TRANSLATED.get(value, value), count) for value, count in rows)


def test_the_migration_translates_the_rows_of_0011_without_touching_them_otherwise(
    base_propia: Base,  # noqa: F811
) -> None:
    """the migration translates the rows of 0011 without touching them otherwise and goes back to 0011 @ENG-17-S1 @assumption:ENG-17-ASM-05 @assumption:ENG-17-ASM-06"""
    base, alembic = base_propia
    command.upgrade(alembic, "0011")
    _seed_spanish(base)
    before = _stored(base, spanish=True)
    with base.connect() as conn:
        content = conn.execute(
            text("SELECT titulo, cuerpo FROM notificacion ORDER BY id")
        ).all()

    command.upgrade(alembic, "head")

    after = _stored(base, spanish=False)
    assert after["counts"] == before["counts"]
    assert after["stamps"] == before["stamps"]
    for key in ("roles", "status", "kind", "delivery"):
        assert after[key] == _english_tally(before[key]), key
    with base.connect() as conn:
        assert conn.execute(
            text("SELECT title, body FROM notification ORDER BY id")
        ).all() == content
        assert conn.execute(text("SELECT first_name FROM app_user LIMIT 1")).scalar_one() == "Ana"
    command.downgrade(alembic, "0011")
    assert _stored(base, spanish=True) == before


OLD_TO_NEW_TABLE = {
    "usuario": "app_user", "sede": "venue", "espacio": "space", "reserva": "booking",
    "enlace_recuperacion": "recovery_link", "correo_saliente": "outgoing_email",
    "dispositivo": "device", "notificacion": "notification",
    "notificacion_reserva": "notification_booking", "alembic_version": "alembic_version",
}  # fmt: skip
FUNCTION_MAP = {
    "marcar_modificado": "touch_updated_at", "prohibir_borrado": "forbid_delete",
    "correo_inmutable": "email_immutable", "nombre_espacio_inmutable": "space_identity_immutable",
}  # fmt: skip
SHARED_COLUMNS = {
    "creado_en": "created_at", "modificado_en": "updated_at", "activo": "active",
    "activa": "active", "dado_de_baja_en": "deactivated_at", "dado_de_baja_por": "deactivated_by",
    "creado_por": "created_by", "modificado_por": "updated_by", "usuario_id": "user_id",
    "reserva_id": "booking_id", "precio_por_hora": "price_per_hour", "cuerpo": "body",
}  # fmt: skip
OWN_COLUMNS = {
    "usuario": {"correo": "email", "nombre": "first_name", "apellido": "last_name",
                "fecha_nacimiento": "birth_date", "rol": "role",
                "contrasena_cambiada_en": "password_changed_at"},
    "sede": {"nombre": "name", "calle": "street", "altura": "street_number",
             "apertura": "opens_at", "cierre": "closes_at", "dias": "open_days"},
    "espacio": {"sede_id": "venue_id", "deporte": "sport", "tipo": "kind", "numero": "number",
                "nombre": "name", "techada": "covered", "iluminada": "lit"},
    "reserva": {"espacio_id": "space_id", "inicio": "starts_at", "fin": "ends_at",
                "estado": "status", "cancelada_en": "canceled_at", "cancelada_por": "canceled_by",
                "motivo": "reason"},
    "enlace_recuperacion": {"codigo_hash": "code_hash", "vence_en": "expires_at",
                            "usado_en": "used_at", "invalidado_en": "invalidated_at"},
    "correo_saliente": {"para": "recipient", "asunto": "subject"},
    "dispositivo": {"plataforma": "platform", "permiso": "permission_granted"},
    "notificacion": {"tipo": "kind", "titulo": "title", "reserva_inicio": "booking_starts_at",
                     "envio": "delivery", "enviada_en": "sent_at", "leida_en": "read_at",
                     "reemplazada_por": "replaced_by", "cantidad": "count",
                     "enviando_desde": "sending_since"},
    "notificacion_reserva": {"notificacion_id": "notification_id"},
    "alembic_version": {},
}  # fmt: skip


def _to_english(table: str, sql: str) -> str:
    """The 0011 text of a definition of `table` with each name and value as 0012 spells it."""
    sql = sql.replace("public.", "")
    sql = re.sub(r"'(\w+)'", lambda m: f"'{TRANSLATED.get(m[1], m[1])}'", sql)
    words = {**OLD_TO_NEW_TABLE, **FUNCTION_MAP, **SHARED_COLUMNS, **OWN_COLUMNS[table]}
    return re.sub(r"(?<!')\b\w+\b(?!')", lambda m: words.get(m[0], m[0]), sql)


def _catalog(base: Engine) -> dict[str, set[tuple[str, ...]]]:
    """Definitions without their names: constraints, indexes, triggers, columns, functions."""
    with base.connect() as conn:
        rows = lambda sql: conn.execute(text(sql)).all()  # noqa: E731
        constraints = {
            (t, k, d)
            for t, k, d in rows(
                "SELECT c.conrelid::regclass::text, c.contype::text, pg_get_constraintdef(c.oid)"
                " FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace"
                " WHERE n.nspname = 'public'"
            )
        }
        indexes = {
            (t, re.sub(r"^CREATE (UNIQUE )?INDEX \w+ ON \S+ ", r"\1", d))
            for t, d in rows(
                "SELECT tablename, indexdef FROM pg_indexes WHERE schemaname = 'public'"
                " AND indexname NOT IN (SELECT conname FROM pg_constraint)"
            )
        }
        triggers = {
            (t, re.sub(r"^CREATE TRIGGER \w+ ", "", d).replace("public.", ""))
            for t, d in rows(
                "SELECT c.relname, pg_get_triggerdef(t.oid) FROM pg_trigger t"
                " JOIN pg_class c ON c.oid = t.tgrelid WHERE NOT t.tgisinternal"
            )
        }
        columns = {
            tuple(map(str, r))
            for r in rows(
                "SELECT table_name, column_name, data_type, is_nullable, column_default"
                " FROM information_schema.columns WHERE table_schema = 'public' AND table_name IN"
                " (SELECT table_name FROM information_schema.tables WHERE table_type = 'BASE TABLE')"
            )
        }
        functions = {
            (n,)
            for (n,) in rows(
                "SELECT proname FROM pg_proc p JOIN pg_language l ON l.oid = p.prolang"
                " WHERE pronamespace = 'public'::regnamespace AND l.lanname = 'plpgsql'"
            )
        }
    return {
        "constraints": constraints, "indexes": indexes, "triggers": triggers,
        "columns": columns, "functions": functions,
    }  # fmt: skip


def _translated(old: dict[str, set[tuple[str, ...]]]) -> dict[str, set[tuple[str, ...]]]:
    out: dict[str, set[tuple[str, ...]]] = {}
    for key, entries in old.items():
        out[key] = set()
        for entry in entries:
            if key == "functions":
                out[key].add((FUNCTION_MAP.get(entry[0], entry[0]),))
            elif key == "columns":
                table = entry[0]
                column = {**SHARED_COLUMNS, **OWN_COLUMNS[table]}.get(entry[1], entry[1])
                default = _to_english(table, entry[4]) if entry[4] != "None" else "None"
                out[key].add((OLD_TO_NEW_TABLE[table], column, entry[2], entry[3], default))
            else:
                table = entry[0]
                out[key].add(
                    (OLD_TO_NEW_TABLE[table], *(_to_english(table, p) for p in entry[1:]))
                )
    return out


def test_the_schema_of_0012_keeps_every_constraint_index_trigger_and_function_of_0011(
    base_propia: Base,  # noqa: F811
) -> None:
    """the schema of 0012 keeps every constraint, index, trigger and function of 0011 @ENG-17-S7"""
    base, alembic = base_propia
    command.upgrade(alembic, "0011")
    old = _catalog(base)
    command.upgrade(alembic, "head")
    new = _catalog(base)
    command.downgrade(alembic, "0011")
    back = _catalog(base)

    expected = _translated(old)
    for key in expected:
        assert new[key] == expected[key], key
    assert back == old


def test_the_migration_gives_up_on_a_held_lock_and_can_run_again(
    base_propia: Base,  # noqa: F811
) -> None:
    """the migration gives up on a held lock and can run again @assumption:ENG-17-ASM-07"""
    base, alembic = base_propia
    command.upgrade(alembic, "0011")
    holder = base.connect()
    holder.execute(text("LOCK TABLE reserva IN ACCESS EXCLUSIVE MODE"))
    result: list[BaseException] = []
    runner: Callable[[], None] = lambda: _capturar(  # noqa: E731
        result, lambda: command.upgrade(alembic, "head")
    )
    thread = threading.Thread(target=runner)

    thread.start()
    thread.join(timeout=60)
    holder.rollback()
    holder.close()

    assert not thread.is_alive()
    assert isinstance(result[0], OperationalError)
    assert "lock timeout" in str(result[0])
    assert _names(base, "SELECT table_name FROM information_schema.tables"
                  " WHERE table_schema = 'public' AND table_name = 'reserva'") == {"reserva"}
    command.upgrade(alembic, "head")
    assert "booking" in _names(
        base, "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
    )
