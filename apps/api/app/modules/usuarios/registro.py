# kit-shape: los contratos del alta y la función que los usa se leen juntos
import logging
from datetime import date
from typing import Protocol
from uuid import UUID

from app.modules.usuarios.reglas import DatosRegistro, Registro, validar_registro
from app.shared.errors import InvalidData, Duplicate

registro_log = logging.getLogger("clubnahuelmosse.registro")


class ProveedorIdentidad(Protocol):
    def create_account(self, correo: str, contrasena: str) -> str:
        """Crea la cuenta y devuelve su uid. Lanza `Duplicate(["correo"])` si el correo existe."""
        ...

    def uid_of(self, correo: str) -> str | None: ...

    def delete_account(self, uid: str) -> None: ...


class RepositorioUsuarios(Protocol):
    def duplicados(self, correo: str, dni: str) -> list[str]: ...

    def uid_activo(self, uid: str) -> bool: ...

    def insertar(self, uid: str, registro: Registro) -> UUID:
        """Inserta y confirma el perfil. Lanza `Duplicate` si la base rechaza correo o DNI."""
        ...


def _crear_cuenta(
    registro: Registro, identidad: ProveedorIdentidad, usuarios: RepositorioUsuarios
) -> str:
    try:
        return identidad.create_account(registro.correo, registro.contrasena)
    except Duplicate:
        # Una cuenta del proveedor sin perfil activo quedó de un alta que no terminó o de una
        # baja: el correo está libre en la base, así que se reemplaza.
        existente = identidad.uid_of(registro.correo)
        if existente is None or usuarios.uid_activo(existente):
            raise
        identidad.delete_account(existente)
        return identidad.create_account(registro.correo, registro.contrasena)


def registrar(
    datos: DatosRegistro,
    hoy: date,
    identidad: ProveedorIdentidad,
    usuarios: RepositorioUsuarios,
) -> UUID:
    registro, errores = validar_registro(datos, hoy)
    if registro is None:
        raise InvalidData(errores)

    if repetidos := usuarios.duplicados(registro.correo, registro.dni):
        raise Duplicate(repetidos)

    uid = _crear_cuenta(registro, identidad, usuarios)
    try:
        return usuarios.insertar(uid, registro)
    except BaseException:
        try:
            identidad.delete_account(uid)
        except Exception:
            registro_log.exception("no se pudo borrar la cuenta %s del proveedor", uid)
        raise
