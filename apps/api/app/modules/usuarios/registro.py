import logging
from datetime import date
from typing import Protocol

from app.modules.usuarios.reglas import DatosRegistro, Registro, validar_registro
from app.shared.errores import DatosInvalidos, Duplicado

registro_log = logging.getLogger("clubnahuelmosse.registro")


class ProveedorIdentidad(Protocol):
    def crear_cuenta(self, correo: str, contrasena: str) -> str:
        """Crea la cuenta y devuelve su uid. Lanza `Duplicado(["correo"])` si el correo existe."""
        ...

    def uid_de(self, correo: str) -> str | None: ...

    def borrar_cuenta(self, uid: str) -> None: ...


class RepositorioUsuarios(Protocol):
    def duplicados(self, correo: str, dni: str) -> list[str]: ...

    def uid_activo(self, uid: str) -> bool: ...

    def insertar(self, uid: str, registro: Registro) -> int:
        """Inserta y confirma el perfil. Lanza `Duplicado` si la base rechaza correo o DNI."""
        ...


def _crear_cuenta(
    registro: Registro, identidad: ProveedorIdentidad, usuarios: RepositorioUsuarios
) -> str:
    try:
        return identidad.crear_cuenta(registro.correo, registro.contrasena)
    except Duplicado:
        # Una cuenta del proveedor sin perfil activo quedó de un alta que no terminó o de una
        # baja: el correo está libre en la base, así que se reemplaza.
        existente = identidad.uid_de(registro.correo)
        if existente is None or usuarios.uid_activo(existente):
            raise
        identidad.borrar_cuenta(existente)
        return identidad.crear_cuenta(registro.correo, registro.contrasena)


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

    uid = _crear_cuenta(registro, identidad, usuarios)
    try:
        return usuarios.insertar(uid, registro)
    except BaseException:
        try:
            identidad.borrar_cuenta(uid)
        except Exception:
            registro_log.exception("no se pudo borrar la cuenta %s del proveedor", uid)
        raise
