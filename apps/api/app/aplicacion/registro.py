from datetime import date
from typing import Protocol

from app.aplicacion.errores import DatosInvalidos, Duplicado
from app.dominio.usuarios import DatosRegistro, Registro, validar_registro


class ProveedorIdentidad(Protocol):
    def crear_cuenta(self, correo: str, contrasena: str) -> str:
        """Crea la cuenta y devuelve su uid. Lanza `Duplicado(["correo"])` si el correo existe."""
        ...

    def borrar_cuenta(self, uid: str) -> None: ...


class RepositorioUsuarios(Protocol):
    def duplicados(self, correo: str, dni: str) -> list[str]: ...

    def insertar(self, uid: str, registro: Registro) -> int:
        """Inserta el perfil. Lanza `Duplicado` si la base rechaza el correo o el DNI."""
        ...


def registrar(
    datos: DatosRegistro,
    hoy: date,
    identidad: ProveedorIdentidad,
    usuarios: RepositorioUsuarios,
) -> int:
    registro, errores = validar_registro(datos, hoy)
    if registro is None:
        raise DatosInvalidos(errores)

    if repetidos := usuarios.duplicados(registro.correo, registro.dni):
        raise Duplicado(repetidos)

    uid = identidad.crear_cuenta(registro.correo, registro.contrasena)
    try:
        return usuarios.insertar(uid, registro)
    except BaseException:
        identidad.borrar_cuenta(uid)
        raise
