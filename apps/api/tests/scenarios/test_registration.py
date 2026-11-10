"""User registration seen from the API: what the screen cannot test by itself."""

from collections.abc import Callable

from fastapi.testclient import TestClient


def test_with_the_newly_created_account_the_user_can_sign_in(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """with the newly created account the user can sign in @CU-03-H01-02

    Checks: after registering, the email and the password chosen open a session, and a different
    password does not. If it fails, the person creates the account and is left out anyway.
    """
    s = unique()
    email = f"Nueva.{s}@Correo.com"
    response = api.post(
        "/register",
        json={
            "first_name": "Nahuel Agustín",
            "last_name": "Mosse",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "2000-03-14",
            "email": email,
            "password": "ClubNahuel1",
        },
    )
    assert response.status_code == 201, response.text

    assert sign_in(email.lower(), "ClubNahuel1") is not None
    assert sign_in(email.lower(), "OtraClave9") is None
