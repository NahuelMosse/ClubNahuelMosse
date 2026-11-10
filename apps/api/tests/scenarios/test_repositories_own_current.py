"""The reminder lead time is now one per notice kind (NOT-05), not a single constant."""

# ruff: noqa: E501  (the test titles carry their tag and are not split)
from datetime import timedelta
from uuid import UUID

import pytest
from sqlalchemy import Connection, Engine

from app.modules.notifications import repository
from app.modules.notifications.repository import NotificationsSql
from tests.scenarios.test_repositories_own import _hour, _world, _booking


def test_the_reminder_goes_out_one_hour_before(
    engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """the reminder goes out one hour before the start, with the domain lead time @REV-06-S9 @assumption:REV-06-ASM-08"""
    world = _world(engine)
    base = _hour(days=9)
    now = base - timedelta(minutes=50)
    created = base - timedelta(days=30)
    near = _booking(engine, world, base, created=created)
    far = _booking(engine, world, base + timedelta(hours=1), created=created)

    def ids(conn: Connection) -> list[UUID]:
        return [r.booking_id for r in NotificationsSql(conn).due(now, world["user"])]

    with engine.connect() as conn:
        assert ids(conn) == [near]
    monkeypatch.setitem(repository.LEAD_TIME_BY_KIND, "reminder", timedelta(hours=2))
    with engine.connect() as conn:
        assert ids(conn) == [near, far]
