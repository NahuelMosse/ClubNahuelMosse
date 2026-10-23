import hmac
import threading
from collections import defaultdict

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import PlainTextResponse

from app.config import config
from app.infraestructura.db import motor

router = APIRouter(tags=["operación"])

SIN_RUTA = "sin_ruta"
_CORTES = (0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0)
_cerrojo = threading.Lock()
_solicitudes: dict[tuple[str, str, int], int] = defaultdict(int)
# Por ruta: una cuenta acumulada por corte, más la suma y el total.
_duraciones: dict[str, list[float]] = {}


def registrar(metodo: str, ruta: str, codigo: int, segundos: float) -> None:
    """Suma un pedido a las series; `ruta` es la plantilla, nunca la ruta con sus valores."""
    with _cerrojo:
        _solicitudes[(metodo, ruta, codigo)] += 1
        serie = _duraciones.setdefault(ruta, [0.0] * (len(_CORTES) + 2))
        for i, corte in enumerate(_CORTES):
            if segundos <= corte:
                serie[i] += 1
        serie[-2] += segundos
        serie[-1] += 1


def _texto() -> str:
    lineas = ["# TYPE solicitudes_total counter"]
    with _cerrojo:
        for (metodo, ruta, codigo), cuenta in sorted(_solicitudes.items()):
            lineas.append(
                f'solicitudes_total{{metodo="{metodo}",ruta="{ruta}",codigo="{codigo}"}} {cuenta}'
            )
        lineas.append("# TYPE solicitud_segundos histogram")
        for ruta, serie in sorted(_duraciones.items()):
            for corte, acumulado in zip(_CORTES, serie, strict=False):
                lineas.append(
                    f'solicitud_segundos_bucket{{ruta="{ruta}",le="{corte}"}} {int(acumulado)}'
                )
            lineas.append(f'solicitud_segundos_bucket{{ruta="{ruta}",le="+Inf"}} {int(serie[-1])}')
            lineas.append(f'solicitud_segundos_sum{{ruta="{ruta}"}} {serie[-2]:.6f}')
            lineas.append(f'solicitud_segundos_count{{ruta="{ruta}"}} {int(serie[-1])}')
    pool = motor().pool
    lineas.append(f"pool_conexiones_en_uso {pool.checkedout()}")  # type: ignore[attr-defined]
    lineas.append(f"pool_conexiones_libres {pool.checkedin()}")  # type: ignore[attr-defined]
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
