import base64
import hashlib
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, Response, status
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel

from app.aplicacion.errores import DatosInvalidos
from app.aplicacion.recuperacion import EnlaceInvalido, enlace_vigente, pedir_enlace, usar_enlace
from app.config import config
from app.dependencias import (
    EnlacesSql,
    ProveedorFirebase,
    UsuariosSql,
    identidad,
    repositorio_enlaces,
    repositorio_usuarios,
)
from app.dependencias import enviar_correo as enviar
from app.interfaz.entradas import Clave, Codigo, Correo
from app.interfaz.limites import Frenado, frenar_por_origen

router = APIRouter(tags=["recuperación de contraseña"])

# El paquete de la app en Android: el enlace del correo la abre con este intent.
PAQUETE_ANDROID = "ar.edu.unimoron.clubnahuelmosse"


class PedidoDeEnlace(BaseModel):
    correo: Correo = ""


class ConsultaDeEnlace(BaseModel):
    codigo: Codigo = ""


class ContrasenaNueva(BaseModel):
    codigo: Codigo = ""
    nueva: Clave = ""


class ErroresDeCampo(BaseModel):
    errores: dict[str, str]


def _invalidos(e: DatosInvalidos) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
    )


@router.post(
    "/recuperacion",
    status_code=status.HTTP_202_ACCEPTED,
    responses={422: {"model": ErroresDeCampo}, 429: {"model": Frenado}},
    summary="Pedir un enlace para crear una contraseña nueva",
    description="Responde lo mismo exista o no una cuenta con ese correo.",
    dependencies=[Depends(frenar_por_origen("recuperacion"))],
)
def pedir(
    pedido: PedidoDeEnlace,
    tareas: BackgroundTasks,
    enlaces: Annotated[EnlacesSql, Depends(repositorio_enlaces)],
) -> Response:
    try:
        mensaje = pedir_enlace(pedido.correo, config.url_publica, enlaces)
    except DatosInvalidos as e:
        return _invalidos(e)
    if mensaje is not None:
        if config.correo_modo == "buzon":
            # En desarrollo y escenarios el buzón se llena antes de responder, así el
            # correo ya está cuando la app muestra «Revisá tu correo».
            enviar(mensaje)
        else:
            # Por SMTP, después de responder: la demora no delata que la cuenta existe.
            tareas.add_task(enviar, mensaje)
    return Response(status_code=status.HTTP_202_ACCEPTED)


# Los códigos viajan en el cuerpo, no en la ruta: la ruta queda en los registros de pedidos.
@router.post(
    "/recuperacion/consulta",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={410: {"description": "El enlace venció, ya se usó o fue reemplazado"}},
    summary="Saber si un enlace de recuperación sigue sirviendo",
)
def consultar(
    consulta: ConsultaDeEnlace, enlaces: Annotated[EnlacesSql, Depends(repositorio_enlaces)]
) -> Response:
    vigente = bool(consulta.codigo) and enlace_vigente(consulta.codigo, enlaces)
    return Response(status_code=status.HTTP_204_NO_CONTENT if vigente else status.HTTP_410_GONE)


@router.put(
    "/recuperacion",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        410: {"description": "El enlace venció, ya se usó o fue reemplazado"},
        422: {"model": ErroresDeCampo},
    },
    summary="Crear la contraseña nueva con el enlace",
    description="El enlace deja de servir y se invalidan todas las sesiones de la cuenta.",
)
def usar(
    pedido: ContrasenaNueva,
    enlaces: Annotated[EnlacesSql, Depends(repositorio_enlaces)],
    usuarios: Annotated[UsuariosSql, Depends(repositorio_usuarios)],
    proveedor: Annotated[ProveedorFirebase, Depends(identidad)],
) -> Response:
    try:
        usar_enlace(
            pedido.codigo,
            pedido.nueva,
            enlaces,
            identidad=proveedor,
            usuarios=usuarios,
        )
    except DatosInvalidos as e:
        return _invalidos(e)
    except EnlaceInvalido:
        return Response(status_code=status.HTTP_410_GONE)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


_SCRIPT_DEL_ENLACE = f"""
  var codigo = new URLSearchParams(location.hash.slice(1)).get("codigo") || "";
  location.replace("intent://app/recuperar?codigo=" + encodeURIComponent(codigo) +
    "#Intent;scheme=clubnahuelmosse;package={PAQUETE_ANDROID};end");
"""

_PAGINA_DEL_ENLACE = f"""<!doctype html>
<html lang="es">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ClubNahuelMosse</title>
<p>Abriendo la app de ClubNahuelMosse…</p>
<p>Si no se abre, abrí este correo desde el teléfono que tiene la app instalada.</p>
<script>{_SCRIPT_DEL_ENLACE}</script>
</html>
"""

# La página sólo corre su propio script: el navegador lo reconoce por su hash.
_HASH_DEL_SCRIPT = base64.b64encode(
    hashlib.sha256(_SCRIPT_DEL_ENLACE.encode("utf-8")).digest()
).decode("ascii")
_POLITICA_DEL_ENLACE = (
    f"default-src 'none'; script-src 'sha256-{_HASH_DEL_SCRIPT}'; frame-ancestors 'none'"
)


@router.get(
    "/enlace/recuperar",
    response_class=HTMLResponse,
    summary="Página del enlace del correo: abre la app en la contraseña nueva",
    description=(
        "Los clientes de correo no vuelven tocables los enlaces con esquema propio; este "
        "enlace https lleva a la app con un intent de Android."
    ),
)
def pagina_del_enlace() -> HTMLResponse:
    return HTMLResponse(
        _PAGINA_DEL_ENLACE,
        headers={
            "Referrer-Policy": "no-referrer",
            "Content-Security-Policy": _POLITICA_DEL_ENLACE,
        },
    )
