from datetime import date
from typing import Protocol

from app.aplicacion.errores import DatosInvalidos
from app.dominio.usuarios import DatosPersonales, Perfil, PerfilEditado, validar_edicion


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
