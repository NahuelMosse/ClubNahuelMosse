from datetime import date

import pytest

from app.modules.users.rules import RegistrationData, password_problems, validate_registration

TODAY = date(2026, 11, 12)


def _data(**changes: str) -> RegistrationData:
    base = {
        "first_name": "Nahuel Agustín",
        "last_name": "Mosse",
        "dni": "42.118.507",
        "birth_date": "2000-03-14",
        "email": "  NMosse@UniMoron.edu.ar ",
        "password": "ClubNahuel1",
    }
    base.update(changes)
    return RegistrationData(**base)


def test_normalizes_email_and_dni() -> None:
    registration, errors = validate_registration(_data(), TODAY)
    assert errors == {}
    assert registration is not None
    assert registration.email == "nmosse@unimoron.edu.ar"
    assert registration.dni == "42118507"
    assert registration.birth_date == date(2000, 3, 14)


@pytest.mark.parametrize(
    ("field", "message"),
    [
        ("first_name", "The name is required"),
        ("last_name", "The last name is required"),
        ("dni", "The DNI is required"),
        ("birth_date", "The birth date is required"),
        ("email", "The email is required"),
        ("password", "The password is required"),
    ],
)
def test_each_field_is_required(field: str, message: str) -> None:
    registration, errors = validate_registration(
        _data(**{field: "   " if field != "password" else ""}), TODAY
    )
    assert registration is None
    assert errors == {field: message}


@pytest.mark.parametrize(
    ("dni", "valid"),
    [
        ("1234567", True),
        ("12345678", True),
        ("12.345.678", True),
        ("123456", False),
        ("123456789", False),
        ("12a45678", False),
    ],
)
def test_dni_of_7_or_8_digits(dni: str, valid: bool) -> None:
    _, errors = validate_registration(_data(dni=dni), TODAY)
    assert ("dni" not in errors) is valid
    if not valid:
        assert errors["dni"] == "The DNI has 7 or 8 digits"


@pytest.mark.parametrize(
    ("value", "message"),
    [
        ("2026-11-12", "The date must be before today"),
        ("2030-01-01", "The date must be before today"),
        ("2000-02-30", "The date is not valid"),
        ("14/03/2000", "The date is not valid"),
    ],
)
def test_birth_date(value: str, message: str) -> None:
    _, errors = validate_registration(_data(birth_date=value), TODAY)
    assert errors == {"birth_date": message}


def test_yesterdays_date_is_valid() -> None:
    _, errors = validate_registration(_data(birth_date="2026-11-11"), TODAY)
    assert errors == {}


@pytest.mark.parametrize("email", ["sinarroba.com", "a@b", "a b@c.com", "a@@c.com"])
def test_email_format(email: str) -> None:
    _, errors = validate_registration(_data(email=email), TODAY)
    assert errors == {"email": "Check the email format"}


@pytest.mark.parametrize(
    ("password", "missing"),
    [
        ("Club1", ["At least 8 characters"]),
        ("clubnahuel1", ["An uppercase letter"]),
        ("ClubNahuel", ["At least one number"]),
        ("club", ["At least 8 characters", "An uppercase letter", "At least one number"]),
        ("ClubNahuel1", []),
        ("Ñandúes123", []),
    ],
)
def test_password_rules(password: str, missing: list[str]) -> None:
    assert password_problems(password) == missing


def test_name_of_up_to_60_characters() -> None:
    _, errors = validate_registration(_data(first_name="a" * 60), TODAY)
    assert errors == {}
    _, errors = validate_registration(_data(first_name="a" * 61), TODAY)
    assert errors == {"first_name": "At most 60 characters"}
