import asyncio
import time

from starlette.types import ASGIApp, Message, Receive, Scope, Send

LIMIT_BYTES = 1024 * 1024
TIMEOUT_SECONDS = 5


class BodyLimit:
    """Cuts a body over 1 MB with 413 and one that does not arrive whole in 5 s with 408.

    When over the limit it answers itself and tells the app the client left: FastAPI turns
    any exception while reading the body into a 400, so it cannot be cut with one.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        declared = dict(scope["headers"]).get(b"content-length", b"")
        if declared.isdigit() and int(declared) > LIMIT_BYTES:
            await self._respond(send, 413)
            return

        deadline = time.monotonic() + TIMEOUT_SECONDS
        received = 0
        cut = False

        async def receive_limited() -> Message:
            nonlocal received, cut
            if cut:
                return {"type": "http.disconnect"}
            try:
                message = await asyncio.wait_for(receive(), deadline - time.monotonic())
            except TimeoutError:
                status = 408
            else:
                received += len(message.get("body", b""))
                if received <= LIMIT_BYTES:
                    return message
                status = 413
            cut = True
            await self._respond(send, status)
            return {"type": "http.disconnect"}

        async def send_unless_cut(message: Message) -> None:
            if not cut:
                await send(message)

        await self.app(scope, receive_limited, send_unless_cut)

    @staticmethod
    async def _respond(send: Send, status: int) -> None:
        await send(
            {
                "type": "http.response.start",
                "status": status,
                "headers": [(b"content-length", b"0"), (b"connection", b"close")],
            }
        )
        await send({"type": "http.response.body", "body": b""})
