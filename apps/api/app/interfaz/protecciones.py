from urllib.parse import urlsplit

from starlette.exceptions import HTTPException
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.config import config

LIMITE_CUERPO = 64 * 1024
POLITICA_DE_CONTENIDO = b"default-src 'none'; frame-ancestors 'none'"
_SEGURIDAD = [(b"cache-control", b"no-store"), (b"x-content-type-options", b"nosniff")]
_HOSTS_PROPIOS = {"localhost", "127.0.0.1", "10.0.2.2"}
_DOCUMENTACION = {"/docs", "/redoc"}
# El chequeo de Render llega con el Host que él use: queda fuera del filtro (no toca dependencias).
RUTA_SALUD = "/health"


def hosts_permitidos() -> set[str]:
    """Los propios, el de `url_publica` y lo que agregue `hosts_permitidos`."""
    agregados = {h.strip().lower() for h in config.hosts_permitidos.split(",") if h.strip()}
    publico = urlsplit(config.url_publica).hostname
    return _HOSTS_PROPIOS | agregados | ({publico.lower()} if publico else set())


def _host(scope: Scope) -> str:
    """El Host del pedido, sin puerto."""
    crudo: str = dict(scope["headers"]).get(b"host", b"").decode("latin-1").strip().lower()
    if crudo.startswith("["):
        return crudo.partition("]")[0] + "]"
    return crudo.partition(":")[0]


class Protecciones:
    """Rechaza Host ajeno y cuerpos de más de 64 KB, y marca las respuestas.

    Todas salen no cacheables, sin adivinar el tipo y con una política de contenido que
    impide incrustarlas; la que ya trae su propia política (la página del enlace) la conserva
    y `/docs` y `/redoc`, cuando están prendidos, no la llevan porque cargan scripts.
    El tamaño se controla por lo que declara `Content-Length`, antes de leer un byte, y
    también mientras se lee, para el cuerpo que llega por partes sin declararlo.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app
        self._hosts = hosts_permitidos()
        self._documentada = config.documentacion_interactiva

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        if scope["path"] != RUTA_SALUD and _host(scope) not in self._hosts:
            await _responder(send, 400, b'{"detail":"Host no permitido"}')
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
        con_politica = not (self._documentada and scope["path"] in _DOCUMENTACION)

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
                previas = [
                    (k, v) for k, v in mensaje.get("headers", []) if k.lower() not in propias
                ]
                mensaje["headers"] = _con_politica(previas, con_politica) + _SEGURIDAD
            await send(mensaje)

        await self.app(scope, recibir, enviar)


def _con_politica(cabeceras: list[tuple[bytes, bytes]], poner: bool) -> list[tuple[bytes, bytes]]:
    if not poner or any(k.lower() == b"content-security-policy" for k, _ in cabeceras):
        return cabeceras
    return [*cabeceras, (b"content-security-policy", POLITICA_DE_CONTENIDO)]


async def _responder(send: Send, codigo: int, cuerpo: bytes) -> None:
    await send(
        {
            "type": "http.response.start",
            "status": codigo,
            "headers": [
                (b"content-type", b"application/json"),
                (b"content-length", str(len(cuerpo)).encode()),
                (b"content-security-policy", POLITICA_DE_CONTENIDO),
                *_SEGURIDAD,
            ],
        }
    )
    await send({"type": "http.response.body", "body": cuerpo})
