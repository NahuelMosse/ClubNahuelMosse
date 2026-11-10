"""`/venues` against the real database and emulator."""

from collections.abc import Callable, Iterator
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.users.seed_admin import main as seed

PASSWORD = "ClubNahuel1"


@pytest.fixture
def admin_token(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> Iterator[str]:
    s = unique()
    email = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", PASSWORD)
    args = [
        "--correo", email, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert seed(args) == 0
    token = sign_in(email, PASSWORD)
    assert token is not None
    yield token


@pytest.fixture
def user_token(
    api: TestClient,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> str:
    s = unique()
    email = f"socio.{s}@correo.com"
    payload = {
        "first_name": "Martín",
        "last_name": "Ferreyra",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "1994-07-21",
        "email": email,
        "password": PASSWORD,
    }
    assert api.post("/register", json=payload).status_code == 201
    token = sign_in(email, PASSWORD)
    assert token is not None
    return token


def _venue(name: str, **changes: object) -> dict[str, object]:
    return {
        "name": name,
        "address": "Av. Vergara 1850",
        "opens_at": "08:00",
        "closes_at": "23:00",
        "open_days": [1, 2, 3, 4, 5, 6],
    } | changes


def _bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_creating_a_venue_stores_it_with_its_trail_and_returns_it(
    api: TestClient, engine: Engine, admin_token: str, unique: Callable[[], str]
) -> None:
    name = f"Sede Haedo {unique()}"
    r = api.post("/venues", headers=_bearer(admin_token), json=_venue(name))
    assert r.status_code == 201
    assert r.json() | {"id": ""} == {
        "id": "",
        "name": name,
        "address": "Av. Vergara 1850",
        "opens_at": "08:00",
        "closes_at": "23:00",
        "open_days": [1, 2, 3, 4, 5, 6],
        "space_count": 0,
        "sports": [],
    }
    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT s.street, s.street_number, s.active, s.created_at IS NOT NULL AS con_fecha,"
                " u.email LIKE 'admin.%' AS por_admin"
                " FROM venue s JOIN app_user u ON u.id = s.created_by WHERE s.id = :id"
            ),
            {"id": r.json()["id"]},
        ).one()
    assert tuple(row) == ("Av. Vergara", 1850, True, True, True)


def test_users_see_the_venues_by_name_with_their_courts(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    unique: Callable[[], str],
) -> None:
    s = unique()
    zeta = api.post("/venues", headers=_bearer(admin_token), json=_venue(f"zz Sede {s}")).json()
    api.post("/venues", headers=_bearer(admin_token), json=_venue(f"ZY Sede {s}"))
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO space (venue_id, sport, kind, number, name, price_per_hour,"
                " covered, lit) VALUES (:venue, 'Padel', 'PAD', 1, :n, 30000, true, true)"
            ),
            {"venue": zeta["id"], "n": f"Zz_Vergara_1850_Padel_PAD_1_{s}"},
        )

    r = api.get("/venues", headers=_bearer(user_token))

    assert r.status_code == 200
    own = [x for x in r.json()["venues"] if x["name"].endswith(s)]
    assert [(x["name"], x["space_count"]) for x in own] == [
        (f"ZY Sede {s}", 0),
        (f"zz Sede {s}", 1),
    ]


def test_there_are_no_two_active_venues_with_the_same_name(
    api: TestClient, admin_token: str, unique: Callable[[], str]
) -> None:
    name = f"Sede Haedo {unique()}"
    assert api.post("/venues", headers=_bearer(admin_token), json=_venue(name)).status_code == 201
    r = api.post(
        "/venues", headers=_bearer(admin_token), json=_venue(name.upper(), address="Otra 1")
    )
    assert r.status_code == 409
    assert r.json() == {"errors": {"name": "A venue with that name already exists"}}


def test_two_identical_simultaneous_creations_store_only_one(
    api: TestClient, engine: Engine, admin_token: str, unique: Callable[[], str]
) -> None:
    name = f"Sede Haedo {unique()}"
    with ThreadPoolExecutor(max_workers=2) as pool:
        codes = sorted(
            pool.map(
                lambda _: (
                    api.post("/venues", headers=_bearer(admin_token), json=_venue(name)).status_code
                ),
                range(2),
            )
        )
    assert codes == [201, 409]
    with engine.connect() as conn:
        n: Any = conn.execute(
            text("SELECT count(*) FROM venue WHERE name = :n"), {"n": name}
        ).scalar_one()
    assert n == 1


