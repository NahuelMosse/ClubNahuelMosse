from datetime import date

import pytest

from app.modules.users.rules import RegistrationData as DatosRegistro
from app.modules.users.rules import password_problems as problemas_contrasena
from app.modules.users.rules import validate_registration as validar_registro

HOY = date(2026, 11, 12)

def _datos(**cambios: str) -> DatosRegistro:
    base = {
        "first_name": "Nahuel Agustín",
        "last_name": "Mosse",
        "dni": "42.118.507",
        "birth_date": "2000-03-14",
        "email": "  NMosse@UniMoron.edu.ar ",
        "password": "ClubNahuel1",
    }
    base.update(cambios)
    return DatosRegistro(**base)


def test_normaliza_correo_y_dni() -> None:
    registro, errores = validar_registro(_datos(), HOY)
    assert errores == {}
    assert registro is not None
    assert registro.email == "nmosse@unimoron.edu.ar"
    assert registro.dni == "42118507"
    assert registro.birth_date == date(2000, 3, 14)


@pytest.mark.parametrize(
    ("campo", "mensaje"),
    [
        ("first_name", "El nombre es obligatorio"),
        ("last_name", "El apellido es obligatorio"),
        ("dni", "El DNI es obligatorio"),
        ("birth_date", "La fecha de nacimiento es obligatoria"),
        ("email", "El correo es obligatorio"),
        ("password", "La contraseña es obligatoria"),
    ],
)
def test_cada_campo_es_obligatorio(campo: str, mensaje: str) -> None:
    registro, errores = validar_registro(
        _datos(**{campo: "   " if campo != "password" else ""}), HOY
    )
    assert registro is None
    assert errores == {campo: mensaje}


@pytest.mark.parametrize(
    ("dni", "valido"),
    [
        ("1234567", True),
        ("12345678", True),
        ("12.345.678", True),
        ("123456", False),
        ("123456789", False),
        ("12a45678", False),
    ],
)
def test_dni_de_7_u_8_numeros(dni: str, valido: bool) -> None:
    _, errores = validar_registro(_datos(dni=dni), HOY)
    assert ("dni" not in errores) is valido
    if not valido:
        assert errores["dni"] == "El DNI tiene 7 u 8 números"


@pytest.mark.parametrize(
    ("fecha", "mensaje"),
    [
        ("2026-11-12", "La fecha tiene que ser anterior a hoy"),
        ("2030-01-01", "La fecha tiene que ser anterior a hoy"),
        ("2000-02-30", "La fecha no es válida"),
        ("14/03/2000", "La fecha no es válida"),
    ],
)
def test_fecha_de_nacimiento(fecha: str, mensaje: str) -> None:
    _, errores = validar_registro(_datos(birth_date=fecha), HOY)
    assert errores == {"birth_date": mensaje}


def test_fecha_de_ayer_es_valida() -> None:
    _, errores = validar_registro(_datos(birth_date="2026-11-11"), HOY)
    assert errores == {}


@pytest.mark.parametrize("correo", ["sinarroba.com", "a@b", "a b@c.com", "a@@c.com"])
def test_formato_de_correo(correo: str) -> None:
    _, errores = validar_registro(_datos(email=correo), HOY)
    assert errores == {"email": "Revisá el formato del correo"}


@pytest.mark.parametrize(
    ("contrasena", "faltan"),
    [
        ("Club1", ["Al menos 8 caracteres"]),
        ("clubnahuel1", ["Una letra mayúscula"]),
        ("ClubNahuel", ["Al menos un número"]),
        ("club", ["Al menos 8 caracteres", "Una letra mayúscula", "Al menos un número"]),
        ("ClubNahuel1", []),
        ("Ñandúes123", []),
    ],
)
def test_reglas_de_contrasena(contrasena: str, faltan: list[str]) -> None:
    assert problemas_contrasena(contrasena) == faltan


def test_nombre_de_hasta_60_caracteres() -> None:
    _, errores = validar_registro(_datos(first_name="a" * 60), HOY)
    assert errores == {}
    _, errores = validar_registro(_datos(first_name="a" * 61), HOY)
    assert errores == {"first_name": "Máximo 60 caracteres"}
