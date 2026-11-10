from collections.abc import Callable

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def test_a_user_without_the_admin_role_cannot_create_a_venue(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """a user without the admin role cannot create a venue @CU-17-H01-03"""
    s = unique()
    email = f"socio.{s}@correo.com"
    assert (
        api.post(
            "/register",
            json={
                "first_name": "Martín",
                "last_name": "Ferreyra",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
                "birth_date": "1994-07-21",
                "email": email,
                "password": "ClubNahuel1",
            },
        ).status_code
        == 201
    )
    token = sign_in(email, "ClubNahuel1")
    name = f"Sede Haedo {s}"

    r = api.post(
        "/venues",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "name": name,
            "address": "Av. Vergara 1850",
            "opens_at": "08:00",
            "closes_at": "23:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    )

    # Verifies: the API rejects it for lack of permissions.
    assert r.status_code == 403
    # Verifies: the venue was not saved.
    with engine.connect() as conn:
        assert (
            conn.execute(
                text("SELECT count(*) FROM venue WHERE name = :n"), {"n": name}
            ).scalar_one()
            == 0
        )
