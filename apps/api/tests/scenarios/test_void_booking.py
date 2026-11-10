from collections.abc import Callable

from fastapi.testclient import TestClient


def test_the_api_rejects_a_void_requested_by_a_user_without_the_admin_role(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """the API rejects a void requested by a user without the admin role @CU-15-H01-04"""
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

    r = api.post(
        "/bookings/00000000-0000-7000-8000-000000000001/void",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "reason": "mantenimiento de la cancha",
            "space_id": "00000000-0000-7000-8000-000000000002",
            "starts_at": "2030-01-01T21:00:00-03:00",
        },
    )

    # Checks: the API rejects it for lack of permissions, not for a data error.
    assert r.status_code == 403
