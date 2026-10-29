"""The HTTP contract speaks English: routes, fields, values, parameters and operationIds."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import json
import re
import subprocess
import uuid
from collections.abc import Callable
from datetime import date, timedelta
from pathlib import Path
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from tests import contract_renames as renames

ROOT = Path(__file__).resolve().parents[4]
MAIN = "805c7f4"
PASSWORD = "ClubNahuel1"


def _main_contract() -> dict[str, Any]:
    shown = subprocess.run(
        ["git", "show", f"{MAIN}:apps/api/openapi.json"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=True,
    ).stdout
    contract: dict[str, Any] = json.loads(shown)
    return contract


def _auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _register(api: TestClient, unique: str, **changes: str) -> dict[str, str]:
    body = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": str(int(unique, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1998-11-02",
        "email": f"socia.{unique}@correo.com",
        "password": PASSWORD,
    } | changes
    assert api.post("/register", json=body).status_code == 201
    return body


def _space(api: TestClient, admin: str, venue_id: str, number: int | None = None) -> dict[str, Any]:
    body: dict[str, Any] = {
        "venue_id": venue_id,
        "sport": "Futbol",
        "kind": "F5",
        "covered": False,
        "lit": True,
        "price_per_hour": 38000,
    }
    if number is not None:
        body["number"] = number
    r = api.post("/spaces", headers=_auth(admin), json=body)
    assert r.status_code == 201
    created: dict[str, Any] = r.json()
    return created


def _book(api: TestClient, token: str, space_id: str, days: int = 1) -> Any:
    return api.post(
        "/bookings",
        headers=_auth(token),
        json={
            "space_id": space_id,
            "date": (date.today() + timedelta(days=days)).isoformat(),
            "start_hour": "21:00",
            "hours": 1,
        },
    )


def test_every_route_of_the_published_contract_is_named_as_the_glossary_says(api: TestClient) -> None:
    """every route of the published contract is named as the glossary says @ENG-18-S1 @assumption:ENG-18-ASM-01"""
    published = set(api.get("/openapi.json").json()["paths"])
    main = set(_main_contract()["paths"])
    assert published == {renames.PATHS[p] for p in main}
    assert {
        "/venues/{venue_id}",
        "/spaces/{space_id}/slots",
        "/bookings/{booking_id}/cancel",
        "/me/password",
        "/password-recovery/check",
        "/link/recover",
        "/devices/unregister",
        "/notifications/{notification_id}/read",
    } <= published

    def segments(paths: set[str]) -> set[str]:
        return {s.strip("{}") for p in paths for s in p.split("/") if s}

    assert segments(published) & (segments(main) - segments(set(renames.PATHS.values()))) == set()


def test_every_json_field_of_the_published_contract_is_named_as_the_glossary_says(api: TestClient) -> None:
    """every JSON field of the published contract is named as the glossary says @ENG-18-S2"""
    published = api.get("/openapi.json").json()["components"]["schemas"]
    main = _main_contract()["components"]["schemas"]
    names = {p for s in published.values() for p in s.get("properties", {})}
    expected = {renames.new_field(p, o) for o, s in main.items() for p in s.get("properties", {})}
    assert names & renames.SPANISH_NAMES == set()
    assert names == expected


def test_an_error_body_names_its_fields_in_english_and_keeps_mains_message(
    api: TestClient, token_admin: str
) -> None:
    """an error body names its fields in English and keeps main's message @ENG-18-S2 @ENG-18-S9"""
    venue = api.post("/venues", headers=_auth(token_admin), json={})
    assert venue.status_code == 422
    assert venue.json() == {
        "errors": {
            "name": "El nombre es obligatorio",
            "address": "La dirección es obligatoria",
            "opens_at": "El horario de apertura es obligatorio",
            "closes_at": "El horario de cierre es obligatorio",
            "open_days": "Elegí los días que abre",
        }
    }
    signup = api.post("/register", json={})
    assert signup.status_code == 422
    assert set(signup.json()["errors"]) == {
        "first_name", "last_name", "dni", "birth_date", "email", "password"
    }  # fmt: skip
    assert signup.json()["errors"]["first_name"] == "El nombre es obligatorio"


