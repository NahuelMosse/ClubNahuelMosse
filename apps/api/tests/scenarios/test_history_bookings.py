from collections.abc import Callable

from fastapi.testclient import TestClient


def test_the_api_rejects_the_global_bookings_query_from_a_user_without_the_admin_role(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """the API rejects the global bookings query from a user without the admin role @CU-14-H05-02"""
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

    r = api.get(
        "/bookings/all",
        headers={"Authorization": f"Bearer {token}"},
    )

    # Verifies: the API rejects it for lack of permissions, not because of a data error.
    assert r.status_code == 403
