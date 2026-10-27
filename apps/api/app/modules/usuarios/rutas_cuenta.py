# kit-shape: las rutas de la cuenta y los modelos de sus pedidos y respuestas se leen juntos
from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.sesion import Perfil, Perfiles, Rol, SinSesion, usuario_actual
from app.modules.usuarios.baja import dar_de_baja
from app.modules.usuarios.contrasena import cambiar_contrasena
from app.modules.usuarios.perfil import editar_perfil
from app.modules.usuarios.reglas import DatosPersonales
from app.modules.usuarios.repositorio import UsuariosSql, repositorio_usuarios
from app.shared.club_timezone import CLUB_TIMEZONE as ZONA
from app.shared.errors import Duplicate, RateLimited
from app.shared.identity import FirebaseProvider, identity

router = APIRouter(tags=["sesión"])


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
    return PerfilPropio.model_validate(perfil, from_attributes=True)


class PedidoCambioDeContrasena(BaseModel):
    actual: str = ""
    nueva: str = ""


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
    usuarios: Annotated[UsuariosSql, Depends(repositorio_usuarios)],
    proveedor: Annotated[FirebaseProvider, Depends(identity)],
) -> Response:
    try:
        cambiar_contrasena(
            perfil,
            pedido.actual,
            pedido.nueva,
            identidad=proveedor,
            usuarios=usuarios,
        )
    except RateLimited:
        return Response(status_code=status.HTTP_429_TOO_MANY_REQUESTS)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class PedidoDeEdicionDePerfil(BaseModel):
    nombre: str = ""
    apellido: str = ""
    dni: str = ""
    fecha_nacimiento: str = ""


@router.put(
    "/yo",
    response_model=PerfilPropio,
    responses={
        401: {"model": SinSesion},
        409: {"model": ErroresDeContrasena, "description": "Otra cuenta ya tiene ese DNI"},
        422: {"model": ErroresDeContrasena},
    },
    summary="Editar los datos personales de quien inició sesión",
    description="Todo menos el correo, que no se puede cambiar.",
)
def editar_perfil_propio(
    pedido: PedidoDeEdicionDePerfil,
    perfil: Annotated[Perfil, Depends(usuario_actual)],
    usuarios: Annotated[UsuariosSql, Depends(repositorio_usuarios)],
    perfiles: Perfiles,
) -> PerfilPropio | JSONResponse:
    try:
        editar_perfil(
            perfil,
            DatosPersonales(**pedido.model_dump()),
            hoy=datetime.now(ZONA).date(),
            usuarios=usuarios,
        )
    except Duplicate:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"errores": {"dni": "Este DNI ya está registrado"}},
        )
    actualizado = perfiles.perfil_activo(perfil.uid)
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
    usuarios: Annotated[UsuariosSql, Depends(repositorio_usuarios)],
    proveedor: Annotated[FirebaseProvider, Depends(identity)],
) -> Response:
    dar_de_baja(perfil, usuarios, proveedor)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
