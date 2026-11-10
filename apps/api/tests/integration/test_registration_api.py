"""The registration endpoint against the real database and emulator."""

from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor

from fastapi.testclient import TestClient


def _payload(s: str, **changes: str) -> dict[str, str]:
    base = {
        "first_name": "Ana",
        "last_name": "Pérez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "2000-03-14",
        "email": f"ana.{s}@correo.com",
        "password": "ClubNahuel1",
    }
    base.update(changes)
    return base


def test_invalid_data_returns_the_errors_per_field(
    api: TestClient, unique: Callable[[], str]
) -> None:
    r = api.post("/register", json=_payload(unique(), dni="123", password="corta"))
    assert r.status_code == 422
    assert r.json() == {
        "errors": {"dni": "The DNI has 7 or 8 digits", "password": "At least 8 characters"}
    }


def test_repeated_email_regardless_of_case(api: TestClient, unique: Callable[[], str]) -> None:
    s = unique()
    assert api.post("/register", json=_payload(s)).status_code == 201
    r = api.post("/register", json=_payload(unique(), email=f"  ANA.{s}@Correo.com "))
    assert r.status_code == 409
    assert r.json() == {
        "message": "The user is already registered. Change the email or the DNI.",
        "fields": ["email"],
        "errors": {"email": "This email is already registered"},
    }


def test_repeated_dni_even_if_written_with_dots(api: TestClient, unique: Callable[[], str]) -> None:
    s = unique()
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    assert api.post("/register", json=_payload(s, dni=dni)).status_code == 201
    with_dots = f"{dni[:2]}.{dni[2:5]}.{dni[5:]}"
    r = api.post("/register", json=_payload(unique(), dni=with_dots))
    assert r.status_code == 409
    assert r.json()["fields"] == ["dni"]


def test_repeated_email_and_dni_at_once(api: TestClient, unique: Callable[[], str]) -> None:
    s = unique()
    assert api.post("/register", json=_payload(s)).status_code == 201
    r = api.post("/register", json=_payload(s))
    assert r.status_code == 409
    assert r.json()["fields"] == ["email", "dni"]


def test_two_simultaneous_registrations_the_second_is_409(
    api: TestClient, unique: Callable[[], str]
) -> None:
    s = unique()
    payloads = [_payload(s), _payload(unique(), dni=_payload(s)["dni"])]
    with ThreadPoolExecutor(max_workers=2) as pool:
        codes = sorted(
            r.status_code for r in pool.map(lambda p: api.post("/register", json=p), payloads)
        )
    assert codes == [201, 409]


def test_the_openapi_documentation_describes_the_registration(api: TestClient) -> None:
    schema = api.get("/openapi.json").json()
    assert "/register" in schema["paths"]
    assert {"201", "409", "422"} <= set(schema["paths"]["/register"]["post"]["responses"])


def test_a_firebase_account_without_a_profile_does_not_block_the_registration(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    from firebase_admin import auth

    from app.shared.identity import _firebase_app

    s = unique()
    email = f"huerfana.{s}@correo.com"
    auth.create_user(email=email, password="OtraClave9", app=_firebase_app())

    r = api.post("/register", json=_payload(s, email=email))
    assert r.status_code == 201, r.text
    assert sign_in(email, "ClubNahuel1") is not None
    assert sign_in(email, "OtraClave9") is None
