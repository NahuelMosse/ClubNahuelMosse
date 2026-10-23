import logging

from starlette.types import ASGIApp, Message, Receive, Scope, Send

_registro = logging.getLogger("clubnahuelmosse.errores")
_RECHAZOS = {400, 401, 403, 409, 429}


def escapar(texto: str) -> str:
    """Muestra los caracteres de control como `\\n`, `\\x00`…: una línea de log no se parte."""
    return "".join(c if c.isprintable() else c.encode("unicode_escape").decode() for c in texto)


class _SinQuery(logging.Filter):
    """Saca el query string de la línea del log de accesos de uvicorn: lleva lo que se busca."""

    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.args, tuple) and len(record.args) == 5:
            ruta = str(record.args[2]).partition("?")[0]
            record.args = (*record.args[:2], escapar(ruta), *record.args[3:])
        return True


def configurar_registro() -> None:
    """Deja el registro de la API con fecha y nivel, sin pisar una configuración propia."""
    accesos = logging.getLogger("uvicorn.access")
    if not any(isinstance(f, _SinQuery) for f in accesos.filters):
        accesos.addFilter(_SinQuery())
    raiz = logging.getLogger("clubnahuelmosse")
    if raiz.handlers:
        return
    manejador = logging.StreamHandler()
    manejador.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s"))
    raiz.addHandler(manejador)
    raiz.setLevel(logging.INFO)


class RegistroDeErrores:
    """Registra, con método, ruta, código y usuario, lo que falla o se rechaza.

    Las excepciones no atrapadas y los 5xx van como error; los rechazos de `_RECHAZOS`
    (entre ellos el Host ajeno y el límite de frecuencia), como aviso.
    El usuario lo deja `usuario_actual` en el estado del pedido; sin sesión es «anónimo».
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        codigo = 0

        async def enviar(mensaje: Message) -> None:
            nonlocal codigo
            if mensaje["type"] == "http.response.start":
                codigo = mensaje["status"]
            await send(mensaje)

        try:
            await self.app(scope, receive, enviar)
        except Exception:
            # Con la respuesta ya enviada (tarea de fondo) vale el código que recibió el cliente.
            _registro.error(
                "%s %d usuario=%s%s",
                _operacion(scope),
                codigo or 500,
                _usuario(scope),
                " (el fallo fue posterior a la respuesta)" if codigo else "",
                exc_info=True,
            )
            raise
        if codigo >= 500:
            _registro.error("%s %d usuario=%s", _operacion(scope), codigo, _usuario(scope))
        elif codigo in _RECHAZOS:
            _registro.warning("%s %d usuario=%s", _operacion(scope), codigo, _usuario(scope))


def _operacion(scope: Scope) -> str:
    return f"{scope['method']} {escapar(scope['path'])}"


def _usuario(scope: Scope) -> str:
    quien = scope.get("state", {}).get("usuario_id")
    return "anónimo" if quien is None else str(quien)
