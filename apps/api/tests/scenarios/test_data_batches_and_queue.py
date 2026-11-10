"""Data (continued): histories, indexes, notice queue and migration 0008.

The helpers and fixtures are those of test_data.py.
"""

import threading
from collections.abc import Callable
from typing import Any

from alembic import command
from alembic.config import Config as AlembicConfig
from fastapi.testclient import TestClient
from sqlalchemy import Engine, event, text
from test_data import (  # noqa: F401 — the fixtures are imported so that pytest sees them
    _sweep,
    _cancel,
    _capture,
    _dispatch,
    _tie,
    _deliveries,
    _past,
    _reminder,
    _strand,
    migrations_db,
    channel,
    member,
    admin_token,
)
from test_reminder import Member


def _member_ids(member: Member) -> set[str]:
    with member.engine.connect() as conn:
        return {
            str(f.id)
            for f in conn.execute(
                text("SELECT id FROM booking WHERE user_id = :u"), {"u": member.user_id}
            )
        }


def _history(member: Member, **params: str) -> dict[str, Any]:
    r = member.api.get("/bookings", headers=member.session, params={"when": "history", **params})
    assert r.status_code == 200
    body: dict[str, Any] = r.json()
    return body


def _capture_sql(action: Callable[[], None]) -> list[tuple[str, Any]]:
    """The statements the database receives while [action] runs."""
    seen: list[tuple[str, Any]] = []

    def listen(conn: Any, cursor: Any, statement: str, parameters: Any, *_: Any) -> None:
        seen.append((statement, parameters))

    event.listen(Engine, "before_cursor_execute", listen)
    try:
        action()
    finally:
        event.remove(Engine, "before_cursor_execute", listen)
    return seen


def test_the_total_and_the_counters_stay_exact_in_a_single_query(
    api: TestClient, member: Member, admin_token: str
) -> None:
    """the total and the counters of the global history stay exact, as CU-14 asks, in a single
    query @REV-03-S3 @assumption:REV-03-ASM-10
    """
    _past(member, 25)
    admin = {"Authorization": f"Bearer {admin_token}"}
    bodies: list[dict[str, Any]] = []

    statements = _capture_sql(
        lambda: bodies.append(
            api.get("/bookings/all", headers=admin, params={"q": member.venue}).json()
        )
    )

    assert bodies[0]["total"] == 25
    assert bodies[0]["counters"]["all"] == 25
    assert bodies[0]["counters"]["completed"] == 25
    assert len([s for s, _ in statements if "count(*)" in s.lower()]) == 1


def test_in_the_own_history_with_the_same_start_the_highest_id_comes_first(
    member: Member,
) -> None:
    """in the own history, with the same start the highest id comes first and all of them arrive
    @REV-03-S2
    """
    _past(member, 20)
    _tie(member)

    everything = _history(member)["bookings"]

    keys = [(r["starts_at"], r["id"]) for r in everything]
    assert keys == sorted(keys, reverse=True)
    assert {r["id"] for r in everything} == _member_ids(member)
    assert len(everything) == 21


def test_upcoming_bookings_keep_arriving_in_full(member: Member) -> None:
    """upcoming bookings keep arriving in full @REV-03-S2 @assumption:REV-03-ASM-16"""
    with member.engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, :e, h + make_interval(days => n), h + make_interval(days => n)"
                " + interval '1 hour', 38000, 38000 FROM generate_series(1, 25) AS n,"
                " (SELECT date_trunc('hour', now()) AS h) AS t"
            ),
            {"u": member.user_id, "e": member.space_id},
        )

    r = member.api.get("/bookings", headers=member.session, params={"cuando": "upcoming"}).json()

    assert len(r["bookings"]) == 25


def test_migration_0008_aborts_on_lock_timeout_and_can_be_run_again(
    migrations_db: tuple[Engine, AlembicConfig],
) -> None:
    """migration 0008 aborts on lock_timeout if a long transaction holds the table
    @REV-03-S7 @assumption:REV-03-ASM-15
    """
    db, alembic = migrations_db
    command.upgrade(alembic, "0007")
    lock = db.connect()
    lock.execute(text("LOCK TABLE notificacion IN ACCESS EXCLUSIVE MODE"))
    result: list[BaseException] = []
    thread = threading.Thread(
        target=lambda: _capture(result, lambda: command.upgrade(alembic, "0008"))
    )

    thread.start()
    thread.join(timeout=60)
    lock.rollback()
    lock.close()

    assert not thread.is_alive()
    assert "lock timeout" in str(result[0])
    with db.connect() as conn:
        version = conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
    assert version == "0007"
    command.upgrade(alembic, "0008")
