"""`/spaces` against the real database and emulator."""

from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.users.seed_admin import main as seed

PASSWORD = "ClubNahuel1"
DUPLICATE = "A sports space with that name already exists in the selected venue."


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _space(venue_id: str, **changes: object) -> dict[str, object]:
    return {
        "venue_id": venue_id,
        "sport": "Futbol",
        "kind": "F5",
        "covered": False,
        "lit": True,
        "price_per_hour": 38000,
    } | changes


def test_creating_a_space_builds_the_name_and_stores_the_trail(
    api: TestClient, engine: Engine, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, prefix = venue
    suggested = api.get(
        "/spaces/name",
        headers=_bearer(admin_token),
        params={"venue_id": venue_id, "sport": "Futbol", "kind": "F5"},
    )
    assert suggested.json() == {"name": f"{prefix}_Futbol_F5_1", "number": 1}

    r = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, number=1))

    assert r.status_code == 201
    assert r.json()["name"] == f"{prefix}_Futbol_F5_1"
    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT e.active, e.created_by IS NOT NULL, e.price_per_hour"
                " FROM space e WHERE e.id = :id"
            ),
            {"id": r.json()["id"]},
        ).one()
    assert tuple(row) == (True, True, 38000)


def test_numbers_are_not_reused_after_deactivation(
    api: TestClient, engine: Engine, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, prefix = venue
    first = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE space SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": first["id"]},
        )
    r = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id))
    assert r.json()["name"] == f"{prefix}_Futbol_F5_2"
    # Another kind has its own numbering.
    r = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, kind="F7"))
    assert r.json()["name"] == f"{prefix}_Futbol_F7_1"


def test_if_another_creation_took_the_number_it_returns_the_next_one(
    api: TestClient, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, prefix = venue
    assert api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).is_success
    r = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json=_space(venue_id, number=1, covered=True),
    )
    assert r.status_code == 409
    assert r.json() == {
        "errors": {"name": DUPLICATE},
        "name": f"{prefix}_Futbol_F5_2",
        "number": 2,
    }


def test_two_simultaneous_creations_take_different_numbers(
    api: TestClient, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, prefix = venue
    with ThreadPoolExecutor(max_workers=3) as pool:
        responses = list(
            pool.map(
                lambda _: api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)),
                range(3),
            )
        )
    assert sorted(r.json()["name"] for r in responses) == [
        f"{prefix}_Futbol_F5_{n}" for n in (1, 2, 3)
    ]


def test_invalid_data_comes_back_with_a_message_per_field(
    api: TestClient, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    r = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json=_space(venue_id, kind="PDL", price_per_hour=0),
    )
    assert r.status_code == 422
    assert r.json() == {
        "errors": {
            "kind": "Choose a kind from the list",
            "price_per_hour": "Enter a price between $ 1 and $ 9,999,999",
        }
    }


def test_a_deactivated_venue_receives_no_spaces(
    api: TestClient, engine: Engine, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE venue SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": venue_id},
        )
    r = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id))
    assert r.status_code == 422
    assert r.json() == {"errors": {"venue_id": "The venue is no longer available"}}


def test_users_see_active_spaces_and_the_catalog(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    venue_id, prefix = venue
    f7 = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, kind="F7"))
    api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id))
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE space SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": f7.json()["id"]},
        )

    r = api.get("/spaces", headers=_bearer(user_token))

    assert r.status_code == 200
    own = [e["name"] for e in r.json()["spaces"] if e["name"].startswith(prefix)]
    assert own == [f"{prefix}_Futbol_F5_1"]
    catalog = api.get("/spaces/catalog", headers=_bearer(user_token)).json()
    football = next(d for d in catalog["sports"] if d["key"] == "Futbol")
    assert {"key": "F5", "name": "Football 5"} in football["kinds"]


