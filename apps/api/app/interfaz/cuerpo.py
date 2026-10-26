import asyncio
import time

from starlette.types import ASGIApp, Message, Receive, Scope, Send

LIMITE_BYTES = 1024 * 1024
PLAZO_SEGUNDOS = 5


class CuerpoAcotado:
    """Corta con 413 un cuerpo de más de 1 MB y con 408 uno que no llega entero en 5 s.

    Al pasarse responde él mismo y le avisa a la app que el cliente se fue: FastAPI convierte
    cualquier excepción al leer el cuerpo en un 400, así que no se puede cortar con una.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        declarado = dict(scope["headers"]).get(b"content-length", b"")
        if declarado.isdigit() and int(declarado) > LIMITE_BYTES:
            await self._responder(send, 413)
            return

        limite = time.monotonic() + PLAZO_SEGUNDOS
        recibidos = 0
        cortado = False

        async def recibir() -> Message:
            nonlocal recibidos, cortado
            if cortado:
                return {"type": "http.disconnect"}
            try:
                mensaje = await asyncio.wait_for(receive(), limite - time.monotonic())
            except TimeoutError:
                estado = 408
            else:
                recibidos += len(mensaje.get("body", b""))
                if recibidos <= LIMITE_BYTES:
                    return mensaje
                estado = 413
            cortado = True
            await self._responder(send, estado)
            return {"type": "http.disconnect"}

        async def enviar(mensaje: Message) -> None:
            if not cortado:
                await send(mensaje)

        await self.app(scope, recibir, enviar)

    @staticmethod
    async def _responder(send: Send, estado: int) -> None:
        await send(
            {
                "type": "http.response.start",
                "status": estado,
                "headers": [(b"content-length", b"0"), (b"connection", b"close")],
            }
        )
        await send({"type": "http.response.body", "body": b""})
