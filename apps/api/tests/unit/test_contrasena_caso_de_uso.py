from datetime import date
from uuid import UUID

import pytest

from app.modules.session.profile import Profile
from app.modules.users.password import DOES_NOT_MATCH as NO_COINCIDE
from app.modules.users.password import change_password as cambiar_contrasena
from app.shared.errors import InvalidData

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


class Identidad:
    def __init__(self, contrasena: str) -> None:
        self.contrasena = contrasena
        self.cambios: list[tuple[str, str]] = []

    def password_matches(self, email: str, password: str) -> bool:
        return email == PERFIL.email and password == self.contrasena

    def change_password(self, uid: str, new_password: str) -> None:
        self.cambios.append((uid, new_password))


class Rastro:
    def __init__(self) -> None:
        self.marcados: list[UUID] = []

    def mark_password_changed(self, id_usuario: UUID) -> None:
        self.marcados.append(id_usuario)


def test_con_la_actual_correcta_cambia_y_deja_rastro() -> None:
    identidad, rastro = Identidad("ClubNahuel1"), Rastro()
    cambiar_contrasena(PERFIL, "ClubNahuel1", "ClubNahuel2", identidad, rastro)
    assert identidad.cambios == [("u7", "ClubNahuel2")]
    assert rastro.marcados == [UUID(int=7)]


def test_con_la_actual_equivocada_no_cambia_nada() -> None:
    identidad, rastro = Identidad("ClubNahuel1"), Rastro()
    with pytest.raises(InvalidData) as error:
        cambiar_contrasena(PERFIL, "OtraClave9", "ClubNahuel2", identidad, rastro)
    assert error.value.errors == {"current_password": NO_COINCIDE}
    assert identidad.cambios == [] and rastro.marcados == []


@pytest.mark.parametrize(
    ("nueva", "mensaje"),
    [
        ("Corta1", "Al menos 8 caracteres"),
        ("clubnahuel1", "Una letra mayúscula"),
        ("ClubNahuel", "Al menos un número"),
    ],
)
def test_una_nueva_que_no_cumple_las_reglas_se_rechaza_antes_de_mirar_la_actual(
    nueva: str, mensaje: str
) -> None:
    identidad = Identidad("ClubNahuel1")
    with pytest.raises(InvalidData) as error:
        cambiar_contrasena(PERFIL, "equivocada", nueva, identidad, Rastro())
    assert error.value.errors == {"new_password": mensaje}


def test_una_nueva_igual_a_la_actual_se_acepta() -> None:
    """Verifica CU-04-SUP-01."""
    identidad = Identidad("ClubNahuel1")
    cambiar_contrasena(PERFIL, "ClubNahuel1", "ClubNahuel1", identidad, Rastro())
    assert identidad.cambios == [("u7", "ClubNahuel1")]


class RastroQueFalla:
    def mark_password_changed(self, id_usuario: UUID) -> None:
        raise RuntimeError("la base no contesta")


def test_si_falla_el_rastro_el_cambio_igual_se_informa_hecho(
    caplog: pytest.LogCaptureFixture,
) -> None:
    identidad = Identidad("ClubNahuel1")
    cambiar_contrasena(PERFIL, "ClubNahuel1", "ClubNahuel2", identidad, RastroQueFalla())
    assert identidad.cambios == [("u7", "ClubNahuel2")]
    assert "no se pudo registrar el cambio de contraseña" in caplog.text


def test_sin_la_actual_no_se_pregunta_al_proveedor() -> None:
    class SinConsultas(Identidad):
        def password_matches(self, email: str, password: str) -> bool:
            raise AssertionError("no tendría que consultar")

    with pytest.raises(InvalidData) as error:
        cambiar_contrasena(PERFIL, "", "ClubNahuel2", SinConsultas("x"), Rastro())
    assert error.value.errors == {"current_password": NO_COINCIDE}