def test_a_user_cannot_request_space_names(
    api: TestClient, user_token: str, venue: tuple[str, str]
) -> None:
    r = api.get(
        "/spaces/name",
        headers=_bearer(user_token),
        params={"venue_id": venue[0], "sport": "Futbol", "kind": "F5"},
    )
    assert r.status_code == 403


def test_without_a_session_there_are_no_spaces(api: TestClient) -> None:
    assert api.get("/spaces").status_code == 401
    assert api.get("/spaces/catalog").status_code == 401
    assert api.post("/spaces", json={}).status_code == 401


def test_the_number_skips_a_name_another_venue_used(
    api: TestClient, engine: Engine, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, prefix = venue
    assert api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).is_success
    with engine.begin() as conn:
        name, street, number = conn.execute(
            text("SELECT name, street, street_number FROM venue WHERE id = :id"),
            {"id": venue_id},
        ).one()
        conn.execute(
            text("UPDATE venue SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": venue_id},
        )
    # The same venue is created again: its first Football 5 cannot be named like the
    # deactivated one's.
    other = api.post(
        "/venues",
        headers=_bearer(admin_token),
        json={
            "name": name,
            "address": f"{street} {number}",
            "opens_at": "08:00",
            "closes_at": "23:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    ).json()["id"]
    suggested = api.get(
        "/spaces/name",
        headers=_bearer(admin_token),
        params={"venue_id": other, "sport": "Futbol", "kind": "F5"},
    ).json()
    assert suggested == {"name": f"{prefix}_Futbol_F5_2", "number": 2}
    r = api.post("/spaces", headers=_bearer(admin_token), json=_space(other, number=2))
    assert r.status_code == 201
    assert r.json()["name"] == f"{prefix}_Futbol_F5_2"


def test_the_same_request_repeated_after_a_cutoff_returns_the_stored_space(
    api: TestClient, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    first = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, number=1))
    repeated = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, number=1))
    assert repeated.status_code == 201
    assert repeated.json() == first.json()
    # With other data it is not the same request: the number is taken.
    different = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json=_space(venue_id, number=1, price_per_hour=40000),
    )
    assert different.status_code == 409
    assert different.json()["number"] == 2


def test_another_administrators_request_is_not_taken_as_its_own(
    api: TestClient,
    admin_token: str,
    venue: tuple[str, str],
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    venue_id, _ = venue
    s = unique()
    monkeypatch.setenv("ADMIN_CONTRASENA", PASSWORD)
    args = [
        "--correo", f"otro.{s}@club.com", "--nombre", "Luis", "--apellido", "Paz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1980-02-02",
    ]  # fmt: skip
    assert seed(args) == 0
    other = sign_in(f"otro.{s}@club.com", PASSWORD)
    assert other is not None
    assert api.post("/spaces", headers=_bearer(other), json=_space(venue_id, number=1)).is_success
    r = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, number=1))
    assert r.status_code == 409


def test_spaces_are_filtered_by_venue_and_the_venue_lists_its_sports(
    api: TestClient,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
    unique: Callable[[], str],
) -> None:
    venue_id, prefix = venue
    other = api.post(
        "/venues",
        headers=_bearer(admin_token),
        json={
            "name": f"Sede Castelar {unique()}",
            "address": "Av. Rivadavia 23500",
            "opens_at": "08:00",
            "closes_at": "22:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    ).json()["id"]
    api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, kind="F7"))
    api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id))
    api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json=_space(venue_id, sport="Tenis", kind="PDL"),
    )
    api.post("/spaces", headers=_bearer(admin_token), json=_space(other))

    r = api.get("/spaces", headers=_bearer(user_token), params={"venue_id": venue_id})

    assert [e["name"] for e in r.json()["spaces"]] == [
        f"{prefix}_Futbol_F5_1",
        f"{prefix}_Futbol_F7_1",
        f"{prefix}_Tenis_PDL_1",
    ]
    venues = {s["id"]: s for s in api.get("/venues", headers=_bearer(user_token)).json()["venues"]}
    assert (venues[venue_id]["space_count"], venues[venue_id]["sports"]) == (3, ["Futbol", "Tenis"])
    assert venues[other]["sports"] == ["Futbol"]


