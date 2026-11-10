"""The grouping of voiding notices: traceability per booking, new id and concurrency."""

import threading
import time
from collections.abc import Callable, Sequence
from typing import Any
from uuid import UUID

import pytest
import test_forced_cancellation as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, a_member

from app.modules.notifications.repository import NotificationsSql, enqueue_forced_cancellation

admin = base.admin
channel = base.channel


def _void_in_the_database(
    engine: Engine, member: Member, bookings: Sequence[dict[str, Any]]
) -> None:
    with engine.begin() as conn:
        for r in bookings:
            conn.execute(
                text(
                    "UPDATE booking SET status = 'voided', reason = 'Baja de la sede',"
                    " canceled_at = now(), canceled_by = :u WHERE id = :id"
                ),
                {"u": member.user_id, "id": r["id"]},
            )


def _notices(engine: Engine, member: Member) -> list[Any]:
    with engine.connect() as conn:
        return list(
            conn.execute(
                text(
                    "SELECT id, title, count, replaced_by, delivery, sent_at"
                    " FROM notification WHERE user_id = :u ORDER BY id"
                ),
                {"u": member.user_id},
            )
        )


def _in_parallel(engine: Engine, user_id: UUID, batches: Sequence[Sequence[UUID]]) -> None:
    """Queues the first batch and, with its transaction still open, the second, which has to
    wait for the first to finish."""
    first_inside, release = threading.Event(), threading.Event()
    errors: list[BaseException] = []

    def first() -> None:
        try:
            with engine.begin() as conn:
                enqueue_forced_cancellation(conn, user_id, batches[0])
                first_inside.set()
                release.wait(10)
        except BaseException as e:
            errors.append(e)
            first_inside.set()

    def second() -> None:
        try:
            first_inside.wait(10)
            with engine.begin() as conn:
                enqueue_forced_cancellation(conn, user_id, batches[1])
        except BaseException as e:
            errors.append(e)

    threads = [threading.Thread(target=first), threading.Thread(target=second)]
    for t in threads:
        t.start()
    first_inside.wait(10)
    time.sleep(0.5)
    waiting = threads[1].is_alive()
    release.set()
    for t in threads:
        t.join(10)
    assert errors == []
    assert waiting, "the second voiding did not wait for the first"


def test_grouping_opens_a_new_notice_and_each_booking_keeps_the_sending_of_its_own(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """the grouped notice has a new id and the traceability of each booking does not change @assumption:CU-24.2-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    first = member.book("20:00")
    second = member.book("21:00")
    assert base.force_cancel(member, admin, first) == 200
    [before] = member.center()["notifications"]
    traceability = base.for_admin(member, admin, first["id"])

    assert base.force_cancel(member, admin, second) == 200

    [after] = member.center()["notifications"]
    assert after["id"] != before["id"]
    assert after["title"] == "The club voided 2 of your bookings"
    assert base.for_admin(member, admin, first["id"])["notice_at"] == traceability["notice_at"]
    assert base.for_admin(member, admin, second["id"])["notice_delivery"] == "sent"
    previous, new = _notices(engine, member)
    assert previous.replaced_by == new.id
    assert previous.sent_at < new.sent_at


def test_a_notice_that_did_not_go_out_passes_its_bookings_to_the_one_that_replaces_it(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """what is grouped before going out is reported in the notice that goes out @assumption:CU-24.2-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    bookings = [member.book("20:00"), member.book("21:00")]
    _void_in_the_database(engine, member, bookings)
    with engine.begin() as conn:
        enqueue_forced_cancellation(conn, member.user_id, [UUID(bookings[0]["id"])])
    with engine.begin() as conn:
        enqueue_forced_cancellation(conn, member.user_id, [UUID(bookings[1]["id"])])

    with engine.connect() as conn:
        links = conn.execute(
            text("SELECT notification_id FROM notification_booking WHERE booking_id = ANY(:ids)"),
            {"ids": [UUID(r["id"]) for r in bookings]},
        ).all()
    *_, new = _notices(engine, member)
    assert {v.notification_id for v in links} == {new.id}


@pytest.mark.parametrize("with_previous_notice", [False, True])
def test_two_simultaneous_voidings_leave_the_count_and_a_single_visible_notice(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
    with_previous_notice: bool,
) -> None:
    """the voidings of the same person are serialized @assumption:CU-24.2-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    bookings = [member.book("20:00"), member.book("21:00"), member.book("22:00")]
    if with_previous_notice:
        assert base.force_cancel(member, admin, bookings[0]) == 200
        simultaneous = bookings[1:]
    else:
        simultaneous = bookings[:2]
        _void_in_the_database(engine, member, simultaneous)
    total = len(simultaneous) + int(with_previous_notice)
    if with_previous_notice:
        _void_in_the_database(engine, member, simultaneous)

    _in_parallel(
        engine, member.user_id, [[UUID(simultaneous[0]["id"])], [UUID(simultaneous[1]["id"])]]
    )

    [visible] = member.center()["notifications"]
    assert visible["title"] == f"The club voided {total} of your bookings"
    not_replaced = [a for a in _notices(engine, member) if a.replaced_by is None]
    assert [a.count for a in not_replaced] == [total]
    with engine.connect() as conn:
        linked: Any = conn.execute(
            text(
                "SELECT count(*) FROM notification_booking nr JOIN notification n"
                " ON n.id = nr.notification_id WHERE n.user_id = :u"
            ),
            {"u": member.user_id},
        ).scalar_one()
    assert linked == total


def test_a_notice_read_while_grouping_does_not_swallow_the_new_voiding(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """reading the previous notice in the middle of the grouping leaves the new one unread @assumption:CU-24.2-SUP-02"""
    member = a_member(api, engine, sign_in, unique)
    first = member.book("20:00")
    second = member.book("21:00")
    assert base.force_cancel(member, admin, first) == 200
    [read] = member.center()["notifications"]
    _void_in_the_database(engine, member, [second])

    def reading() -> None:
        with engine.connect() as conn:
            NotificationsSql(conn).read(member.user_id, UUID(read["id"]))

    reader = threading.Thread(target=reading)

    first_inside, release = threading.Event(), threading.Event()

    def queueing() -> None:
        with engine.begin() as conn:
            enqueue_forced_cancellation(conn, member.user_id, [UUID(second["id"])])
            first_inside.set()
            release.wait(10)

    thread = threading.Thread(target=queueing)
    thread.start()
    first_inside.wait(10)
    reader.start()
    time.sleep(0.5)
    release.set()
    thread.join(10)
    reader.join(10)

    center = member.center()
    assert center["unread"] == 1
    [entry] = center["notifications"]
    assert entry["title"] == "The club voided 2 of your bookings"
    assert entry["read"] is False


def test_the_dispatch_takes_the_pending_ones_through_a_partial_index(engine: Engine) -> None:
    """the dispatch query has its index"""
    with engine.connect() as conn:
        definition: Any = conn.execute(
            text("SELECT indexdef FROM pg_indexes WHERE indexname = 'notification_to_dispatch'")
        ).scalar_one()
    assert "delivery = 'pending'" in definition
    assert "kind <> 'reminder'" in definition
