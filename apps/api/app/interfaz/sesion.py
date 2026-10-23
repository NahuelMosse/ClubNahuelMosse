from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.baja import dar_de_baja
from app.aplicacion.contrasena import cambiar_contrasena
from app.aplicacion.errores import (
    DatosInvalidos,
    Demorado,
    Duplicado,
    NoAutenticado,
    Prohibido,
)
from app.aplicacion.perfil import editar_perfil
from app.aplicacion.sesion import perfil_autenticado
from app.dependencias import ProveedorFirebase, UsuariosSql, conexion
from app.dominio.usuarios import DatosPersonales, Perfil, Rol
from app.dominio.zona import ZONA_CLUB as ZONA
from app.interfaz.entradas import Clave, Texto40, Texto120
from app.interfaz.limites import Frenado, frenar_por_cuenta

router = APIRouter(tags=["sesión"])
_portador = HTTPBearer(auto_error=False, description="ID token de Firebase Authentication")


class SinSesion(BaseModel):
    detail: str


def usuario_actual(
    peticion: Request,
    credencial: Annotated[HTTPAuthorizationCredentials | None, Depends(_portador)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> Perfil:
    """Quién hace el pedido, según el token de Firebase de la cabecera `Authorization`."""
    try:
        perfil = perfil_autenticado(
            credencial.credentials if credencial else None,
            identidad=ProveedorFirebase(),
            usuarios=UsuariosSql(conn),
        )
        peticion.state.usuario_id = perfil.id
        return perfil
    except NoAutenticado as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión inválida o vencida",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e


class PerfilPropio(BaseModel):
    nombre: str
    apellido: str
    correo: str
    rol: Rol
    dni: str
    fecha_nacimiento: date


@router.get(
    "/yo",
    response_model=PerfilPropio,
    responses={401: {"model": SinSesion}},
    summary="El perfil y el rol de quien inició sesión",
)
def perfil_propio(perfil: Annotated[Perfil, Depends(usuario_actual)]) -> PerfilPropio:
    return PerfilPropio(
        nombre=perfil.nombre,
        apellido=perfil.apellido,
        correo=perfil.correo,
        rol=perfil.rol,
        dni=perfil.dni,
        fecha_nacimiento=perfil.fecha_nacimiento,
    )


class PedidoCambioDeContrasena(BaseModel):
    actual: Clave = ""
    nueva: Clave = ""


class ErroresDeContrasena(BaseModel):
    errores: dict[str, str]


@router.put(
    "/yo/contrasena",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": SinSesion},
        422: {"model": ErroresDeContrasena},
        429: {"description": "Demasiados intentos con la contraseña actual"},
    },
    summary="Cambiar la contraseña de quien inició sesión",
    description="Invalida todas las sesiones abiertas: la app vuelve a entrar con la nueva.",
)
def cambiar_contrasena_propia(
    pedido: PedidoCambioDeContrasena,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> Response:
    try:
        cambiar_contrasena(
            perfil,
            pedido.actual,
            pedido.nueva,
            identidad=ProveedorFirebase(),
            usuarios=UsuariosSql(conn),
        )
    except DatosInvalidos as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
        )
    except Demorado:
        return Response(status_code=status.HTTP_429_TOO_MANY_REQUESTS)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class PedidoDeEdicion(BaseModel):
    nombre: Texto120 = ""
    apellido: Texto120 = ""
    dni: Texto40 = ""
    fecha_nacimiento: Texto40 = ""


def _frenar_edicion(peticion: Request, perfil: Annotated[Perfil, Depends(usuario_actual)]) -> None:
    """Cada intento con un DNI cuenta, sea ajeno o propio: no sirve para averiguar quién es
    socio."""
    frenar_por_cuenta(peticion, "editar-perfil", perfil.id)


@router.put(
    "/yo",
    response_model=PerfilPropio,
    responses={
        401: {"model": SinSesion},
        409: {"model": ErroresDeContrasena, "description": "Otra cuenta ya tiene ese DNI"},
        422: {"model": ErroresDeContrasena},
        429: {"model": Frenado},
    },
    summary="Editar los datos personales de quien inició sesión",
    description="Todo menos el correo, que no se puede cambiar.",
    dependencies=[Depends(_frenar_edicion)],
)
def editar_perfil_propio(
    pedido: PedidoDeEdicion,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> PerfilPropio | JSONResponse:
    usuarios = UsuariosSql(conn)
    try:
        editar_perfil(
            perfil,
            DatosPersonales(**pedido.model_dump()),
            hoy=datetime.now(ZONA).date(),
            usuarios=usuarios,
        )
    except DatosInvalidos as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
        )
    except Duplicado:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"errores": {"dni": "Este DNI ya está registrado"}},
        )
    actualizado = usuarios.perfil_activo(perfil.uid)
    if actualizado is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión inválida o vencida",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return perfil_propio(actualizado)


@router.delete(
    "/yo",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        401: {"model": SinSesion},
        403: {"description": "Un administrador no se da de baja desde la app"},
    },
    summary="Dar de baja la cuenta de quien inició sesión",
    description=(
        "Baja lógica: la cuenta deja de estar activa, sus reservas que todavía no empezaron "
        "pasan a canceladas y el historial se conserva."
    ),
)
def dar_de_baja_propia(
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> Response:
    try:
        dar_de_baja(perfil, UsuariosSql(conn), ProveedorFirebase())
    except Prohibido:
        return Response(status_code=status.HTTP_403_FORBIDDEN)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
