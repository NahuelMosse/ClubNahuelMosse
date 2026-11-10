"""Password recovery against the real database and emulator, with the mailbox."""

import re
import time
from collections.abc import Callable
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

OLD = "ClubNahuel1"
NEW = "ClubNahuel2"


def _register(api: TestClient, s: str) -> str:
    email = f"socia.{s}@correo.com"
    payload = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1998-11-02",
        "email": email,
        "password": OLD,
    }
    assert api.post("/register", json=payload).status_code == 201
    return email


def _codes(engine: Engine, email: str) -> list[str]:
    with engine.connect() as conn:
        bodies: Any = conn.execute(
            text("SELECT body FROM outgoing_email WHERE recipient = :p ORDER BY id"), {"p": email}
        ).scalars()
        return [m.group(1) for c in bodies if (m := re.search(r"#code=([\w-]+)", c))]


def test_requesting_and_using_the_link_changes_the_password_only_once(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    email = _register(api, unique())
    token = sign_in(email, OLD)
    time.sleep(1.1)
    assert api.post("/password-recovery", json={"email": email.upper()}).status_code == 202
    (code,) = _codes(engine, email)

    assert api.post("/password-recovery/check", json={"code": code}).status_code == 204
    assert (
        api.put("/password-recovery", json={"code": code, "new_password": NEW}).status_code == 204
    )

    assert sign_in(email, OLD) is None
    assert sign_in(email, NEW) is not None
    # The sessions opened before expired.
    assert api.get("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401
    assert api.post("/password-recovery/check", json={"code": code}).status_code == 410
    assert (
        api.put(
            "/password-recovery", json={"code": code, "new_password": "ClubNahuel3"}
        ).status_code
        == 410
    )


def test_an_email_without_an_account_gets_the_same_response_and_no_mail(
    api: TestClient, engine: Engine, unique: Callable[[], str]
) -> None:
    email = f"nadie.{unique()}@correo.com"
    r = api.post("/password-recovery", json={"email": email})
    assert (r.status_code, r.content) == (202, b"")
    assert _codes(engine, email) == []


def test_a_deactivated_account_gets_no_link(
    api: TestClient, engine: Engine, unique: Callable[[], str]
) -> None:
    """Checks CU-04b-SUP-01."""
    email = _register(api, unique())
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE app_user SET active = false, deactivated_at = now() WHERE email = :c"),
            {"c": email},
        )
    assert api.post("/password-recovery", json={"email": email}).status_code == 202
    assert _codes(engine, email) == []


def test_resending_invalidates_the_previous_link_and_there_is_an_hourly_cap(
    api: TestClient, engine: Engine, unique: Callable[[], str]
) -> None:
    email = _register(api, unique())
    for _ in range(4):
        assert api.post("/password-recovery", json={"email": email}).status_code == 202
    codes = _codes(engine, email)
    assert len(codes) == 3
    assert [api.post("/password-recovery/check", json={"code": c}).status_code for c in codes] == [
        410,
        410,
        204,
    ]


def test_changing_the_password_another_way_invalidates_the_links(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """Checks CU-04b-SUP-03."""
    email = _register(api, unique())
    api.post("/password-recovery", json={"email": email})
    (code,) = _codes(engine, email)
    token = sign_in(email, OLD)
    r = api.put(
        "/me/password",
        headers={"Authorization": f"Bearer {token}"},
        json={"current_password": OLD, "new_password": NEW},
    )
    assert r.status_code == 204
    assert api.post("/password-recovery/check", json={"code": code}).status_code == 410


def test_a_weak_password_is_rejected_and_the_link_still_works(
    api: TestClient, engine: Engine, unique: Callable[[], str]
) -> None:
    email = _register(api, unique())
    api.post("/password-recovery", json={"email": email})
    (code,) = _codes(engine, email)
    r = api.put("/password-recovery", json={"code": code, "new_password": "ClubNahuel"})
    assert r.status_code == 422
    assert r.json() == {"errors": {"new_password": "At least one number"}}
    assert api.post("/password-recovery/check", json={"code": code}).status_code == 204


def test_an_invented_code_does_not_work(api: TestClient) -> None:
    assert api.post("/password-recovery/check", json={"code": "inventado"}).status_code == 410
    assert api.post("/password-recovery/check", json={}).status_code == 410
    assert (
        api.put("/password-recovery", json={"code": "inventado", "new_password": NEW}).status_code
        == 410
    )


def test_a_misspelled_email_is_rejected(api: TestClient) -> None:
    r = api.post("/password-recovery", json={"email": "lucia@correo"})
    assert r.status_code == 422
    assert r.json() == {"errors": {"email": "Check the email format"}}


def test_without_test_mode_the_mailbox_does_not_exist(api: TestClient) -> None:
    assert api.get("/_testing/emails", params={"para": "x@y.com"}).status_code == 404


def test_the_email_link_is_https_and_the_code_does_not_reach_the_server(
    api: TestClient, engine: Engine, unique: Callable[[], str]
) -> None:
    email = _register(api, unique())
    api.post("/password-recovery", json={"email": email})
    with engine.connect() as conn:
        body: Any = conn.execute(
            text("SELECT body FROM outgoing_email WHERE recipient = :p"), {"p": email}
        ).scalar_one()
    link = re.search(r"(\S+/link/recover)#code=", body)
    assert link is not None and link.group(1).startswith("http")
    page = api.get("/link/recover")
    assert page.status_code == 200
    assert "intent://app/recuperar?codigo=" in page.text
    assert "package=ar.edu.unimoron.clubnahuelmosse" in page.text
    assert page.headers["referrer-policy"] == "no-referrer"


def test_simultaneous_requests_do_not_leave_two_valid_links(
    api: TestClient, engine: Engine, unique: Callable[[], str]
) -> None:
    from concurrent.futures import ThreadPoolExecutor

    email = _register(api, unique())
    with ThreadPoolExecutor(max_workers=6) as pool:
        http_codes = list(
            pool.map(
                lambda _: api.post("/password-recovery", json={"email": email}).status_code,
                range(6),
            )
        )
    assert http_codes == [202] * 6
    codes = _codes(engine, email)
    assert len(codes) == 3
    valid = [
        c
        for c in codes
        if api.post("/password-recovery/check", json={"code": c}).status_code == 204
    ]
    assert len(valid) == 1