def test_spaces_are_filtered_by_sport_and_kind(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, prefix = venue
    for changes in ({}, {"kind": "F7"}, {"sport": "Hockey", "kind": "H7"}):
        api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, **changes))

    def names(**filters: str) -> list[str]:
        params: dict[str, str | int] = {"venue_id": venue_id, **filters}
        r = api.get("/spaces", headers=_bearer(user_token), params=params)
        return [e["name"] for e in r.json()["spaces"]]

    assert names(sport="Futbol") == [f"{prefix}_Futbol_F5_1", f"{prefix}_Futbol_F7_1"]
    assert names(sport="Futbol", kind="F7") == [f"{prefix}_Futbol_F7_1"]
    assert names(sport="Golf") == []
    assert names(kind="F7") == [f"{prefix}_Futbol_F7_1"]
    for bad in ({"sport": ""}, {"kind": ""}):
        params: dict[str, str | int] = {"venue_id": venue_id, **bad}
        r = api.get("/spaces", headers=_bearer(user_token), params=params)
        assert r.status_code == 422


def test_space_slots_mark_active_bookings(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
    today = api.get(f"/spaces/{space['id']}/slots", headers=_bearer(user_token)).json()
    tomorrow = date.fromisoformat(today["today"]) + timedelta(days=1)
    with engine.begin() as conn:
        for hour, status in ((10, "active"), (12, "canceled")):
            conn.execute(
                text(
                    "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                    " total, status, canceled_at)"
                    " SELECT (SELECT id FROM app_user ORDER BY id LIMIT 1), :e, x.i,"
                    " x.i + interval '1 hour', 38000, 38000, :status,"
                    " CASE WHEN :status = 'canceled' THEN now() END FROM"
                    " (SELECT (CAST(:dia AS date) + make_interval(hours => :hora))"
                    " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x"
                ),
                {"e": space["id"], "dia": tomorrow, "hora": hour, "status": status},
            )

    r = api.get(
        f"/spaces/{space['id']}/slots",
        headers=_bearer(user_token),
        params={"date": tomorrow.isoformat()},
    )

    assert r.status_code == 200
    slots = {f["starts_at"]: f["available"] for f in r.json()["slots"]}
    assert (slots["10:00"], slots["11:00"], slots["12:00"]) == (False, True, True)
    assert (r.json()["opens"], r.json()["unavailable"]) == (True, 1)
    assert r.json()["slots"][-1] == {"starts_at": "22:00", "ends_at": "23:00", "available": True}


def test_slots_require_a_session_and_stay_within_the_week(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    space = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
    path = f"/spaces/{space['id']}/slots"
    today = date.fromisoformat(api.get(path, headers=_bearer(user_token)).json()["today"])

    assert api.get(path).status_code == 401
    far = {"date": (today + timedelta(days=7)).isoformat()}
    assert api.get(path, headers=_bearer(user_token), params=far).status_code == 422
    assert api.get(path, headers=_bearer(user_token), params={"hours": 5}).status_code == 422
    missing = "/spaces/00000000-0000-7000-8000-0000000000ff/slots"
    assert api.get(missing, headers=_bearer(user_token)).status_code == 404


def test_available_courts_are_those_free_across_the_whole_range(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, prefix = venue
    ids = [
        api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id, **c)).json()["id"]
        for c in ({}, {}, {"kind": "F7"})
    ]
    today = date.fromisoformat(
        api.get(f"/spaces/{ids[0]}/slots", headers=_bearer(user_token)).json()["today"]
    )
    tomorrow = today + timedelta(days=1)
    with engine.begin() as conn:
        for space, hour in ((ids[0], 9), (ids[1], 11)):
            conn.execute(
                text(
                    "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                    " total) SELECT (SELECT id FROM app_user ORDER BY id LIMIT 1), :e, x.i,"
                    " x.i + interval '1 hour', 38000, 38000"
                    " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :h))"
                    " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x"
                ),
                {"e": space, "dia": tomorrow, "h": hour},
            )
    query: dict[str, str | int] = {
        "venue_id": venue_id,
        "sport": "Futbol",
        "date": tomorrow.isoformat(),
    }

    def names(**changes: str) -> list[str]:
        r = api.get(
            "/spaces/available",
            headers=_bearer(user_token),
            params={**query, "since": "10:00", "until": "12:00", **changes},
        )
        assert r.status_code == 200, r.text
        return [e["name"] for e in r.json()["spaces"]]

    assert names(kind="F5") == [f"{prefix}_Futbol_F5_1"]
    assert names() == [f"{prefix}_Futbol_F5_1", f"{prefix}_Futbol_F7_1"]
    assert names(kind="F5", since="09:00", until="12:00") == []
    assert len(names(kind="F5", since="12:00", until="14:00")) == 2


