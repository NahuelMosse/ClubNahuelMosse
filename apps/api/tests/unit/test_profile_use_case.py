from datetime import date
from uuid import UUID

import pytest

from app.modules.session.profile import Profile
from app.modules.users.profile import update_profile as editar_perfil
from app.modules.users.rules import EditedProfile as PerfilEditado
from app.modules.users.rules import PersonalData as DatosPersonales
from app.shared.errors import InvalidData

HOY = date(2026, 9, 27)
PERFIL = Profile(
    id=UUID(int=7),
    uid="u7",
    first_name="Lucía",
    last_name="Gómez",
    email="lucia@correo.com",
    role="user",
    dni="30111222",
    birth_date=date(1998, 11, 2),
)


class Perfiles:
    def __init__(self) -> None:
        self.guardados: list[tuple[UUID, PerfilEditado]] = []

    def update(self, id_usuario: UUID, editado: PerfilEditado) -> None:
        self.guardados.append((id_usuario, editado))


def test_guarda_los_datos_normalizados() -> None:
    perfiles = Perfiles()
    editar_perfil(
        PERFIL, DatosPersonales(" Ana ", " Díaz ", "30.111.223", "1985-06-01"), HOY, perfiles
    )
    assert perfiles.guardados == [
        (UUID(int=7), PerfilEditado("Ana", "Díaz", "30111223", date(1985, 6, 1)))
    ]


@pytest.mark.parametrize(
    ("datos", "campos"),
    [
        (DatosPersonales("", "Díaz", "30111223", "1985-06-01"), {"first_name"}),
        (DatosPersonales("Ana", "Díaz", "42118", "1985-06-01"), {"dni"}),
        (DatosPersonales("Ana", "Díaz", "30111223", "2000-13-32"), {"birth_date"}),
        (DatosPersonales("Ana", "Díaz", "30111223", "2026-09-27"), {"birth_date"}),
        (DatosPersonales("A" * 61, "Díaz", "30111223", "1985-06-01"), {"first_name"}),
    ],
)
def test_un_dato_invalido_no_guarda_nada(datos: DatosPersonales, campos: set[str]) -> None:
    """Verifica CU-06-SUP-01 y CU-06-SUP-04."""
    perfiles = Perfiles()
    with pytest.raises(InvalidData) as error:
        editar_perfil(PERFIL, datos, HOY, perfiles)
    assert set(error.value.errors) == campos
    assert perfiles.guardados == []
