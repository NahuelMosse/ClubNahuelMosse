from starlette.exceptions import HTTPException
from starlette.types import ASGIApp, Message, Receive, Scope, Send

LIMITE_CUERPO = 64 * 1024
_SEGURIDAD = [(b"cache-control", b"no-store"), (b"x-content-type-options", b"nosniff")]


class Protecciones:
    """Rechaza cuerpos de más de 64 KB y marca todas las respuestas como no cacheables.

    El tamaño se controla por lo que declara `Content-Length`, antes de leer un byte, y
    también mientras se lee, para el cuerpo que llega por partes sin declararlo.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        declarado = dict(scope["headers"]).get(b"content-length")
        if declarado is not None:
            if not declarado.isdigit():
                await _responder(send, 400, b'{"detail":"Content-Length invalido"}')
                return
            if int(declarado) > LIMITE_CUERPO:
                await _responder(send, 413, b'{"detail":"El pedido es demasiado grande"}')
                return

        leidos = 0

        async def recibir() -> Message:
            nonlocal leidos
            mensaje = await receive()
            if mensaje["type"] == "http.request":
                leidos += len(mensaje.get("body", b""))
                if leidos > LIMITE_CUERPO:
                    # FastAPI re-lanza HTTPException al leer el cuerpo; otra excepción la
                    # convertiría en un 400 genérico.
                    raise HTTPException(413, "El pedido es demasiado grande")
            return mensaje

        async def enviar(mensaje: Message) -> None:
            if mensaje["type"] == "http.response.start":
                propias = {k for k, _ in _SEGURIDAD}
                mensaje["headers"] = [
                    (k, v) for k, v in mensaje.get("headers", []) if k.lower() not in propias
                ] + _SEGURIDAD
            await send(mensaje)

        await self.app(scope, recibir, enviar)


async def _responder(send: Send, codigo: int, cuerpo: bytes) -> None:
    await send(
        {
            "type": "http.response.start",
            "status": codigo,
            "headers": [
                (b"content-type", b"application/json"),
                (b"content-length", str(len(cuerpo)).encode()),
                *_SEGURIDAD,
            ],
        }
    )
    await send({"type": "http.response.body", "body": cuerpo})
