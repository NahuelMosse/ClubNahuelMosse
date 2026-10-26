import hmac
from collections.abc import Callable
from typing import cast

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import PlainTextResponse
from prometheus_client import (
    CollectorRegistry,
    Counter,
    Gauge,
    Histogram,
    disable_created_metrics,
)

from app.config import config
from app.dependencias import uso_del_pool

router = APIRouter(tags=["operación"])

SIN_RUTA = "sin_ruta"
_CORTES = (0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0)

# Las series son del proceso, compartidas por todas las apps que se creen: un registro propio,
# no el global de la librería. Sin las series `_created`, que sólo suman ruido (la librería no
# tipa esta función).
cast(Callable[[], None], disable_created_metrics)()
_registro = CollectorRegistry()
_solicitudes = Counter(
    "solicitudes", "Pedidos atendidos", ["metodo", "ruta", "codigo"], registry=_registro
)
_duraciones = Histogram(
    "solicitud_segundos", "Segundos por pedido", ["ruta"], buckets=_CORTES, registry=_registro
)
Gauge("pool_conexiones_en_uso", "Conexiones del pool en uso", registry=_registro).set_function(
    lambda: uso_del_pool()[0]
)
Gauge("pool_conexiones_libres", "Conexiones del pool libres", registry=_registro).set_function(
    lambda: uso_del_pool()[1]
)


def registrar(metodo: str, ruta: str, codigo: int, segundos: float) -> None:
    """Suma un pedido a las series; `ruta` es la plantilla, nunca la ruta con sus valores."""
    _solicitudes.labels(metodo, ruta, str(codigo)).inc()
    _duraciones.labels(ruta).observe(segundos)


def _texto() -> str:
    """El formato de texto de Prometheus. Las etiquetas salen en el orden declarado, que fijan
    los tests; `generate_latest` las ordena por nombre."""
    lineas: list[str] = []
    for serie in _registro.collect():
        nombre = f"{serie.name}_total" if serie.type == "counter" else serie.name
        lineas += [f"# HELP {nombre} {serie.documentation}", f"# TYPE {nombre} {serie.type}"]
        for muestra in serie.samples:
            etiquetas = ",".join(f'{k}="{v}"' for k, v in muestra.labels.items())
            serie_con_etiquetas = f"{muestra.name}{{{etiquetas}}}" if etiquetas else muestra.name
            lineas.append(f"{serie_con_etiquetas} {muestra.value!r}")
    return "\n".join(lineas) + "\n"


@router.get(
    "/metrics",
    response_class=PlainTextResponse,
    responses={404: {"description": "Sin token válido o con las métricas apagadas."}},
)
def metricas(request: Request) -> PlainTextResponse:
    """Las métricas por ruta y del pool; el token va como bearer y, sin él, la ruta no existe."""
    esperado = config.metricas_token
    cabecera = request.headers.get("authorization", "")
    recibido = cabecera.removeprefix("Bearer ") if cabecera.startswith("Bearer ") else ""
    if not esperado or not hmac.compare_digest(recibido.encode(), esperado.encode()):
        raise HTTPException(status_code=404, detail="Not Found")
    return PlainTextResponse(_texto())
