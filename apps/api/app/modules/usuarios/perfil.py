from datetime import date
from typing import Protocol

from app.modules.sesion import Perfil
from app.modules.usuarios.reglas import DatosPersonales, PerfilEditado, validar_edicion
from app.shared.errores import DatosInvalidos


class PerfilesEditables(Protocol):
    def actualizar(self, id_usuario: int, editado: PerfilEditado) -> None:
        """Lanza `Duplicado(["dni"])` si otra cuenta activa ya tiene ese DNI."""
        ...


def editar_perfil(
    perfil: Perfil, datos: DatosPersonales, hoy: date, usuarios: PerfilesEditables
) -> None:
    """Guarda los datos personales de quien tiene la sesión. El correo no se toca (RF 2)."""
    editado, errores = validar_edicion(datos, hoy)
    if editado is None:
        raise DatosInvalidos(errores)
    usuarios.actualizar(perfil.id, editado)
