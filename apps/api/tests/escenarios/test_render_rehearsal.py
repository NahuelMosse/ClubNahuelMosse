"""Rehearsal of revision 0012 on a restored dump of the Render database (revision 0011).

The dump and the connection string live outside the repo; this test reads the target from
ENG17_REHEARSAL_URL and compares only counts and tallies per value, never rows.
"""

import os
import subprocess
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config as AlembicConfig
from sqlalchemy import create_engine, text

API_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = API_ROOT.parents[1]
TABLES = {
    "usuario": "app_user", "sede": "venue", "espacio": "space", "reserva": "booking",
    "enlace_recuperacion": "recovery_link", "correo_saliente": "outgoing_email",
    "dispositivo": "device", "notificacion": "notification",
    "notificacion_reserva": "notification_booking",
}  # fmt: skip
TALLIES = {  # table, column (0011) -> table, column (0012), value map
    ("reserva", "estado"): ("booking", "status",
                            {"activa": "active", "cancelada": "canceled", "anulada": "voided"}),
    ("usuario", "rol"): ("app_user", "role", {"usuario": "user", "admin": "admin"}),
    ("notificacion", "tipo"): ("notification", "kind", {
        "recordatorio": "reminder", "recordatorio_cinco": "five_minute_reminder",
        "cancelacion_forzosa": "forced_cancellation", "cancelacion_usuario": "user_cancellation"}),
    ("notificacion", "envio"): ("notification", "delivery", {
        "pendiente": "pending", "enviando": "sending", "enviada": "sent",
        "sin_permiso": "no_permission", "sin_canal": "no_channel", "fallida": "failed"}),
}  # fmt: skip


def _target_url() -> str:
    url = os.environ.get("ENG17_REHEARSAL_URL")
    if url:
        return url
    if os.environ.get("ENG17_REHEARSAL_REQUIRED") == "1":
        pytest.fail("ENG17_REHEARSAL_URL is not set and the rehearsal is required")
    pytest.skip("ENG17_REHEARSAL_URL is not set")


def _counts(engine, tables: list[str]) -> dict[str, int]:  # type: ignore[no-untyped-def]
    with engine.connect() as conn:
        return {t: conn.execute(text(f"SELECT count(*) FROM {t}")).scalar_one() for t in tables}


def _tally(engine, table: str, column: str) -> dict[str, int]:  # type: ignore[no-untyped-def]
    with engine.connect() as conn:
        rows = conn.execute(text(f"SELECT {column}, count(*) FROM {table} GROUP BY {column}"))
        return {value: count for value, count in rows}


def test_the_migration_runs_on_the_render_dump_translates_every_row_and_goes_back() -> None:
    """the migration runs on the Render dump, translates every row and goes back @ENG-17-S6"""
    url = _target_url()
    engine = create_engine(url)
    alembic = AlembicConfig(str(API_ROOT / "alembic.ini"))
    alembic.set_main_option("sqlalchemy.url", url.replace("%", "%%"))
    with engine.connect() as conn:
        assert conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one() == "0011"
    before_counts = _counts(engine, list(TABLES))
    before = {key: _tally(engine, *key) for key in TALLIES}
    assert sum(before_counts.values()) > 0

    command.upgrade(alembic, "head")

    assert _counts(engine, list(TABLES.values())) == {
        TABLES[t]: n for t, n in before_counts.items()
    }
    for (table, column), (new_table, new_column, values) in TALLIES.items():
        translated = {values[v]: n for v, n in before[(table, column)].items()}
        assert _tally(engine, new_table, new_column) == translated, (table, column)
    command.downgrade(alembic, "0011")
    assert _counts(engine, list(TABLES)) == before_counts
    assert {key: _tally(engine, *key) for key in TALLIES} == before
    engine.dispose()


def test_no_versioned_file_holds_the_render_connection_string() -> None:
    """no versioned file holds the Render connection string @assumption:ENG-17-ASM-09"""
    files = subprocess.run(
        ["git", "ls-files"], cwd=REPO_ROOT, capture_output=True, text=True, check=True
    ).stdout.split("\n")
    leaking = [
        name
        for name in files
        if name and Path(REPO_ROOT, name).is_file()
        and not name.endswith((".png", ".jpg", ".pdf", ".ttf", ".otf", ".ico", ".webp"))
        and "dpg-" in Path(REPO_ROOT, name).read_text(encoding="utf-8", errors="ignore")
    ]

    assert leaking == []
