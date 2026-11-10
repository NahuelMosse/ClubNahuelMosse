"""The suite tests what it says: edges, a session on every operation, fixed queries and unit tests."""

import ast
import os
import re
import subprocess
import sys
from collections.abc import Callable, Iterator
from datetime import datetime, timedelta
from pathlib import Path
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Connection, Engine, event, text
from sqlalchemy.exc import IntegrityError

from app.shared.db import engine as app_engine
from app.modules.users.seed_admin import main as seed_admin

API_ROOT = Path(__file__).resolve().parents[2]
ZONE = ZoneInfo("America/Argentina/Buenos_Aires")
PASSWORD = "ClubNahuel1"


def _non_public(api: TestClient) -> list[tuple[str, str]]:
    """The operations the contract publishes with security: the others ask for no session."""
    schema = api.get("/openapi.json").json()
    return [
        (method.upper(), re.sub(r"\{[^}]+\}", "1", route))
        for route, operations in schema["paths"].items()
        for method, operation in operations.items()
        if operation.get("security")
    ]


def _without_401(api: TestClient, headers: dict[str, str]) -> dict[tuple[str, str], int]:
    codes = {
        (method, route): api.request(
            method, route, headers=headers, json=None if method == "GET" else {}
        ).status_code
        for method, route in _non_public(api)
    }
    return {operation: c for operation, c in codes.items() if c != 401}


def test_every_non_public_operation_answers_401_without_a_session(api: TestClient) -> None:
    """every non-public operation answers 401 without a session and the 28 of the contract are counted, as RNF-01-H06-02 asks
    @REV-08-S1 @assumption:REV-08-ASM-02
    """
    assert len(_non_public(api)) >= 28
    assert _without_401(api, {}) == {}


def test_an_invalid_token_counts_as_no_session(api: TestClient) -> None:
    """an invalid token counts as no session and answers 401
    @REV-08-S1 @assumption:REV-08-ASM-11
    """
    assert _without_401(api, {"Authorization": "Bearer no-es-un-token"}) == {}


def _user(conn: Connection, email: str, dni: str) -> UUID:
    return conn.execute(
        text(
            "INSERT INTO app_user (firebase_uid, email, first_name, last_name, dni,"
            " birth_date) VALUES (:uid, :c, 'Ana', 'Rios', :d, '1990-01-01')"
            " RETURNING id"
        ),
        {"uid": f"uid-{email}-{dni}", "c": email, "d": dni},
    ).scalar_one()


