from collections.abc import Callable
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def test_a_user_without_the_admin_role_cannot_create_a_space(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """a user without the admin role cannot create a space @CU-21-H01-03"""
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
    with engine.begin() as conn:
        venue: Any = conn.execute(
            text(
                "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede Haedo {s}"},
        ).scalar_one()
    token = sign_in(email, "ClubNahuel1")

    r = api.post(
        "/spaces",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "venue_id": str(venue),
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    )

    # Verifies: the API rejects it for lack of permissions.
    assert r.status_code == 403
    # Verifies: the venue still has no spaces.
    with engine.connect() as conn:
        assert (
            conn.execute(
                text("SELECT count(*) FROM space WHERE venue_id = :s"), {"s": venue}
            ).scalar_one()
            == 0
        )
