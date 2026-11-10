"""The non-functional requirements of the brief, checked against the repo and the real API."""

import hashlib
import os
import re
import subprocess
from collections.abc import Callable
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

import httpx2
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from tests.readme_checks import (
    assert_app_readme_covers_setup_and_run,
    assert_scripts_exist,
    headings,
)

ROOT = Path(__file__).resolve().parents[4]
APP = ROOT / "apps" / "mobile"
API = ROOT / "apps" / "api"
NAME = "ClubNahuelMosse"
ZONE = ZoneInfo("America/Argentina/Buenos_Aires")
METHODS = {"get", "post", "put", "delete", "patch"}

# What the API serves without a session: account sign-up and password recovery (with the page of the email link).
PUBLIC = {
    ("post", "/register"),
    ("post", "/password-recovery"),
    ("post", "/password-recovery/check"),
    ("put", "/password-recovery"),
    ("get", "/link/recover"),
    ("get", "/health"),
}

# The ic_launcher.png that `flutter create` generates, per density.
DEFAULT_ICON = {
    "13e9c72ec37fac220397aa819fa1ef2d",
    "6270344430679711b81476e29878caa7",
    "a0a8db5985280b3679d99a820ae2db79",
    "afe1b655b9f32da22f9a4301bb8e6ba8",
    "57838d52c318faff743130c3fcfae0c6",
}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _normalize(route: str) -> str:
    without_query = route.split("?")[0]
    without_interpolation = re.sub(r"\$\{[^}]*\}|\$\w+|\{[^}]*\}", "{}", without_query)
    return without_interpolation.rstrip("/") or "/"


def _endpoints_the_app_uses() -> set[tuple[str, str]]:
    """Each API call with a literal route: `_api.get('/x')`, `_get('/x')`, `Uri(path: '/x')`."""
    calls = re.compile(r"\b_?api\.(get|post|put|delete)\(\s*'([^']+)'")
    found = {
        (m.group(1), _normalize(m.group(2)))
        for f in (APP / "lib").rglob("*.dart")
        for m in calls.finditer(_read(f))
    }
    # The catalog, the search and the grid build a `Uri` and ask with GET.
    for f in (
        APP / "lib" / "features" / "spaces" / "data" / "spaces_repository.dart",
        APP / "lib" / "features" / "bookings" / "data" / "availability_api.dart",
    ):
        for m in re.finditer(r"(?:_get\(\s*'([^']+)'|path:\s*'([^']+)')", _read(f)):
            found.add(("get", _normalize(m.group(1) or m.group(2))))
    return found


def _operations(api: TestClient) -> set[tuple[str, str]]:
    schema = api.get("/openapi.json").json()
    return {
        (method, _normalize(route))
        for route, ops in schema["paths"].items()
        for method in ops
        if method in METHODS
    }


def test_the_app_is_called_clubnahuelmosse_on_the_device_and_in_the_repository() -> None:
    """the app is called ClubNahuelMosse on the device and the repository has the same name @RNF-01-H01-01"""
    manifest = _read(APP / "android" / "app" / "src" / "main" / "AndroidManifest.xml")
    gradle = _read(APP / "android" / "app" / "build.gradle.kts")

    assert f'android:label="{NAME}"' in manifest
    assert f'applicationId = "ar.edu.unimoron.{NAME.lower()}"' in gradle
    assert re.search(rf"^name: {NAME.lower()}$", _read(APP / "pubspec.yaml"), re.M)
    origin = _git("remote", "get-url", "origin")
    assert re.fullmatch(rf"https://github\.com/[^/]+/{NAME}(\.git)?", origin), origin


def test_the_app_is_a_flutter_project_for_android() -> None:
    """the app is a Flutter project that builds and runs on an Android emulator @RNF-01-H02-01"""
    pubspec = _read(APP / "pubspec.yaml")

    assert re.search(r"^dependencies:\n  flutter:\n    sdk: flutter$", pubspec, re.M)
    assert (APP / "lib" / "main.dart").is_file()
    assert (APP / "android" / "app" / "build.gradle.kts").is_file()
    activity = next((APP / "android" / "app" / "src" / "main" / "kotlin").rglob("MainActivity.kt"))
    assert "FlutterActivity" in _read(activity)


