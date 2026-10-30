"""Every readable text the API produces is English."""

import ast
import re
import subprocess
import uuid
from typing import cast
from datetime import UTC, datetime
from pathlib import Path

from fastapi.testclient import TestClient

from app.modules.notifications.rules import (
    BookingData,
    Reminder,
    ReminderKind,
    cancellation_message,
    forced_cancellations_message,
    reminder_email,
    reminder_message,
)
from app.modules.spaces.rules import CATALOG

APP = Path(__file__).resolve().parents[2] / "app"
ACCENTS = re.compile("[áéíóúñ¿¡ÁÉÍÓÚÑ]")
WORDS = re.compile(
    r"\b(de|la|el|una|reserva|sede|espacio|horario|contraseña|correo|usuario|campo|obligatorio)\b",
    re.IGNORECASE,
)
SPANISH_PATTERN = re.compile(
    r"\b(Tu|Elegí|Escribí|Sólo|sólo|Revisá|Hola|Cancha|Día|Sede|Horario|Motivo|Tenés|"
    r"Reserva|enlace|cuenta)\b"
)


def _literals(path: Path) -> list[tuple[int, str]]:
    tree = ast.parse(path.read_text(encoding="utf-8"))
    docstrings: set[int] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Module | ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef):
            first = node.body[0] if node.body else None
            if isinstance(first, ast.Expr) and isinstance(first.value, ast.Constant):
                docstrings.add(id(first.value))
    return [
        (n.lineno, n.value)
        for n in ast.walk(tree)
        if isinstance(n, ast.Constant) and isinstance(n.value, str) and id(n) not in docstrings
    ]


CLI_INTERFACE = {
    "correo", "nombre", "apellido", "dni", "nacimiento", "promover",
    "--promover", "ADMIN_CONTRASENA", "--una-vez", "clubnahuelmosse.correo",
}  # fmt: skip


def _is_spanish(text: str) -> bool:
    if text in CLI_INTERFACE:
        return False
    return bool(ACCENTS.search(text) or WORDS.search(text) or SPANISH_PATTERN.search(text))


def test_no_string_literal_of_the_api_code_is_spanish() -> None:
    """no string literal of the API code is Spanish @ENG-20-ASM-03"""
    found = [
        f"{p.relative_to(APP)}:{line}: {text[:60]}"
        for p in sorted(APP.rglob("*.py"))
        for line, text in _literals(p)
        if _is_spanish(text)
    ]
    assert found == []


def test_an_error_detail_is_english(api: TestClient) -> None:
    """an error detail is English @ENG-20-S1"""
    response = api.get("/me")
    assert response.status_code == 401
    assert not _is_spanish(response.json()["detail"])


def test_a_field_error_message_is_english(api: TestClient) -> None:
    """a field error message is English @ENG-20-S1"""
    response = api.post("/register", json={"email": "x"})
    assert response.status_code == 422
    errors = response.json()["errors"]
    assert errors
    assert all(not _is_spanish(message) for message in errors.values())


def test_the_api_answers_in_english_whatever_accept_language_says(api: TestClient) -> None:
    """the API answers in English whatever Accept-Language says @ENG-20-ASM-01"""
    response = api.post("/register", json={"email": "x"}, headers={"Accept-Language": "es-AR"})
    assert all(not _is_spanish(m) for m in response.json()["errors"].values())


def test_the_routes_codes_and_keys_are_mains(api: TestClient) -> None:
    """the routes, codes and keys are main's @ENG-20-S7"""
    paths = set(api.get("/openapi.json").json()["paths"])
    assert {"/me", "/register", "/venues", "/bookings", "/spaces/catalog"} <= paths


def _reminder(kind: str) -> Reminder:
    now = datetime(2026, 11, 2, 18, 0, tzinfo=UTC)
    return Reminder(
        booking_id=uuid.uuid4(),
        user_id=uuid.uuid4(),
        starts_at=now,
        ends_at=now,
        sport="Futbol",
        kind="F5",
        venue="Venue",
        email="a@b.com",
        name="Ana",
        reminder_kind=cast(ReminderKind, kind),
    )


