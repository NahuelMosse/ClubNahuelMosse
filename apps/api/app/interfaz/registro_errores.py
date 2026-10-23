import json
import logging
import re
import time
import uuid
from contextvars import ContextVar

from fastapi.responses import JSONResponse
from starlette.datastructures import Headers, MutableHeaders
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.config import config
from app.interfaz import metricas

_registro = logging.getLogger("clubnahuelmosse.errores")
_RECHAZOS = {400, 401, 403, 409, 429}
_ID_VALIDO = re.compile(r"[A-Za-z0-9._-]{1,64}")
_EVENTO = re.compile(r"^(\w+):")
_referencia: ContextVar[str | None] = ContextVar("referencia", default=None)

MENSAJE_500 = "Ocurrió un error. Si le escribís a soporte, pasale esta referencia."


def referencia_actual() -> str:
    """El id de correlación del pedido en curso; fuera de un pedido, uno nuevo."""
    return _referencia.get() or str(uuid.uuid4())


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


class _EnJson(logging.Formatter):
    """Una línea JSON por registro, con nivel, evento, referencia y versión."""

    def format(self, record: logging.LogRecord) -> str:
        mensaje = record.getMessage()
        coincide = _EVENTO.match(mensaje)
        linea = {
            "fecha": self.formatTime(record),
            "nivel": record.levelname,
            "evento": getattr(record, "evento", None) or (coincide[1] if coincide else record.name),
            "referencia": getattr(record, "referencia", None),
            "version": config.version,
            "mensaje": mensaje,
        }
        if record.exc_info:
            linea["traza"] = self.formatException(record.exc_info)
        return json.dumps(linea, ensure_ascii=False)


def _fabrica_con_referencia() -> None:
    anterior = logging.getLogRecordFactory()
    if getattr(anterior, "con_referencia", False):
        return

    def fabrica(*args: object, **kwargs: object) -> logging.LogRecord:
        registro = anterior(*args, **kwargs)
        registro.referencia = _referencia.get()
        registro.version = config.version
        return registro

    fabrica.con_referencia = True  # type: ignore[attr-defined]
    logging.setLogRecordFactory(fabrica)


def configurar_registro() -> None:
    """Deja el registro de la API en JSON por línea, sin pisar una configuración propia."""
    _fabrica_con_referencia()
    accesos = logging.getLogger("uvicorn.access")
    if not any(isinstance(f, _SinQuery) for f in accesos.filters):
        accesos.addFilter(_SinQuery())
    raiz = logging.getLogger("clubnahuelmosse")
    if raiz.handlers:
        return
    manejador = logging.StreamHandler()
    manejador.setFormatter(_EnJson())
    raiz.addHandler(manejador)
    raiz.setLevel(logging.INFO)


class RegistroDeErrores:
    """El más externo: da a cada pedido su id de correlación y lo devuelve en X-Request-ID.

    Registra, con método, ruta, código y usuario, lo que falla o se rechaza, y cuenta cada
    pedido en las métricas. Una excepción no atrapada es un 500 con la referencia; los 5xx
    van como error y los rechazos de `_RECHAZOS` (entre ellos el Host ajeno y el límite de
    frecuencia), como aviso. El usuario lo deja `usuario_actual` en el estado del pedido;
    sin sesión es «anónimo».
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        propio = Headers(scope=scope).get("x-request-id", "")
        referencia = propio if _ID_VALIDO.fullmatch(propio) else str(uuid.uuid4())
        marca = _referencia.set(referencia)
        codigo = 0
        inicio = time.monotonic()

        async def enviar(mensaje: Message) -> None:
            nonlocal codigo
            if mensaje["type"] == "http.response.start":
                codigo = mensaje["status"]
                MutableHeaders(scope=mensaje)["X-Request-ID"] = referencia
            await send(mensaje)

        try:
            try:
                await self.app(scope, receive, enviar)
            except Exception:
                # Con la respuesta ya enviada (tarea de fondo) vale el código del cliente.
                _registro.error(
                    "%s %d usuario=%s%s",
                    _operacion(scope),
                    codigo or 500,
                    _usuario(scope),
                    " (el fallo fue posterior a la respuesta)" if codigo else "",
                    exc_info=True,
                    extra={"evento": "error_no_atrapado"},
                )
                if codigo:
                    raise
                respuesta = JSONResponse(
                    {"mensaje": MENSAJE_500, "referencia": referencia}, status_code=500
                )
                await respuesta(scope, receive, enviar)
            else:
                if codigo >= 500:
                    _registro.error(
                        "%s %d usuario=%s", _operacion(scope), codigo, _usuario(scope),
                        extra={"evento": "error_http"},
                    )  # fmt: skip
                elif codigo in _RECHAZOS:
                    _registro.warning(
                        "%s %d usuario=%s", _operacion(scope), codigo, _usuario(scope),
                        extra={"evento": "pedido_rechazado"},
                    )  # fmt: skip
        finally:
            ruta = getattr(scope.get("route"), "path_format", None) or metricas.SIN_RUTA
            metricas.registrar(scope["method"], ruta, codigo or 500, time.monotonic() - inicio)
            _referencia.reset(marca)


def _operacion(scope: Scope) -> str:
    return f"{scope['method']} {escapar(scope['path'])}"


def _usuario(scope: Scope) -> str:
    quien = scope.get("state", {}).get("usuario_id")
    return "anónimo" if quien is None else str(quien)
