import pytest

from app.aplicacion.contrasena import NO_COINCIDE, cambiar_contrasena
from app.aplicacion.errores import DatosInvalidos
from app.dominio.usuarios import Perfil

PERFIL = Perfil(
    id=7, uid="u7", nombre="Lucía", apellido="Gómez", correo="lucia@correo.com", rol="usuario"
)


class Identidad:
    def __init__(self, contrasena: str) -> None:
        self.contrasena = contrasena
        self.cambios: list[tuple[str, str]] = []

    def contrasena_correcta(self, correo: str, contrasena: str) -> bool:
        return correo == PERFIL.correo and contrasena == self.contrasena

    def cambiar_contrasena(self, uid: str, nueva: str) -> None:
        self.cambios.append((uid, nueva))


class Rastro:
    def __init__(self) -> None:
        self.marcados: list[int] = []

    def marcar_cambio_de_contrasena(self, id_usuario: int) -> None:
        self.marcados.append(id_usuario)


def test_con_la_actual_correcta_cambia_y_deja_rastro() -> None:
    identidad, rastro = Identidad("ClubNahuel1"), Rastro()
    cambiar_contrasena(PERFIL, "ClubNahuel1", "ClubNahuel2", identidad, rastro)
    assert identidad.cambios == [("u7", "ClubNahuel2")]
    assert rastro.marcados == [7]


def test_con_la_actual_equivocada_no_cambia_nada() -> None:
    identidad, rastro = Identidad("ClubNahuel1"), Rastro()
    with pytest.raises(DatosInvalidos) as error:
        cambiar_contrasena(PERFIL, "OtraClave9", "ClubNahuel2", identidad, rastro)
    assert error.value.errores == {"actual": NO_COINCIDE}
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
    with pytest.raises(DatosInvalidos) as error:
        cambiar_contrasena(PERFIL, "equivocada", nueva, identidad, Rastro())
    assert error.value.errores == {"nueva": mensaje}


def test_una_nueva_igual_a_la_actual_se_acepta() -> None:
    """Verifica CU-04-SUP-01."""
    identidad = Identidad("ClubNahuel1")
    cambiar_contrasena(PERFIL, "ClubNahuel1", "ClubNahuel1", identidad, Rastro())
    assert identidad.cambios == [("u7", "ClubNahuel1")]


class RastroQueFalla:
    def marcar_cambio_de_contrasena(self, id_usuario: int) -> None:
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
        def contrasena_correcta(self, correo: str, contrasena: str) -> bool:
            raise AssertionError("no tendría que consultar")

    with pytest.raises(DatosInvalidos) as error:
        cambiar_contrasena(PERFIL, "", "ClubNahuel2", SinConsultas("x"), Rastro())
    assert error.value.errores == {"actual": NO_COINCIDE}
