"""User profile rules. The messages are the ones the app shows."""

import re
from dataclasses import dataclass
from datetime import date

NAME_MAX_LENGTH = 60
PASSWORD_MIN_LENGTH = 8


@dataclass(frozen=True)
class RegistrationData:
    first_name: str
    last_name: str
    dni: str
    birth_date: str
    email: str
    password: str


@dataclass(frozen=True)
class Registration:
    first_name: str
    last_name: str
    dni: str
    birth_date: date
    email: str
    password: str


_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def normalize_email(email: str) -> str:
    return email.strip().lower()


def valid_email(email: str) -> bool:
    return _EMAIL.fullmatch(email) is not None


def normalize_dni(dni: str) -> str:
    return re.sub(r"[.\s]", "", dni.strip())


def password_problems(password: str) -> list[str]:
    """The rules it does not meet, in the order the app shows them."""
    missing = []
    if len(password) < PASSWORD_MIN_LENGTH:
        missing.append(f"Al menos {PASSWORD_MIN_LENGTH} caracteres")
    if not re.search(r"[A-ZÁÉÍÓÚÑ]", password):
        missing.append("Una letra mayúscula")
    if not re.search(r"[0-9]", password):
        missing.append("Al menos un número")
    return missing


def _date(text: str) -> date | None:
    try:
        return date.fromisoformat(text.strip())
    except ValueError:
        return None


@dataclass(frozen=True)
class PersonalData:
    """What the person can change in their profile: everything but the email (RF 2)."""

    first_name: str
    last_name: str
    dni: str
    birth_date: str


@dataclass(frozen=True)
class EditedProfile:
    first_name: str
    last_name: str
    dni: str
    birth_date: date


def _personal_errors(data: PersonalData, today: date) -> tuple[dict[str, str], str, date | None]:
    """The first name, last name, DNI and date rules, shared by sign-up and editing."""
    errors: dict[str, str] = {}

    for field, value, required in (
        ("first_name", data.first_name, "El nombre es obligatorio"),
        ("last_name", data.last_name, "El apellido es obligatorio"),
    ):
        clean = value.strip()
        if not clean:
            errors[field] = required
        elif len(clean) > NAME_MAX_LENGTH:
            errors[field] = f"Máximo {NAME_MAX_LENGTH} caracteres"

    dni = normalize_dni(data.dni)
    if not dni:
        errors["dni"] = "El DNI es obligatorio"
    elif not re.fullmatch(r"[0-9]{7,8}", dni):
        errors["dni"] = "El DNI tiene 7 u 8 números"

    birth_date = _date(data.birth_date)
    if not data.birth_date.strip():
        errors["birth_date"] = "La fecha de nacimiento es obligatoria"
    elif birth_date is None:
        errors["birth_date"] = "La fecha no es válida"
    elif birth_date >= today:
        errors["birth_date"] = "La fecha tiene que ser anterior a hoy"

    return errors, dni, birth_date


def validate_registration(
    data: RegistrationData, today: date
) -> tuple[Registration | None, dict[str, str]]:
    """Returns the normalized registration, or the errors per field if there are any."""
    errors, dni, birth_date = _personal_errors(
        PersonalData(data.first_name, data.last_name, data.dni, data.birth_date), today
    )

    email = normalize_email(data.email)
    if not email:
        errors["email"] = "El correo es obligatorio"
    elif not _EMAIL.fullmatch(email):
        errors["email"] = "Revisá el formato del correo"

    if not data.password:
        errors["password"] = "La contraseña es obligatoria"
    elif missing := password_problems(data.password):
        errors["password"] = missing[0]

    if errors or birth_date is None:
        return None, errors
    return (
        Registration(
            first_name=data.first_name.strip(),
            last_name=data.last_name.strip(),
            dni=dni,
            birth_date=birth_date,
            email=email,
            password=data.password,
        ),
        {},
    )


def validate_edit(data: PersonalData, today: date) -> tuple[EditedProfile | None, dict[str, str]]:
    """The normalized personal data, or the errors per field if there are any."""
    errors, dni, birth_date = _personal_errors(data, today)
    if errors or birth_date is None:
        return None, errors
    return (
        EditedProfile(
            first_name=data.first_name.strip(),
            last_name=data.last_name.strip(),
            dni=dni,
            birth_date=birth_date,
        ),
        {},
    )