def test_invalid_data_comes_back_with_a_message_per_field(
    api: TestClient, admin_token: str, unique: Callable[[], str]
) -> None:
    r = api.post(
        "/venues",
        headers=_bearer(admin_token),
        json=_venue(f"Sede {unique()}", address="Vergara", opens_at="22:00", closes_at="21:00"),
    )
    assert r.status_code == 422
    assert r.json() == {
        "errors": {
            "address": "Write the street and the number",
            "closes_at": "The closing must be after the opening",
        }
    }
    r = api.post("/venues", headers=_bearer(admin_token), json={})
    assert r.status_code == 422
    assert set(r.json()["errors"]) == {"name", "address", "opens_at", "closes_at", "open_days"}


def test_without_a_session_there_are_no_venues(api: TestClient) -> None:
    assert api.get("/venues").status_code == 401
    assert api.post("/venues", json=_venue("Sede Haedo")).status_code == 401


@pytest.mark.parametrize("hour", ["23:00+00:00", "00:00Z", "08", "0800", "T08:00", "8:00"])
def test_a_time_that_is_not_hh_mm_is_a_field_error(
    api: TestClient, admin_token: str, unique: Callable[[], str], hour: str
) -> None:
    r = api.post(
        "/venues", headers=_bearer(admin_token), json=_venue(f"Sede {unique()}", closes_at=hour)
    )
    assert r.status_code == 422
    assert r.json() == {"errors": {"closes_at": "The closing time is required"}}


def _create(api: TestClient, admin_token: str, name: str) -> str:
    r = api.post(
        "/venues",
        headers=_bearer(admin_token),
        json=_venue(name, open_days=[1, 2, 3, 4, 5, 6, 7]),
    )
    assert r.status_code == 201
    return str(r.json()["id"])


def test_editing_stores_the_new_data_with_its_trail(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, unique: Callable[[], str]
) -> None:
    name = f"Sede Haedo {unique()}"
    venue = _create(api, admin_token, name)
    changes = _venue(
        f"{name} Norte", address="Av. Vergara 1900", closes_at="00:00", open_days=[1, 2]
    )

    r = api.put(f"/venues/{venue}", headers=_bearer(admin_token), json=changes)

    assert r.status_code == 200
    assert (
        r.json()["name"],
        r.json()["address"],
        r.json()["closes_at"],
        r.json()["open_days"],
    ) == (
        f"{name} Norte",
        "Av. Vergara 1900",
        "00:00",
        [1, 2],
    )
    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT s.updated_at > s.created_at AS despues, u.email LIKE 'admin.%' AS admin"
                " FROM venue s JOIN app_user u ON u.id = s.updated_by WHERE s.id = :id"
            ),
            {"id": venue},
        ).one()
    assert tuple(row) == (True, True)
    # The same venue can keep its name.
    assert (
        api.put(f"/venues/{venue}", headers=_bearer(admin_token), json=changes).status_code == 200
    )
    assert api.put(f"/venues/{venue}", headers=_bearer(user_token), json=changes).status_code == 403
    assert api.put(f"/venues/{venue}", json=changes).status_code == 401


def test_editing_rejects_another_name_in_use_invalid_data_and_a_deactivated_venue(
    api: TestClient, engine: Engine, admin_token: str, unique: Callable[[], str]
) -> None:
    name = f"Sede Haedo {unique()}"
    other = f"Sede Morón {unique()}"
    venue = _create(api, admin_token, name)
    _create(api, admin_token, other)

    repeated = api.put(f"/venues/{venue}", headers=_bearer(admin_token), json=_venue(other.upper()))
    assert repeated.status_code == 409
    assert repeated.json() == {"errors": {"name": "A venue with that name already exists"}}
    empty = api.put(f"/venues/{venue}", headers=_bearer(admin_token), json=_venue(name, address=""))
    assert empty.status_code == 422
    assert empty.json()["errors"]["address"] == "The address is required"
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE venue SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": venue},
        )
    assert (
        api.put(f"/venues/{venue}", headers=_bearer(admin_token), json=_venue(name)).status_code
        == 404
    )
    assert (
        api.put(
            "/venues/00000000-0000-7000-8000-0000000000ff",
            headers=_bearer(admin_token),
            json=_venue(name),
        ).status_code
        == 404
    )


