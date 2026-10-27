"""The sweep that sends reminders when their time comes, in the background."""

import argparse
import asyncio
import logging
import sys
from datetime import UTC, datetime
from uuid import UUID

from app.modules.notifications.push import push_channel
from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.use_cases import (
    PushChannel,
    dispatch_pending,
    send_reminders,
)
from app.shared.db import engine

_log = logging.getLogger(__name__)


def sweep_once() -> int:
    with engine().connect() as conn:
        notifications = NotificationsSql(conn)
        channel = push_channel()
        # What was registered with a fact and never went out, for example if the server
        # crashed right after cancelling. If it fails, the reminders still go out.
        try:
            dispatch_pending(notifications, channel)
        except Exception:
            _log.exception("el despacho de avisos pendientes falló")
        return send_reminders(notifications, channel, datetime.now(UTC))


def dispatch_for(user_id: UUID, channel: PushChannel) -> None:
    """Sends what is still pending for [user_id], on its own connection: it runs after the
    response has gone out. A failure here does not change what the person did; the sweep
    picks it up again."""
    try:
        with engine().connect() as conn:
            dispatch_pending(NotificationsSql(conn), channel, user_id)
    except Exception:
        _log.exception("el despacho de avisos falló")


def main(args: list[str] | None = None) -> int:
    """Runs one sweep and exits: a cron separate from the web service launches it, since the
    free plan sleeps."""
    parser = argparse.ArgumentParser(description="Manda los recordatorios que ya les toca.")
    parser.add_argument("--una-vez", action="store_true", required=True)
    parser.parse_args(args)
    logging.basicConfig(level=logging.INFO)
    try:
        sent = sweep_once()
    except Exception:
        _log.exception("barrido_fallido")
        return 1
    _log.info("barrido_ok recordatorios=%s", sent)
    return 0


async def sweep_every(seconds: int) -> None:
    while True:
        await asyncio.sleep(seconds)
        try:
            await asyncio.to_thread(sweep_once)
        except Exception:
            # A failing sweep (the database down for a moment) must not kill the next one.
            _log.exception("el barrido de recordatorios falló")


if __name__ == "__main__":
    sys.exit(main())
