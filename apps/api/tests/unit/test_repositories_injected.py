import ast
from datetime import date, time
from pathlib import Path
from uuid import UUID

from fastapi.testclient import TestClient

from app.main import create_app
from app.modules.session.current_user import current_user
from app.modules.session.profile import Profile
from app.modules.venues.repository import venue_repository
from app.modules.venues.rules import Venue

INTERFACE = Path(__file__).resolve().parents[2] / "app" / "interfaz"
# The console commands have no HTTP request: they build their own pieces.
COMMANDS = {"barrido.py", "sembrar_admin.py"}


def _constructions(file: Path) -> list[str]:
    """What the file builds of infrastructure: `…Sql(…)` and `FirebaseProvider(…)`."""
    tree = ast.parse(file.read_text(encoding="utf-8"))
    return [
        f"{file.name}:{node.lineno} {node.func.id}"
        for node in ast.walk(tree)
        if isinstance(node, ast.Call)
        and isinstance(node.func, ast.Name)
        and (node.func.id.endswith("Sql") or node.func.id == "FirebaseProvider")
    ]


def test_no_route_builds_a_repository_or_an_infrastructure_service() -> None:
    """no route builds a repository or an infrastructure service
    @ARQ-01-S1 @assumption:ARQ-01-ASM-01"""
    routes = [a for a in sorted(INTERFACE.glob("*.py")) if a.name not in COMMANDS]
    found = [c for file in routes for c in _constructions(file)]
    assert found == []


class _TestVenues:
    def active(self) -> list[Venue]:
        return [
            Venue(
                id=UUID(int=7),
                name="Sede de prueba",
                street="Calle",
                street_number=123,
                opens_at=time(8),
                closes_at=time(22),
                open_days=(1, 2, 3, 4, 5),
                space_count=2,
                sports=("futbol",),
            )
        ]


def test_a_route_receives_its_repository_by_dependency_and_a_test_replaces_it() -> None:
    """a route receives its repository by dependency and a test replaces it @ARQ-01-S2"""
    app = create_app()
    app.dependency_overrides[current_user] = lambda: Profile(
        id=UUID(int=1),
        uid="uid-prueba",
        first_name="Ana",
        last_name="Díaz",
        email="ana@club.test",
        role="user",
        dni="30111222",
        birth_date=date(1990, 1, 1),
    )
    app.dependency_overrides[venue_repository] = _TestVenues

    response = TestClient(app, base_url="http://localhost").get("/venues")

    assert response.status_code == 200
    assert [s["name"] for s in response.json()["venues"]] == ["Sede de prueba"]


def test_a_route_with_two_repositories_builds_them_on_the_same_connection() -> None:
    """a route with two repositories builds them on the same connection @ARQ-01-ASM-02"""
    from typing import Annotated

    from fastapi import Depends, FastAPI

    from app.modules.bookings.repository import BookingsSql, bookings_repository
    from app.modules.notifications.repository import NotificationsSql, notifications_repository
    from app.shared.db import connection

    app = FastAPI()
    connections: list[object] = []

    def fake_connection() -> object:
        new = object()
        connections.append(new)
        return new

    @app.get("/dos")
    def two(
        bookings: Annotated[BookingsSql, Depends(bookings_repository)],
        notices: Annotated[NotificationsSql, Depends(notifications_repository)],
    ) -> bool:
        return bookings._conn is notices._conn

    app.dependency_overrides[connection] = fake_connection

    response = TestClient(app).get("/dos")

    assert response.json() is True
    assert len(connections) == 1
