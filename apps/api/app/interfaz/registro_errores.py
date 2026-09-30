import logging

from starlette.types import ASGIApp, Message, Receive, Scope, Send

_registro = logging.getLogger("clubnahuelmosse.errores")
_RECHAZOS = {401, 403, 409}


def configurar_registro() -> None:
    """Deja el registro de la API con fecha y nivel, sin pisar una configuración propia."""
    raiz = logging.getLogger("clubnahuelmosse")
    if raiz.handlers:
        return
    manejador = logging.StreamHandler()
    manejador.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s"))
    raiz.addHandler(manejador)
    raiz.setLevel(logging.INFO)


class RegistroDeErrores:
    """Registra, con método, ruta, código y usuario, lo que falla o se rechaza.

    Las excepciones no atrapadas y los 5xx van como error; los 401, 403 y 409, como aviso.
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
            _registro.error("%s 500 usuario=%s", _operacion(scope), _usuario(scope), exc_info=True)
            raise
        if codigo >= 500:
            _registro.error("%s %d usuario=%s", _operacion(scope), codigo, _usuario(scope))
        elif codigo in _RECHAZOS:
            _registro.warning("%s %d usuario=%s", _operacion(scope), codigo, _usuario(scope))


def _operacion(scope: Scope) -> str:
    return f"{scope['method']} {scope['path']}"


def _usuario(scope: Scope) -> str:
    quien = scope.get("state", {}).get("usuario_id")
    return "anónimo" if quien is None else str(quien)
