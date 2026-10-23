"""Límite de frecuencia por ventana deslizante, en la memoria de esta instancia de la app.
Hay dos: por origen, para lo que se puede pedir sin sesión, y por cuenta, para lo que se
pide con sesión."""

import threading
import time
from collections import deque
from collections.abc import Callable

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.config import config

POR_ORIGEN = (10, 60)
POR_CUENTA = (10, 3600)
MENSAJE_POR_ORIGEN = "Hiciste demasiados intentos. Esperá un minuto y volvé a probar."
MENSAJE_POR_CUENTA = "Hiciste demasiados intentos. Esperá una hora y volvé a probar."
# Tope de claves en memoria: pasado esto se barren las ventanas que ya vencieron.
_CLAVES_MAXIMAS = 10_000


class Frenado(BaseModel):
    """El cuerpo del 429, para el contrato."""

    mensaje: str


class LimiteExcedido(Exception):
    def __init__(self, espera: int, mensaje: str) -> None:
        super().__init__(mensaje)
        self.espera = espera
        self.mensaje = mensaje


class Ventana:
    """Deja pasar hasta `maximo` pedidos por clave en los últimos `segundos`."""

    def __init__(
        self,
        maximo: int,
        segundos: int,
        mensaje: str,
        reloj: Callable[[], float] = time.monotonic,
    ) -> None:
        self._maximo = maximo
        self._segundos = segundos
        self._mensaje = mensaje
        self._reloj = reloj
        self._pedidos: dict[str, deque[float]] = {}
        self._candado = threading.Lock()

    def exigir(self, clave: str) -> None:
        """Anota el pedido, o lanza `LimiteExcedido` si la clave ya agotó su cupo. Un pedido
        frenado no cuenta: el cupo vuelve cuando vence el más viejo."""
        with self._candado:
            ahora = self._reloj()
            if len(self._pedidos) >= _CLAVES_MAXIMAS:
                self._barrer(ahora)
            pedidos = self._pedidos.setdefault(clave, deque())
            self._podar(pedidos, ahora)
            if len(pedidos) >= self._maximo:
                raise LimiteExcedido(self._segundos, self._mensaje)
            pedidos.append(ahora)

    def _podar(self, pedidos: deque[float], ahora: float) -> None:
        while pedidos and ahora - pedidos[0] >= self._segundos:
            pedidos.popleft()

    def _barrer(self, ahora: float) -> None:
        for clave in list(self._pedidos):
            self._podar(self._pedidos[clave], ahora)
            if not self._pedidos[clave]:
                del self._pedidos[clave]


class Limites:
    def __init__(self, reloj: Callable[[], float] = time.monotonic) -> None:
        self.por_origen = Ventana(*POR_ORIGEN, MENSAJE_POR_ORIGEN, reloj)
        self.por_cuenta = Ventana(*POR_CUENTA, MENSAJE_POR_CUENTA, reloj)


def origen(peticion: Request) -> str:
    """Quién pide. Detrás del proxy de Render el último valor de `X-Forwarded-For` es el que
    agrega Render; los anteriores los manda el cliente y se pueden inventar."""
    if config.detras_de_proxy:
        reenviado = peticion.headers.get("x-forwarded-for", "").split(",")[-1].strip()
        if reenviado:
            return reenviado
    return peticion.client.host if peticion.client else "desconocido"


def frenar_por_origen(ruta: str) -> Callable[[Request], None]:
    """La dependencia de una ruta sin sesión: cuenta los pedidos de cada origen."""

    def dependencia(peticion: Request) -> None:
        peticion.app.state.limites.por_origen.exigir(f"{ruta}|{origen(peticion)}")

    return dependencia


def frenar_por_cuenta(peticion: Request, ruta: str, cuenta: int) -> None:
    """Cuenta los pedidos de una cuenta a una ruta con sesión."""
    peticion.app.state.limites.por_cuenta.exigir(f"{ruta}|{cuenta}")


async def _responder(_: Request, e: Exception) -> JSONResponse:
    assert isinstance(e, LimiteExcedido)
    return JSONResponse(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        content={"mensaje": e.mensaje},
        headers={"Retry-After": str(e.espera)},
    )


def instalar(app: FastAPI) -> None:
    """Crea los contadores de esta app y responde 429 con `Retry-After` al que se pasa."""
    app.state.limites = Limites()
    app.add_exception_handler(LimiteExcedido, _responder)