def test_a_booking_error_names_date_space_id_start_hour_hours_until_and_dates_in_english(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """a booking error names date, space_id, start_hour, hours, until and dates in English @ENG-18-S2 @assumption:ENG-18-ASM-01"""
    space = _space(api, token_admin, sede[0])["id"]
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    long_stay = api.post(
        "/bookings",
        headers=_auth(token_usuario),
        json={"space_id": space, "date": tomorrow, "start_hour": "21:00", "hours": 9},
    )
    assert long_stay.status_code == 422
    assert set(long_stay.json()["errors"]) == {"hours", "until"}
    unreadable = api.post(
        "/bookings",
        headers=_auth(token_usuario),
        json={"space_id": space, "date": tomorrow, "start_hour": "9", "hours": 1},
    )
    assert set(unreadable.json()["errors"]) == {"start_hour"}
    far = api.post(
        "/bookings",
        headers=_auth(token_usuario),
        json={"space_id": space, "date": "2999-01-01", "start_hour": "21:00", "hours": 1},
    )
    assert set(far.json()["errors"]) == {"date"}
    other = _space(api, token_admin, sede[0])["id"]
    booking = _book(api, token_usuario, space).json()
    kind_mismatch = api.post(
        f"/bookings/{booking['id']}/modify",
        headers=_auth(token_usuario),
        json={"space_id": str(uuid.uuid4()), "date": tomorrow, "start_hour": "21:00"},
    )
    assert set(kind_mismatch.json()["errors"]) == {"space_id"}
    assert other
    reversed_range = api.get(
        "/bookings/all", headers=_auth(token_admin), params={"since": "2030-01-02", "until": "2030-01-01"}
    )
    assert set(reversed_range.json()["errors"]) == {"dates"}


def test_a_void_error_names_reason_in_english(api: TestClient, token_admin: str) -> None:
    """a void error names reason in English @ENG-18-S2"""
    r = api.post(
        f"/bookings/{uuid.uuid4()}/void",
        headers=_auth(token_admin),
        json={"reason": " ", "space_id": str(uuid.uuid4()), "starts_at": "2030-01-01T10:00:00-03:00"},
    )
    assert (r.status_code, r.json()) == (422, {"errors": {"reason": "El motivo es obligatorio para anular"}})


def test_a_password_change_error_names_current_password_and_new_password(
    api: TestClient, token_usuario: str
) -> None:
    """a password change error names current_password and new_password @ENG-18-S2"""
    wrong = api.put(
        "/me/password",
        headers=_auth(token_usuario),
        json={"current_password": "Equivocada1", "new_password": "ClubNahuel2"},
    )
    assert (wrong.status_code, set(wrong.json()["errors"])) == (422, {"current_password"})
    weak = api.put(
        "/me/password", headers=_auth(token_usuario), json={"current_password": PASSWORD, "new_password": "x"}
    )
    assert set(weak.json()["errors"]) == {"new_password"}


def test_a_space_error_names_kind_in_english(api: TestClient, token_admin: str, sede: tuple[str, str]) -> None:
    """a space error names kind in English @ENG-18-S2"""
    r = api.get(
        "/spaces/name",
        headers=_auth(token_admin),
        params={"venue_id": sede[0], "sport": "Futbol", "kind": "no-existe"},
    )
    assert (r.status_code, set(r.json()["errors"])) == (422, {"kind"})
    empty = api.post("/spaces", headers=_auth(token_admin), json={})
    assert set(empty.json()["errors"]) == {"venue_id", "sport", "kind", "covered", "lit", "price_per_hour"}
    nothing = api.put(f"/spaces/{uuid.uuid4()}", headers=_auth(token_admin), json={})
    assert set(nothing.json()["errors"]) == {"change"}


def test_an_unreadable_body_answers_errors_body(api: TestClient, token_usuario: str) -> None:
    """an unreadable body answers errors.body @ENG-18-S2 @assumption:ENG-18-ASM-01"""
    r = api.post(
        "/bookings", headers=_auth(token_usuario) | {"Content-Type": "application/json"}, content=b"{no"
    )
    assert (r.status_code, set(r.json()["errors"])) == (400, {"body"})


def test_the_health_body_is_status_ok(api: TestClient) -> None:
    """the health body is status ok @assumption:ENG-18-ASM-04"""
    body = api.get("/health").json()
    assert (body["status"], set(body)) == ("ok", {"status", "version"})


def test_every_enum_value_travels_as_the_database_stores_it_and_nothing_translates_it(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """every enum value travels as the database stores it and nothing translates it @ENG-18-S3 @ENG-18-S12 @assumption:ENG-18-ASM-02"""
    space = _space(api, token_admin, sede[0])["id"]
    active = _book(api, token_usuario, space, 1).json()
    to_cancel = _book(api, token_usuario, space, 2).json()
    assert active["status"] == "active"
    cancel = api.post(f"/bookings/{to_cancel['id']}/cancel", headers=_auth(token_usuario))
    assert cancel.json()["status"] == "canceled"
    stored = {r.id: r.status for r in motor.connect().execute(text("SELECT id, status FROM booking"))}
    assert stored[uuid.UUID(active["id"])] == "active"
    assert api.get("/me", headers=_auth(token_usuario)).json()["role"] == "user"
    assert api.get("/me", headers=_auth(token_admin)).json()["role"] == "admin"
    upcoming = api.get("/bookings", headers=_auth(token_usuario), params={"when": "upcoming"}).json()
    assert [b["id"] for b in upcoming["bookings"]] == [active["id"]]
    history = api.get("/bookings", headers=_auth(token_usuario), params={"when": "history"}).json()
    assert [b["status"] for b in history["bookings"]] == ["canceled"]
    assert api.get("/bookings", headers=_auth(token_usuario), params={"when": "proximas"}).status_code == 422
    filtered = api.get("/bookings/all", headers=_auth(token_admin), params={"status": "active"})
    assert filtered.status_code == 200
    assert api.get("/bookings/all", headers=_auth(token_admin), params={"status": "activa"}).status_code == 422
    app_dir = ROOT / "apps" / "api" / "app"
    assert not (app_dir / "shared" / "stored_values.py").exists()
    assert not [p for p in app_dir.rglob("*.py") if "stored_values" in p.read_text(encoding="utf-8")]


def test_the_push_data_carries_kind_and_booking_id_with_the_english_kind_and_mains_text() -> None:
    """the push data carries kind and booking_id with the English kind and main's text @ENG-18-S5 @ENG-18-S9 @assumption:ENG-18-ASM-10"""
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
        [VoidedBooking(booking, __import__("datetime").datetime.now().astimezone(), "Futbol", "F5", "Sede", "lluvia")]
    )
    assert notice.title == "El club anuló tu reserva"
    assert build_message(["t"], notice).data == {"kind": "forced_cancellation", "booking_id": str(booking)}


def test_every_query_parameter_is_named_as_the_glossary_says(
    api: TestClient, token_usuario: str, token_admin: str, sede: tuple[str, str]
) -> None:
    """every query parameter is named as the glossary says @ENG-18-S6"""
    published = api.get("/openapi.json").json()["paths"]
    names = {
        p["name"] for methods in published.values() for op in methods.values() for p in op.get("parameters", [])
        if p["in"] == "query"
    }  # fmt: skip
    assert names == {"venue_id", "sport", "kind", "date", "hours", "booking_id", "since", "until", "when", "status", "page", "q"}
    _space(api, token_admin, sede[0])
    found = api.get("/spaces", headers=_auth(token_usuario), params={"venue_id": sede[0], "sport": "Futbol"})
    assert [s["venue_id"] for s in found.json()["spaces"]] == [sede[0]]
    assert api.get("/spaces", headers=_auth(token_usuario), params={"sede_id": sede[0]}).json()["spaces"] != []


def test_an_old_spanish_route_also_the_old_recovery_link_answers_404(api: TestClient) -> None:
    """an old Spanish route, also the old recovery link, answers 404 @ENG-18-S8 @assumption:ENG-18-ASM-05 @assumption:ENG-18-ASM-12"""
    main = _main_contract()["paths"]
    for old, methods in main.items():
        if renames.PATHS[old] == old:
            continue
        concrete = re.sub(r"\{\w+\}", str(uuid.uuid4()), old)
        for method in methods:
            assert api.request(method.upper(), concrete).status_code == 404, (method, old)
    assert api.get("/enlace/recuperar").status_code == 404


def test_an_old_spanish_body_answers_422_where_fields_are_required_and_changes_nothing_where_all_are_optional(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """an old Spanish body answers 422 where fields are required and changes nothing where all are optional @ENG-18-S8 @assumption:ENG-18-ASM-05"""
    space = _space(api, token_admin, sede[0])
    old_booking = api.post(
        "/bookings",
        headers=_auth(token_usuario),
        json={"espacio_id": space["id"], "fecha": "2030-01-01", "desde": "21:00", "horas": 1},
    )
    assert (old_booking.status_code, set(old_booking.json()["errors"])) == (
        422, {"space_id", "date", "start_hour", "hours"}
    )  # fmt: skip
    old_edit = api.put(f"/spaces/{space['id']}", headers=_auth(token_admin), json={"precio_por_hora": 1})
    assert old_edit.status_code == 422
    after = api.get("/spaces", headers=_auth(token_admin), params={"venue_id": sede[0]}).json()["spaces"]
    assert [s["price_per_hour"] for s in after] == [38000]


def test_the_recovery_email_links_to_link_recover_with_code_and_the_page_opens_the_same_app_route(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    """the recovery email links to /link/recover with #code and the page opens the same app route @assumption:ENG-18-ASM-06"""
    account = _register(api, unico())
    assert api.post("/password-recovery", json={"email": account["email"]}).status_code == 202
    with motor.connect() as conn:
        subject, body = conn.execute(
            text("SELECT subject, body FROM outgoing_email WHERE recipient = :p ORDER BY id DESC LIMIT 1"),
            {"p": account["email"]},
        ).one()
    assert subject == "Creá una contraseña nueva"
    assert re.search(r"/link/recover#code=[\w-]+", body) and "/enlace/" not in body
    code = re.search(r"#code=([\w-]+)", body)
    assert code is not None
    assert api.post("/password-recovery/check", json={"code": code.group(1)}).status_code == 204
    page = api.get("/link/recover")
    assert page.status_code == 200
    assert 'get("code")' in page.text and "intent://app/recuperar?codigo=" in page.text


def test_the_email_the_catalog_names_and_the_seeds_stay_as_in_main(
    api: TestClient, token_usuario: str
) -> None:
    """the email, the catalog names and the seeds stay as in main @ENG-18-S9"""
    main_source = subprocess.run(
        ["git", "show", f"{MAIN}:apps/api/app/modules/spaces/rules.py"],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8", check=True,
    ).stdout  # fmt: skip
    pairs = re.findall(r'(?:Sport\(\s*|Kind\()"([^"]+)",\s*"([^"]+)"', main_source)
    catalog = api.get("/spaces/catalog", headers=_auth(token_usuario)).json()["sports"]
    shown = [(s["key"], s["name"]) for s in catalog]
    shown += [(k["key"], k["name"]) for s in catalog for k in s["kinds"]]
    assert sorted(shown) == sorted(pairs)
    seed = "apps/api/app/modules/users/seed_admin.py"
    assert subprocess.run(["git", "diff", "--quiet", MAIN, "--", seed], cwd=ROOT).returncode == 0


def test_mains_contract_renamed_by_the_glossary_is_the_published_contract(api: TestClient) -> None:
    """main's contract renamed by the glossary is the published contract @ENG-18-S11 @assumption:ENG-18-ASM-11"""
    published = renames.comparable(api.get("/openapi.json").json(), renamed=False)
    expected = renames.comparable(_main_contract(), renamed=True)
    assert sorted(published) == sorted(expected)
    for key, operation in expected.items():
        assert published[key] == operation, key
