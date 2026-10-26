from datetime import date

import pytest

from app.modules.usuarios.perfil import editar_perfil
from app.modules.usuarios.reglas import DatosPersonales, PerfilEditado
from app.modules.sesion.perfil import Perfil
from app.shared.errores import DatosInvalidos

HOY = date(2026, 9, 27)
PERFIL = Perfil(
    id=7,
    uid="u7",
    nombre="Lucía",
    apellido="Gómez",
    correo="lucia@correo.com",
    rol="usuario",
    dni="30111222",
    fecha_nacimiento=date(1998, 11, 2),
)


class Perfiles:
    def __init__(self) -> None:
        self.guardados: list[tuple[int, PerfilEditado]] = []

    def actualizar(self, id_usuario: int, editado: PerfilEditado) -> None:
        self.guardados.append((id_usuario, editado))


def test_guarda_los_datos_normalizados() -> None:
    perfiles = Perfiles()
    editar_perfil(
        PERFIL, DatosPersonales(" Ana ", " Díaz ", "30.111.223", "1985-06-01"), HOY, perfiles
    )
    assert perfiles.guardados == [(7, PerfilEditado("Ana", "Díaz", "30111223", date(1985, 6, 1)))]


@pytest.mark.parametrize(
    ("datos", "campos"),
    [
        (DatosPersonales("", "Díaz", "30111223", "1985-06-01"), {"nombre"}),
        (DatosPersonales("Ana", "Díaz", "42118", "1985-06-01"), {"dni"}),
        (DatosPersonales("Ana", "Díaz", "30111223", "2000-13-32"), {"fecha_nacimiento"}),
        (DatosPersonales("Ana", "Díaz", "30111223", "2026-09-27"), {"fecha_nacimiento"}),
        (DatosPersonales("A" * 61, "Díaz", "30111223", "1985-06-01"), {"nombre"}),
    ],
)
def test_un_dato_invalido_no_guarda_nada(datos: DatosPersonales, campos: set[str]) -> None:
    """Verifica CU-06-SUP-01 y CU-06-SUP-04."""
    perfiles = Perfiles()
    with pytest.raises(DatosInvalidos) as error:
        editar_perfil(PERFIL, datos, HOY, perfiles)
    assert set(error.value.errores) == campos
    assert perfiles.guardados == []