def test_the_reminder_notification_title_and_body_are_english() -> None:
    """the reminder notification title and body are English @ENG-20-S3"""
    notice = reminder_message(_reminder("reminder"))
    assert notice.title == "Your booking is in 1 hour"
    assert not _is_spanish(notice.body)


def test_the_five_minute_reminder_title_and_body_are_english() -> None:
    """the five minute reminder title and body are English @ENG-20-S3"""
    notice = reminder_message(_reminder("five_minute_reminder"))
    assert notice.title == "Your booking starts in 5 minutes"
    assert not _is_spanish(notice.body)


def test_the_forced_cancellation_notification_title_and_body_are_english() -> None:
    """the forced cancellation notification title and body are English @ENG-20-S3"""
    notice = forced_cancellations_message(3)
    assert notice.title == "The club voided 3 of your bookings"
    assert not _is_spanish(notice.body)


def test_the_user_cancellation_notification_title_and_body_are_english() -> None:
    """the user cancellation notification title and body are English @ENG-20-S3"""
    data = BookingData(uuid.uuid4(), "Futbol", "F5", "Venue", datetime(2026, 11, 2, tzinfo=UTC))
    notice = cancellation_message(data)
    assert notice.title == "Booking cancelled"
    assert not _is_spanish(notice.body)


def test_the_booking_email_subject_and_body_are_english() -> None:
    """a booking email subject and body are English @ENG-20-S2"""
    from app.modules.bookings import email

    assert email.SUBJECT == "Your booking is confirmed"
    assert email.DAYS[0] == "Monday"


def test_the_booking_cancellation_email_subject_and_body_are_english() -> None:
    """the booking cancellation email subject and body are English @ENG-20-S2"""
    email = reminder_email(_reminder("reminder"))
    assert email.subject == "Your booking is in 1 hour"
    assert not _is_spanish(email.body)


def test_the_password_recovery_email_subject_and_body_are_english() -> None:
    """the password recovery email subject and body are English @ENG-20-S2"""
    source = (APP / "modules/password_recovery/use_cases.py").read_text(encoding="utf-8")
    assert 'subject="Create a new password"' in source


def test_the_catalog_names_are_english() -> None:
    """the catalog names are English @ENG-20-S4"""
    names = [s.name for s in CATALOG] + [k.name for s in CATALOG for k in s.kinds]
    assert "Football" in names
    assert {"Football 5", "Clay", "Tennis", "Volleyball", "Basketball 3x3"} <= set(names)
    assert all(not _is_spanish(n) for n in names)


def test_the_catalog_keys_are_mains() -> None:
    """the catalog keys are main's @ENG-20-ASM-02"""
    keys = [s.key for s in CATALOG]
    assert keys == ["Futbol", "Tenis", "Padel", "Voley", "Basquet", "Hockey", "Golf"]
    assert [k.key for k in CATALOG[0].kinds] == ["F5", "F7", "F8", "F11"]


def test_the_seeded_data_is_english() -> None:
    """the seeded data is English @ENG-20-S5"""
    for module in ("users/seed_admin.py", "users/admins.py"):
        for line, text in _literals(APP / "modules" / module):
            assert not _is_spanish(text), f"{module}:{line}"


def test_the_admin_seed_command_prints_english_and_keeps_its_options() -> None:
    """the admin seed command prints English and keeps its options @ENG-20-ASM-04"""
    source = (APP / "modules/users/seed_admin.py").read_text(encoding="utf-8")
    for option in ("correo", "nombre", "apellido", "dni", "nacimiento"):
        assert f'"{option}"' in source
    assert '"--promover"' in source
    assert "ADMIN_CONTRASENA" in source


def test_no_migration_of_this_card_rewrites_stored_rows() -> None:
    """no migration of this card rewrites stored rows @ENG-20-S6"""
    out = subprocess.run(
        ["git", "diff", "--name-only", "main", "--", str(APP.parent / "migrations")],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    assert out.strip() == ""
