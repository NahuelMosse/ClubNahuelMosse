from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import Connection

from app.aplicacion.errores import DatosInvalidos, Duplicado
from app.aplicacion.registro import registrar
from app.dependencias import ProveedorFirebase, UsuariosSql, conexion
from app.dominio.usuarios import DatosRegistro
from app.dominio.zona import ZONA_CLUB as ZONA
from app.interfaz.entradas import Clave, Correo, Texto40, Texto120
from app.interfaz.limites import Frenado, frenar_por_origen

router = APIRouter(tags=["usuarios"])
MENSAJE_DUPLICADO = "El usuario ya está registrado. Modificá el correo o el DNI."
MENSAJES_CAMPO = {
    "correo": "Este correo ya está registrado",
    "dni": "Este DNI ya está registrado",
}


class PedidoRegistro(BaseModel):
    nombre: Texto120 = ""
    apellido: Texto120 = ""
    dni: Texto40 = ""
    fecha_nacimiento: Texto40 = ""
    correo: Correo = ""
    contrasena: Clave = ""


class RegistroCreado(BaseModel):
    id: int


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
        429: {"model": Frenado},
    },
    summary="Registrar un usuario nuevo",
    dependencies=[Depends(frenar_por_origen("registro"))],
)
def registrar_usuario(
    pedido: PedidoRegistro, conn: Annotated[Connection, Depends(conexion, scope="function")]
) -> RegistroCreado | JSONResponse:
    try:
        nuevo = registrar(
            DatosRegistro(**pedido.model_dump()),
            hoy=datetime.now(ZONA).date(),
            identidad=ProveedorFirebase(),
            usuarios=UsuariosSql(conn),
        )
    except DatosInvalidos as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"errores": e.errores}
        )
    except Duplicado as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={
                "mensaje": MENSAJE_DUPLICADO,
                "campos": e.campos,
                "errores": {c: MENSAJES_CAMPO[c] for c in e.campos},
            },
        )
    return RegistroCreado(id=nuevo)