def test_available_courts_reject_an_invalid_range(
    api: TestClient, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    base: dict[str, str | int] = {"venue_id": venue_id, "sport": "Futbol", "date": "2020-01-01"}

    r = api.get(
        "/spaces/available",
        headers=_bearer(user_token),
        params=base | {"since": "10:00", "until": "10:00"},
    )
    assert r.status_code == 422
    assert r.json()["errors"] == {
        "date": "The date must be in the future",
        "until": "The minimum duration is one hour",
    }
    r = api.get(
        "/spaces/available",
        headers=_bearer(user_token),
        params=base | {"since": "10", "until": "11:00"},
    )
    assert r.json()["errors"] == {"start_hour": "Choose an on-the-hour time"}
    r = api.get(
        "/spaces/available",
        headers=_bearer(user_token),
        params=base
        | {"venue_id": "00000000-0000-7000-8000-000000000000", "since": "10:00", "until": "11:00"},
    )
    assert r.json()["errors"] == {"venue_id": "The venue is no longer available"}
    assert api.get("/spaces/available", params=base).status_code in (401, 422)


def test_editing_changes_cover_lighting_and_price_without_touching_the_name_or_bookings(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    created = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
    with engine.begin() as conn:
        owner: Any = conn.execute(text("SELECT id FROM app_user ORDER BY id LIMIT 1")).scalar_one()
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, :e, i, i + interval '1 hour', :p, :p"
                " FROM (SELECT date_trunc('hour', now()) + interval '1 day' AS i) x"
            ),
            {"u": owner, "e": created["id"], "p": created["price_per_hour"]},
        )
    change = {"covered": not created["covered"], "lit": False, "price_per_hour": 45000}

    r = api.put(f"/spaces/{created['id']}", headers=_bearer(admin_token), json=change)

    assert r.status_code == 200
    assert r.json() == created | change
    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT e.updated_by IS NOT NULL, r.total FROM space e"
                " JOIN booking r ON r.space_id = e.id WHERE e.id = :id"
            ),
            {"id": created["id"]},
        ).one()
    assert tuple(row) == (True, created["price_per_hour"])
    assert (
        api.put(f"/spaces/{created['id']}", headers=_bearer(user_token), json=change).status_code
        == 403
    )


def test_editing_rejects_an_invalid_price_and_a_deactivated_space(
    api: TestClient, engine: Engine, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    created = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
    path = f"/spaces/{created['id']}"

    for price, message in [
        (None, "This field is required"),
        (0, "Enter a price between $ 1 and $ 9,999,999"),
        (10_000_000, "Enter a price between $ 1 and $ 9,999,999"),
    ]:
        r = api.put(
            path,
            headers=_bearer(admin_token),
            json={"covered": True, "lit": True, "price_per_hour": price},
        )
        assert r.status_code == 422
        assert r.json()["errors"] == {"price_per_hour": message}
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE space SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": created["id"]},
        )
    valid = {"covered": True, "lit": True, "price_per_hour": 45000}
    assert api.put(path, headers=_bearer(admin_token), json=valid).status_code == 404