def _space(conn: Connection, s: str) -> UUID:
    return conn.execute(
        text(
            "WITH s AS (INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
            " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
            " RETURNING id)"
            " INSERT INTO space (venue_id, sport, kind, number, name, covered,"
            " lit, price_per_hour) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
            " 38000 FROM s RETURNING id"
        ),
        {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1"},
    ).scalar_one()


def _booking(conn: Connection, user: UUID, space: UUID, hours: int) -> None:
    start = datetime(2030, 11, 14, 8, tzinfo=ZONE)
    conn.execute(
        text(
            "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
            " VALUES (:u, :e, :i, :f, 38000, :t)"
        ),
        {
            "u": user,
            "e": space,
            "i": start,
            "f": start + timedelta(hours=hours),
            "t": 38000 * hours,
        },
    )


@pytest.mark.parametrize("hours", [1, 4])
def test_the_database_accepts_bookings_of_one_to_four_hours(
    db: Connection, unique: Callable[[], str], hours: int
) -> None:
    """the duration test covers the edges that are accepted @REV-08-S2"""
    s = unique()
    user = _user(db, f"borde.{s}@correo.com", str(int(s, 16) % 90_000_000 + 10_000_000))

    _booking(db, user, _space(db, s), hours)

    assert (
        db.execute(
            text("SELECT count(*) FROM booking WHERE user_id = :u"), {"u": user}
        ).scalar_one()
        == 1
    )


@pytest.mark.parametrize("hours", [0, 5])
def test_the_database_rejects_bookings_of_less_than_one_or_more_than_four_hours(
    db: Connection, unique: Callable[[], str], hours: int
) -> None:
    """the duration test covers the edges that are rejected @REV-08-S2"""
    s = unique()
    user = _user(db, f"borde.{s}@correo.com", str(int(s, 16) % 90_000_000 + 10_000_000))
    space = _space(db, s)

    with pytest.raises(IntegrityError), db.begin_nested():
        _booking(db, user, space, hours)


def test_deactivation_frees_the_dni_that_was_blocked_before(
    db: Connection, unique: Callable[[], str]
) -> None:
    """the deactivation test shows the DNI blocked before and freed after @REV-08-S3"""
    s = unique()
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    user = _user(db, f"vuelve.{s}@correo.com", dni)

    with pytest.raises(IntegrityError), db.begin_nested():
        _user(db, f"otro.{s}@correo.com", dni)
    db.execute(
        text("UPDATE app_user SET active = false, deactivated_at = now() WHERE id = :id"),
        {"id": user},
    )
    new = _user(db, f"otro.{s}@correo.com", dni)

    assert new != user


def test_deactivation_frees_the_email_that_was_blocked_before(
    db: Connection, unique: Callable[[], str]
) -> None:
    """deactivation frees the email that was blocked before @REV-08-S3"""
    s = unique()
    email = f"Vuelve.{s}@correo.com"
    user = _user(db, email, str(int(s, 16) % 90_000_000 + 10_000_000))

    with pytest.raises(IntegrityError), db.begin_nested():
        _user(db, email.lower(), str(int(s, 16) % 90_000_000 + 10_000_001))
    db.execute(
        text("UPDATE app_user SET active = false, deactivated_at = now() WHERE id = :id"),
        {"id": user},
    )
    new = _user(db, email.upper(), str(int(s, 16) % 90_000_000 + 10_000_001))

    assert new != user


def test_constraints_no_longer_has_the_two_misleading_tests() -> None:
    """test_constraints no longer has the two misleading tests, duration and deactivation
    @REV-08-S2 @assumption:REV-08-ASM-06
    """
    source = (API_ROOT / "tests" / "integration" / "test_constraints.py").read_text(
        encoding="utf-8"
    )

    assert "def test_la_reserva_dura_entre_una_y_cuatro_horas(" not in source
    assert "def test_la_baja_libera_el_correo_y_el_dni(" not in source


def _run(
    *arguments: str, remove: tuple[str, ...] = (), add: dict[str, str] | None = None
) -> "subprocess.CompletedProcess[str]":
    env = {k: v for k, v in os.environ.items() if k not in remove} | (add or {})
    return subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", *arguments],
        cwd=API_ROOT, env=env, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip


SCENARIO = "tests/scenarios/test_error_log.py"


def test_with_the_emulator_variable_missing_the_run_fails_with_a_clear_message() -> None:
    """with the emulator variable missing the run fails with a clear message
    @REV-08-S5 @assumption:REV-08-ASM-10
    """
    run = _run(SCENARIO, remove=("FIREBASE_AUTH_EMULATOR_HOST",))

    assert run.returncode != 0
    assert "the Firebase Auth emulator is required" in run.stdout + run.stderr
    assert "passed" not in run.stdout


def test_with_the_emulator_off_the_run_fails_with_a_clear_message() -> None:
    """with the emulator off the run fails with a clear message
    @REV-08-S5 @assumption:REV-08-ASM-10
    """
    run = _run(SCENARIO, add={"FIREBASE_AUTH_EMULATOR_HOST": "127.0.0.1:9"})

    assert run.returncode != 0
    assert "the Firebase Auth emulator is required" in run.stdout + run.stderr
    assert "passed" not in run.stdout


def test_without_the_auth_emulator_the_run_fails() -> None:
    """without the authentication emulator the suite does not come out green
    @REV-08-S5 @assumption:REV-08-ASM-03
    """
    env = {k: v for k, v in os.environ.items() if k != "FIREBASE_AUTH_EMULATOR_HOST"}

    run = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider",
         "tests/scenarios/test_error_log.py"],
        cwd=API_ROOT, env=env, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip

    assert run.returncode != 0
    assert "emulator" in run.stdout + run.stderr


def test_without_the_emulator_it_can_be_skipped_on_request_and_says_so() -> None:
    """skipping the API tests without an emulator only happens if requested
    @REV-08-S5 @assumption:REV-08-ASM-03
    """
    env = {k: v for k, v in os.environ.items() if k != "FIREBASE_AUTH_EMULATOR_HOST"}

    run = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", "--no-emulator",
         "tests/scenarios/test_error_log.py"],
        cwd=API_ROOT, env=env, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip

    assert run.returncode == 0
    assert "skipped" in run.stdout


@pytest.fixture
def queries() -> Iterator[list[str]]:
    """The SQL queries the API makes while the test lasts."""
    recorded: list[str] = []

    def record(*arguments: object) -> None:
        recorded.append(str(arguments[2]))

    event.listen(app_engine(), "before_cursor_execute", record)
    yield recorded
    event.remove(app_engine(), "before_cursor_execute", record)


def _member(api: TestClient, sign_in: Callable[[str, str], str | None], s: str) -> dict[str, str]:
    email = f"socio.{s}@correo.com"
    signup = api.post(
        "/register",
        json={
            "first_name": "Martín",
            "last_name": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "birth_date": "1994-07-21",
            "email": email,
            "password": PASSWORD,
        },
    )
    assert signup.status_code == 201
    token = sign_in(email, PASSWORD)
    assert token is not None
    return {"Authorization": f"Bearer {token}"}


def _upcoming(engine: Engine, email: str, space: UUID, count: int) -> None:
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT u.id, :e, h + make_interval(days => n), h + make_interval(days => n)"
                " + interval '1 hour', 38000, 38000 FROM app_user u,"
                " generate_series(1, :c) AS n,"
                " (SELECT date_trunc('day', now(), 'America/Argentina/Buenos_Aires')"
                " + interval '13 hours' + make_interval(days => 400) AS h) AS t"
                " WHERE u.email = :email AND u.active"
            ),
            {"e": space, "c": count, "email": email},
        )


