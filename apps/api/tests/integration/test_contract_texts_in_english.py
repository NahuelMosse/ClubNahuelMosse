"""The English contract carries English texts: what ENG-18 kept in main's words, ENG-20 says in English."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import re
import subprocess
import uuid
from collections.abc import Callable
from datetime import datetime
from pathlib import Path
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ROOT = Path(__file__).resolve().parents[4]
MAIN = "805c7f4"
PASSWORD = "ClubNahuel1"


def _auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _register(api: TestClient, unique: str) -> dict[str, str]:
    body = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": str(int(unique, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1998-11-02",
        "email": f"member.{unique}@correo.com",
        "password": PASSWORD,
    }
    assert api.post("/register", json=body).status_code == 201
    return body


def test_an_error_body_names_its_fields_in_english_and_says_its_message_in_english(
    api: TestClient, admin_token: str
) -> None:
    """an error body names its fields in English and says its message in English @ENG-18-S2 @ENG-18-S9 @ENG-20-S1"""
    venue = api.post("/venues", headers=_auth(admin_token), json={})
    assert venue.status_code == 422
    assert venue.json() == {
        "errors": {
            "name": "The name is required",
            "address": "The address is required",
            "opens_at": "The opening time is required",
            "closes_at": "The closing time is required",
            "open_days": "Choose the days it opens",
        }
    }
    signup = api.post("/register", json={})
    assert signup.status_code == 422
    assert set(signup.json()["errors"]) == {
        "first_name", "last_name", "dni", "birth_date", "email", "password"
    }  # fmt: skip
    assert signup.json()["errors"]["first_name"] == "The name is required"


def test_a_void_error_names_reason_and_says_it_in_english(
    api: TestClient, admin_token: str
) -> None:
    """a void error names reason and says it in English @ENG-18-S2 @ENG-20-S1"""
    r = api.post(
        f"/bookings/{uuid.uuid4()}/void",
        headers=_auth(admin_token),
        json={
            "reason": " ",
            "space_id": str(uuid.uuid4()),
            "starts_at": "2030-01-01T10:00:00-03:00",
        },
    )
    assert (r.status_code, r.json()) == (
        422,
        {"errors": {"reason": "The reason is required to void"}},
    )


def test_the_push_data_carries_kind_and_booking_id_with_the_english_kind_and_an_english_text() -> (
    None
):
    """the push data carries kind and booking_id with the English kind and an English text @ENG-18-S5 @ENG-18-S9 @assumption:ENG-18-ASM-10 @ENG-20-S3"""
    from app.modules.notifications.push import build_message
    from app.modules.notifications.rules import (
        VoidedBooking,
        forced_cancellation_message,
        notice_data,
    )

    booking = uuid.uuid4()
    assert notice_data("reminder", booking) == {"kind": "reminder", "booking_id": str(booking)}
    assert notice_data("forced_cancellation", None) == {"kind": "forced_cancellation"}
    notice = forced_cancellation_message(
        [VoidedBooking(booking, datetime.now().astimezone(), "Futbol", "F5", "Venue", "rain")]
    )
    assert notice.title == "The club voided your booking"
    assert build_message(["t"], notice).data == {
        "kind": "forced_cancellation",
        "booking_id": str(booking),
    }


def test_the_english_recovery_email_links_to_link_recover_with_code_and_the_page_opens_the_same_app_route(
    api: TestClient, engine: Engine, unique: Callable[[], str]
) -> None:
    """the English recovery email links to /link/recover with #code and the page opens the same app route @assumption:ENG-18-ASM-06 @ENG-20-S2"""
    account = _register(api, unique())
    assert api.post("/password-recovery", json={"email": account["email"]}).status_code == 202
    with engine.connect() as conn:
        subject, body = conn.execute(
            text(
                "SELECT subject, body FROM outgoing_email WHERE recipient = :p ORDER BY id DESC LIMIT 1"
            ),
            {"p": account["email"]},
        ).one()
    assert subject == "Create a new password"
    assert re.search(r"/link/recover#code=[\w-]+", body) and "/enlace/" not in body
    code = re.search(r"#code=([\w-]+)", body)
    assert code is not None
    assert api.post("/password-recovery/check", json={"code": code.group(1)}).status_code == 204
    page = api.get("/link/recover")
    assert page.status_code == 200
    assert 'get("code")' in page.text and "intent://app/recuperar?codigo=" in page.text


def test_the_catalog_keeps_mains_keys_with_english_names_and_the_seed_keeps_its_options(
    api: TestClient, user_token: str
) -> None:
    """the catalog keeps main's keys with English names and the seed keeps its options @ENG-18-S9 @ENG-20-S4"""
    main_source = subprocess.run(
        ["git", "show", f"{MAIN}:apps/api/app/modules/spaces/rules.py"],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8", check=True,
    ).stdout  # fmt: skip
    main_keys = sorted(
        k for k, _ in re.findall(r'(?:Sport\(\s*|Kind\()"([^"]+)",\s*"([^"]+)"', main_source)
    )
    catalog: list[dict[str, Any]] = api.get("/spaces/catalog", headers=_auth(user_token)).json()[
        "sports"
    ]
    shown = [(s["key"], s["name"]) for s in catalog]
    shown += [(k["key"], k["name"]) for s in catalog for k in s["kinds"]]
    assert sorted(k for k, _ in shown) == main_keys
    names = {name for _, name in shown}
    assert {"Football", "Football 5", "Tennis", "Volleyball", "Basketball 3x3"} <= names
    seed = (ROOT / "apps/api/app/modules/users/seed_admin.py").read_text(encoding="utf-8")
    for option in ("--correo", "--nombre", "--apellido", "--dni", "--nacimiento", "--promover"):
        assert option.lstrip("-") in seed
