from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.errores import NoAutenticado
from app.aplicacion.sesion import perfil_autenticado
from app.dominio.usuarios import Perfil, Rol
from app.infraestructura.db import conexion
from app.infraestructura.identidad import ProveedorFirebase
from app.infraestructura.usuarios import UsuariosSql

router = APIRouter(tags=["sesión"])
_portador = HTTPBearer(auto_error=False, description="ID token de Firebase Authentication")


class SinSesion(BaseModel):
    detail: str


def usuario_actual(
    credencial: Annotated[HTTPAuthorizationCredentials | None, Depends(_portador)],
    conn: Annotated[Connection, Depends(conexion, scope="function")],
) -> Perfil:
    """Quién hace el pedido, según el token de Firebase de la cabecera `Authorization`."""
    try:
        return perfil_autenticado(
            credencial.credentials if credencial else None,
            identidad=ProveedorFirebase(),
            usuarios=UsuariosSql(conn),
        )
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


@router.get(
    "/yo",
    response_model=PerfilPropio,
    responses={401: {"model": SinSesion}},
    summary="El perfil y el rol de quien inició sesión",
)
def perfil_propio(perfil: Annotated[Perfil, Depends(usuario_actual)]) -> PerfilPropio:
    return PerfilPropio(
        nombre=perfil.nombre, apellido=perfil.apellido, correo=perfil.correo, rol=perfil.rol
    )