def _count(queries: list[str], request: Callable[[], object]) -> int:
    queries.clear()
    request()
    return len(queries)


def test_my_bookings_runs_the_same_queries_with_few_or_many(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    queries: list[str],
) -> None:
    """the upcoming bookings are read with a fixed number of queries
    @REV-08-S6 @assumption:REV-08-ASM-05
    """
    s = unique()
    session = _member(api, sign_in, s)
    with engine.begin() as conn:
        space = _space(conn, s)
    email = f"socio.{s}@correo.com"
    _upcoming(engine, email, space, 2)
    few = _count(queries, lambda: api.get("/bookings", headers=session))
    with engine.begin() as conn:
        other = _space(conn, f"{s}b")
    _upcoming(engine, email, other, 13)

    many = _count(queries, lambda: api.get("/bookings", headers=session))

    assert many == few


@pytest.fixture
def admin(
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> dict[str, str]:
    s = unique()
    monkeypatch.setenv("ADMIN_PASSWORD", PASSWORD)
    arguments = [
        "--email", f"admin.{s}@club.com", "--first-name", "Ana", "--last-name", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--birth-date", "1985-06-01",
    ]  # fmt: skip
    assert seed_admin(arguments) == 0
    token = sign_in(f"admin.{s}@club.com", PASSWORD)
    assert token is not None
    return {"Authorization": f"Bearer {token}"}


def test_venues_and_the_global_history_run_fixed_queries(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    admin: dict[str, str],
    queries: list[str],
) -> None:
    """venues and the global history are read with a fixed number of queries
    @REV-08-S6 @assumption:REV-08-ASM-05
    """
    s = unique()
    _member(api, sign_in, s)
    with engine.begin() as conn:
        space = _space(conn, s)
    _upcoming(engine, f"socio.{s}@correo.com", space, 2)
    venues_before = _count(queries, lambda: api.get("/venues", headers=admin))
    history_before = _count(queries, lambda: api.get("/bookings/all", headers=admin))
    with engine.begin() as conn:
        others = [_space(conn, f"{s}{n}") for n in range(5)]
    _upcoming(engine, f"socio.{s}@correo.com", others[0], 13)

    venues_after = _count(queries, lambda: api.get("/venues", headers=admin))
    history_after = _count(queries, lambda: api.get("/bookings/all", headers=admin))

    assert venues_after == venues_before
    assert history_after == history_before


def _use_cases() -> list[str]:
    source = (API_ROOT / "app" / "modules" / "bookings" / "use_cases.py").read_text(
        encoding="utf-8"
    )
    return [
        n.name
        for n in ast.parse(source).body
        if isinstance(n, ast.FunctionDef) and not n.name.startswith("_")
    ]


def test_every_public_bookings_function_has_its_unit_test() -> None:
    """every public function of bookings/use_cases.py has its unit test
    @REV-08-S7 @assumption:REV-08-ASM-09
    """
    unit_tests = API_ROOT / "tests" / "unit" / "test_use_cases_bookings.py"
    code = unit_tests.read_text(encoding="utf-8") if unit_tests.exists() else ""

    assert len(_use_cases()) >= 7
    assert [c for c in _use_cases() if not re.search(rf"{c}\(", code)] == []


def test_rnf_01_h04_01_is_tested_against_the_published_contract(api: TestClient) -> None:
    """RNF-01-H04-01 is tested against the published contract and not by reading the README
    @REV-08-S4 @assumption:REV-08-ASM-08
    """
    contract = api.get("/openapi.json")
    source = (API_ROOT / "tests" / "scenarios" / "test_non_functional_requirements.py").read_text(
        encoding="utf-8"
    )

    assert contract.status_code == 200
    assert len(contract.json()["paths"]) >= 20
    assert "swagger" in api.get("/docs").text.lower()
    assert "_endpoints_que_usa_la_app" not in source


def test_the_bookings_use_cases_are_tested_without_database_or_emulator() -> None:
    """the bookings use cases have unit tests that allow measuring the mutation
    @REV-08-S7
    """
    unit_tests = API_ROOT / "tests" / "unit" / "test_use_cases_bookings.py"
    without_services = {
        **{k: v for k, v in os.environ.items() if k != "FIREBASE_AUTH_EMULATOR_HOST"},
        "DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
        "TEST_DATABASE_URL": "postgresql+psycopg://nadie:nadie@127.0.0.1:9/nada_test",
    }

    run = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", str(unit_tests)],
        cwd=API_ROOT, env=without_services, capture_output=True, text=True, timeout=120, check=False,
    )  # fmt: skip

    assert run.returncode == 0, run.stdout[-2000:]
    code = unit_tests.read_text(encoding="utf-8")
    assert [c for c in _use_cases() if not re.search(rf"\b{c}\(", code)] == []
