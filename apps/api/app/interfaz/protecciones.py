from starlette.types import ASGIApp, Message, Receive, Scope, Send

LIMITE_CUERPO = 64 * 1024


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
        if declarado is not None and (not declarado.isdigit() or int(declarado) > LIMITE_CUERPO):
            await _demasiado_grande(send)
            return

        leidos = 0

        async def recibir() -> Message:
            nonlocal leidos
            mensaje = await receive()
            if mensaje["type"] == "http.request":
                leidos += len(mensaje.get("body", b""))
                if leidos > LIMITE_CUERPO:
                    raise _CuerpoExcedido
            return mensaje

        async def enviar(mensaje: Message) -> None:
            if mensaje["type"] == "http.response.start":
                cabeceras = [
                    (k, v) for k, v in mensaje.get("headers", []) if k.lower() != b"cache-control"
                ]
                cabeceras.append((b"cache-control", b"no-store"))
                cabeceras.append((b"x-content-type-options", b"nosniff"))
                mensaje["headers"] = cabeceras
            await send(mensaje)

        try:
            await self.app(scope, recibir, enviar)
        except _CuerpoExcedido:
            await _demasiado_grande(send)


class _CuerpoExcedido(Exception):
    pass


async def _demasiado_grande(send: Send) -> None:
    cuerpo = b'{"detail":"El pedido es demasiado grande"}'
    await send(
        {
            "type": "http.response.start",
            "status": 413,
            "headers": [
                (b"content-type", b"application/json"),
                (b"content-length", str(len(cuerpo)).encode()),
                (b"cache-control", b"no-store"),
            ],
        }
    )
    await send({"type": "http.response.body", "body": cuerpo})
