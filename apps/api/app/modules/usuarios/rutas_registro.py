# kit-shape: las rutas de registro y los modelos de sus pedidos y respuestas se leen juntos
from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.modules.usuarios.registro import registrar
from app.modules.usuarios.reglas import DatosRegistro
from app.modules.usuarios.repositorio import UsuariosSql, repositorio_usuarios
from app.shared.errors import Duplicate
from app.shared.identity import FirebaseProvider, identidad
from app.shared.club_timezone import CLUB_TIMEZONE as ZONA

router = APIRouter(tags=["usuarios"])
MENSAJE_DUPLICADO = "El usuario ya está registrado. Modificá el correo o el DNI."
MENSAJES_CAMPO = {
    "correo": "Este correo ya está registrado",
    "dni": "Este DNI ya está registrado",
}


class PedidoRegistro(BaseModel):
    nombre: str = ""
    apellido: str = ""
    dni: str = ""
    fecha_nacimiento: str = ""
    correo: str = ""
    contrasena: str = ""


class RegistroCreado(BaseModel):
    id: UUID


class ErroresDeCampo(BaseModel):
    errores: dict[str, str]


class UsuarioRepetido(BaseModel):
    mensaje: str
    campos: list[str]
    errores: dict[str, str]


@router.post(
    "/registro",
    status_code=status.HTTP_201_CREATED,
    response_model=RegistroCreado,
    responses={
        422: {"model": ErroresDeCampo},
        409: {"model": UsuarioRepetido},
    },
    summary="Registrar un usuario nuevo",
)
def registrar_usuario(
    pedido: PedidoRegistro,
    usuarios: Annotated[UsuariosSql, Depends(repositorio_usuarios)],
    proveedor: Annotated[FirebaseProvider, Depends(identidad)],
) -> RegistroCreado | JSONResponse:
    try:
        nuevo = registrar(
            DatosRegistro(**pedido.model_dump()),
            hoy=datetime.now(ZONA).date(),
            identidad=proveedor,
            usuarios=usuarios,
        )
    except Duplicate as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={
                "mensaje": MENSAJE_DUPLICADO,
                "campos": e.campos,
                "errores": {c: MENSAJES_CAMPO[c] for c in e.campos},
            },
        )
    return RegistroCreado(id=nuevo)