def _git(*args: str) -> str:
    try:
        r = subprocess.run(
            ["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=True
        )
    except (OSError, subprocess.CalledProcessError):
        pytest.skip("the git history of the repository is required")
    return r.stdout.strip()


def test_the_repository_is_the_students_and_the_history_has_commits_throughout_development() -> (
    None
):
    """the repository is of the student's account and the history has commits throughout development @RNF-01-H03-01 @assumption:RNF-01-SUP-06"""
    origin = _git("remote", "get-url", "origin")
    dates = _git("log", "--format=%ad", "--date=short").splitlines()

    assert origin.startswith("https://github.com/NahuelMosse/")
    assert len(dates) >= 50
    assert len(set(dates)) >= 3


def test_the_api_publishes_openapi_with_every_endpoint_the_app_uses(api: TestClient) -> None:
    """the API publishes its OpenAPI documentation with every endpoint the app uses @RNF-01-H04-01"""
    used = _endpoints_the_app_uses()
    published = _operations(api)

    assert len(used) >= 30, "the calls of the app were not read"
    assert used <= published, sorted(used - published)
    docs = api.get("/docs")
    assert docs.status_code == 200
    assert "swagger" in docs.text.lower()


def test_the_api_stores_the_data_in_postgresql(engine: Engine) -> None:
    """the API stores the data in a PostgreSQL database @RNF-01-H05-01"""
    with engine.connect() as conn:
        version: Any = conn.execute(text("SELECT version()")).scalar_one()
        tables: Any = conn.execute(
            text("SELECT count(*) FROM information_schema.tables WHERE table_name = 'booking'")
        ).scalar_one()

    assert str(version).startswith("PostgreSQL")
    assert tables == 1


@pytest.mark.skipif(
    not os.environ.get("API_URL_NUBE"),
    reason="API_URL_NUBE is required, with the public address of the deployed API",
)
def test_the_api_answers_from_a_public_url_in_the_cloud() -> None:
    """the API and the database answer from a public URL in the cloud and the installed app uses that URL @RNF-01-H06-01"""
    base = os.environ["API_URL_NUBE"].rstrip("/")

    schema = httpx2.get(f"{base}/openapi.json", timeout=60)
    venues = httpx2.get(f"{base}/sedes", timeout=60)

    assert base.startswith("https://")
    assert schema.status_code == 200
    # Without a session the cloud rejects, and to answer 401 it had to open its database.
    assert venues.status_code == 401


def test_every_api_operation_without_an_authenticated_user_is_rejected(api: TestClient) -> None:
    """an operation on users or bookings without an authenticated user is rejected @RNF-01-H06-02 @assumption:RNF-01-SUP-01"""
    schema: dict[str, Any] = api.get("/openapi.json").json()
    accepted = []
    rejected = 0

    for route, ops in schema["paths"].items():
        for method in ops:
            if method not in METHODS or (method, route) in PUBLIC:
                continue
            url = re.sub(r"\{[^}]*\}", "1", route)
            r = api.request(method.upper(), url, json={} if method != "get" else None)
            if r.status_code == 401:
                rejected += 1
            else:
                accepted.append((method, route, r.status_code))

    assert not accepted, accepted
    assert rejected >= 25
    fake_token = {"Authorization": "Bearer no-es-un-token"}
    assert api.get("/bookings", headers=fake_token).status_code == 401
    assert api.get("/me", headers=fake_token).status_code == 401


def test_bookings_act_on_the_authenticated_user_and_not_on_another_one_in_the_request(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """an operation on bookings acts on the authenticated user and not on another one given in the request @RNF-01-H06-03"""
    ids: list[Any] = []
    sessions: list[dict[str, str]] = []
    for name in ("Ana", "Beto"):
        s = unique()
        email = f"{name.lower()}.{s}@correo.com"
        signup = api.post(
            "/register",
            json={
                "first_name": name,
                "last_name": "Ferreyra",
                "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
                "birth_date": "1994-07-21",
                "email": email,
                "password": "ClubNahuel1",
            },
        )
        assert signup.status_code == 201
        token = sign_in(email, "ClubNahuel1")
        assert token is not None
        sessions.append({"Authorization": f"Bearer {token}"})
        with engine.connect() as conn:
            ids.append(
                conn.execute(
                    text("SELECT id FROM app_user WHERE email = :c"), {"c": email}
                ).scalar_one()
            )
    ana, beto = sessions
    ana_id, beto_id = ids
    s = unique()
    with engine.begin() as conn:
        space: Any = conn.execute(
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
    tomorrow = (datetime.now(ZONE).date() + timedelta(days=1)).isoformat()

    # Beto books in his own name; Ana tries to book and cancel «as Beto».
    beto_booking = api.post(
        "/bookings",
        headers=beto,
        json={"space_id": str(space), "date": tomorrow, "start_hour": "10:00", "hours": 1},
    )
    ana_booking = api.post(
        "/bookings",
        headers=ana,
        json={
            "space_id": str(space),
            "date": tomorrow,
            "start_hour": "12:00",
            "hours": 1,
            "user_id": str(beto_id),
        },
    )
    attempt = api.post(f"/bookings/{beto_booking.json()['id']}/cancel", headers=ana)

    assert (beto_booking.status_code, ana_booking.status_code) == (201, 201)
    with engine.connect() as conn:
        owner = {
            str(r.id): r.user_id
            for r in conn.execute(
                text("SELECT id, user_id FROM booking WHERE space_id = :e"), {"e": space}
            )
        }
        status: Any = conn.execute(
            text("SELECT status FROM booking WHERE id = :i"), {"i": beto_booking.json()["id"]}
        ).scalar_one()
    assert owner == {beto_booking.json()["id"]: beto_id, ana_booking.json()["id"]: ana_id}
    assert attempt.status_code in (403, 404)
    assert status == "active"
    mine = api.get("/bookings", headers=ana).json()["bookings"]
    assert [r["id"] for r in mine] == [ana_booking.json()["id"]]


def test_the_app_readme_is_enough_to_configure_and_run_it() -> None:
    """following only the README of the app, the app is configured and run @RNF-01-H07-01 @assumption:RNF-01-SUP-05"""
    assert_app_readme_covers_setup_and_run(APP / "lib" / "common" / "config.dart")


def test_the_backend_readme_is_enough_to_configure_run_and_deploy() -> None:
    """following only the README of the backend, the API is configured, run and deployed @RNF-01-H07-02 @assumption:RNF-01-SUP-05"""
    readme = _read(API / "README.md")
    configuration = _read(API / "app" / "shared" / "config.py")
    variables = {
        field.upper()
        for field in re.findall(r"^    ([a-z_]+): ", configuration, re.M)
        if field != "model_config"
    }

    for section in ("configure", "run", "test", "deploy"):
        assert section in headings(readme), section
    assert variables >= {"DATABASE_URL", "FIREBASE_PROJECT_ID", "PUBLIC_URL"}
    assert not {v for v in variables if v not in readme}, "undocumented variables"
    assert_scripts_exist(readme)
    assert "alembic upgrade head" in readme
    assert "/docs" in readme


def test_the_app_has_its_own_icon_in_the_launcher() -> None:
    """the app has its own icon in the launcher @RNF-01-H08-01"""
    pubspec = _read(APP / "pubspec.yaml")
    image = re.search(r"^\s+image_path: \"?([^\"\n]+)\"?$", pubspec, re.M)
    res = APP / "android" / "app" / "src" / "main" / "res"
    icons = sorted(res.glob("mipmap-*dpi/ic_launcher.png"))

    assert "flutter_launcher_icons:" in pubspec
    assert image is not None and (APP / image.group(1)).is_file()
    assert len(icons) == 5
    own = {hashlib.md5(i.read_bytes()).hexdigest() for i in icons}
    assert not own & DEFAULT_ICON
    assert (res / "mipmap-anydpi-v26" / "ic_launcher.xml").is_file()