def test_editing_without_a_field_leaves_it_as_it_was(
    api: TestClient, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    created = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
    path = f"/spaces/{created['id']}"

    # Another administrator changed the price; this one only changes the cover.
    assert (
        api.put(path, headers=_bearer(admin_token), json={"price_per_hour": 50000}).status_code
        == 200
    )
    r = api.put(path, headers=_bearer(admin_token), json={"covered": not created["covered"]})

    assert r.status_code == 200
    assert (r.json()["price_per_hour"], r.json()["covered"]) == (50000, not created["covered"])
    empty = api.put(path, headers=_bearer(admin_token), json={})
    assert empty.status_code == 422
    assert empty.json()["errors"] == {"change": "There is nothing to change"}


def test_deactivation_leaves_the_space_inactive_with_its_trail_and_the_venue_with_one_less(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    one = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
    path = f"/spaces/{one['id']}"
    assert api.delete(path, headers=_bearer(user_token)).status_code == 403
    assert api.delete(path).status_code == 401

    assert api.delete(path, headers=_bearer(admin_token)).status_code == 204

    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT active, deactivated_at IS NOT NULL, deactivated_by IS NOT NULL"
                " FROM space WHERE id = :id"
            ),
            {"id": one["id"]},
        ).one()
    assert tuple(row) == (False, True, True)
    spaces = api.get("/spaces", headers=_bearer(user_token)).json()["spaces"]
    assert one["id"] not in [e["id"] for e in spaces]
    assert api.delete(path, headers=_bearer(admin_token)).status_code == 404


def test_a_space_with_an_unfinished_booking_is_not_deactivated(
    api: TestClient, engine: Engine, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue
    one = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
    with engine.begin() as conn:
        owner: Any = conn.execute(text("SELECT id FROM app_user ORDER BY id LIMIT 1")).scalar_one()
        # One in progress: it started this hour and ends in two.
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, :e, i, i + interval '2 hours', 38000, 76000"
                " FROM (SELECT date_trunc('hour', now()) AS i) x"
            ),
            {"u": owner, "e": one["id"]},
        )

    r = api.delete(f"/spaces/{one['id']}", headers=_bearer(admin_token))

    assert r.status_code == 409
    assert r.json() == {
        "errors": {"space": "The space cannot be deleted because it has future bookings."}
    }
    with engine.connect() as conn:
        assert conn.execute(
            text("SELECT active FROM space WHERE id = :id"), {"id": one["id"]}
        ).scalar_one()


def test_deactivation_only_considers_active_bookings_not_yet_finished(
    api: TestClient, engine: Engine, admin_token: str, venue: tuple[str, str]
) -> None:
    venue_id, _ = venue

    def with_booking(since: str, status: str) -> str:
        space = api.post("/spaces", headers=_bearer(admin_token), json=_space(venue_id)).json()
        with engine.begin() as conn:
            owner: Any = conn.execute(
                text("SELECT id FROM app_user ORDER BY id LIMIT 1")
            ).scalar_one()
            conn.execute(
                text(
                    "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                    " total, status, canceled_at)"
                    " SELECT :u, :e, i, i + interval '1 hour', 38000, 38000, :status,"
                    " CASE WHEN :status <> 'active' THEN now() END"
                    f" FROM (SELECT date_trunc('hour', now()) + interval '{since}' AS i) x"
                ),
                {"u": owner, "e": space["id"], "status": status},
            )
        return str(space["id"])

    future = with_booking("1 day", "active")
    finished = with_booking("-1 day", "active")
    canceled = with_booking("1 day", "canceled")

    assert api.delete(f"/spaces/{future}", headers=_bearer(admin_token)).status_code == 409
    assert api.delete(f"/spaces/{finished}", headers=_bearer(admin_token)).status_code == 204
    assert api.delete(f"/spaces/{canceled}", headers=_bearer(admin_token)).status_code == 204
