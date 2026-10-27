# kit-shape: el modelo de la respuesta sin sesión y la dependencia del usuario actual van juntos
from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel

from app.modules.sesion.casos_de_uso import perfil_autenticado
from app.modules.sesion.perfil import Perfil
from app.modules.sesion.repositorio import Perfiles
from app.shared.errores import NoAutenticado
from app.shared.identidad import ProveedorFirebase, identidad

_portador = HTTPBearer(auto_error=False, description="ID token de Firebase Authentication")


class SinSesion(BaseModel):
    detail: str


def usuario_actual(
    peticion: Request,
    credencial: Annotated[HTTPAuthorizationCredentials | None, Depends(_portador)],
    perfiles: Perfiles,
    proveedor: Annotated[ProveedorFirebase, Depends(identidad)],
) -> Perfil:
    """Quién hace el pedido, según el token de Firebase de la cabecera `Authorization`."""
    try:
        return perfil_autenticado(
            credencial.credentials if credencial else None,
            identidad=proveedor,
            usuarios=perfiles,
        )
    except NoAutenticado as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión inválida o vencida",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