def test_shrinking_the_hours_asks_to_confirm_the_bookings_left_outside_and_keeps_them(
    api: TestClient, engine: Engine, admin_token: str, unique: Callable[[], str]
) -> None:
    name = f"Sede Morón {unique()}"
    venue = _create(api, admin_token, name)
    space = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json={
            "venue_id": venue,
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    ).json()["id"]
    with engine.begin() as conn:
        owner: Any = conn.execute(text("SELECT id FROM app_user ORDER BY id LIMIT 1")).scalar_one()
        tomorrow: Any = conn.execute(
            text("SELECT (now() AT TIME ZONE 'America/Argentina/Buenos_Aires')::date + 1")
        ).scalar_one()
        for day, hour, status in [
            (1, 8, "active"),
            (1, 22, "active"),
            (1, 9, "canceled"),
            (-2, 8, "active"),
        ]:
            conn.execute(
                text(
                    "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                    " total, status, canceled_at)"
                    " SELECT :u, :e, x.i, x.i + interval '1 hour', 38000, 38000, :status,"
                    " CASE WHEN :status <> 'active' THEN now() END"
                    " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :h))"
                    " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x"
                ),
                {
                    "u": owner,
                    "e": space,
                    "dia": tomorrow + timedelta(days=day - 1),
                    "h": hour,
                    "status": status,
                },
            )

    def edit(**changes: object) -> tuple[int, object]:
        r = api.put(f"/venues/{venue}", headers=_bearer(admin_token), json=_venue(name, **changes))
        return r.status_code, r.json()

    all_days = [1, 2, 3, 4, 5, 6, 7]
    # Past and canceled ones do not count.
    assert edit(opens_at="09:00", open_days=all_days) == (409, {"bookings_outside": 1})
    assert edit(opens_at="09:00", closes_at="22:00", open_days=all_days) == (
        409,
        {"bookings_outside": 2},
    )
    without_tomorrow = [d for d in all_days if d != tomorrow.isoweekday()]
    assert edit(open_days=without_tomorrow) == (409, {"bookings_outside": 2})
    assert edit(opens_at="09:00", open_days=all_days, confirm=True)[0] == 200
    # What was already outside is not asked about again.
    assert edit(opens_at="09:00", open_days=all_days, address="Av. Rivadavia 19850")[0] == 200
    with engine.connect() as conn:
        active: Any = conn.execute(
            text("SELECT count(*) FROM booking WHERE space_id = :e AND status = 'active'"),
            {"e": space},
        ).scalar_one()
    assert active == 3


def test_deactivation_leaves_the_venue_and_its_spaces_inactive_with_their_trail(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, unique: Callable[[], str]
) -> None:
    name = f"Sede Haedo {unique()}"
    venue = _create(api, admin_token, name)
    space = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json={
            "venue_id": venue,
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    ).json()["id"]
    assert api.delete(f"/venues/{venue}", headers=_bearer(user_token)).status_code == 403
    assert api.delete(f"/venues/{venue}").status_code == 401

    assert api.delete(f"/venues/{venue}", headers=_bearer(admin_token)).status_code == 204

    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT s.active, s.deactivated_at IS NOT NULL, e.active,"
                " e.deactivated_by = s.deactivated_by"
                " FROM venue s JOIN space e ON e.venue_id = s.id WHERE s.id = :id"
            ),
            {"id": venue},
        ).one()
    assert tuple(row) == (False, True, False, True)
    venues = api.get("/venues", headers=_bearer(user_token)).json()["venues"]
    assert name not in [s["name"] for s in venues]
    spaces = api.get("/spaces", headers=_bearer(user_token)).json()["spaces"]
    assert space not in [e["id"] for e in spaces]
    # Already deactivated: 404, and its name is free for a new venue.
    assert api.delete(f"/venues/{venue}", headers=_bearer(admin_token)).status_code == 404
    assert api.post("/venues", headers=_bearer(admin_token), json=_venue(name)).status_code == 201


def test_a_venue_with_unfinished_bookings_is_not_deactivated(
    api: TestClient, engine: Engine, admin_token: str, unique: Callable[[], str]
) -> None:
    venue = _create(api, admin_token, f"Sede Morón {unique()}")
    space = api.post(
        "/spaces",
        headers=_bearer(admin_token),
        json={
            "venue_id": venue,
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    ).json()["id"]
    with engine.begin() as conn:
        owner: Any = conn.execute(text("SELECT id FROM app_user ORDER BY id LIMIT 1")).scalar_one()
        # One in progress: it started this hour and ends in two.
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, :e, i, i + interval '2 hours', 38000, 76000"
                " FROM (SELECT date_trunc('hour', now()) AS i) x"
            ),
            {"u": owner, "e": space},
        )

    r = api.delete(f"/venues/{venue}", headers=_bearer(admin_token))

    assert r.status_code == 409
    assert r.json() == {
        "errors": {"venue": "The venue cannot be deleted because it has future bookings."}
    }
    with engine.connect() as conn:
        assert conn.execute(
            text("SELECT active FROM venue WHERE id = :id"), {"id": venue}
        ).scalar_one()
