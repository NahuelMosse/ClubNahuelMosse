"""Corrected versions of three ENG-18 tests of the English HTTP contract."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import re
from collections.abc import Callable, Sequence
from typing import Any

from fastapi import FastAPI
from fastapi.routing import APIRoute
from fastapi.testclient import TestClient
from fastapi.utils import generate_unique_id
from sqlalchemy import Engine

from app.shared import http_errors
from tests.integracion.test_contract_in_english import PASSWORD, _auth, _book, _register, _space


def test_every_hand_built_409_body_names_its_fields_in_english(
    api: TestClient,
    token_admin: str,
    token_usuario: str,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    sede: tuple[str, str],
) -> None:
    """every hand-built 409 body names its fields in English: space name, venue bookings_outside, dni and duplicate user @ENG-18-S2"""
    space = _space(api, token_admin, sede[0], number=1)
    taken = api.post(
        "/spaces",
        headers=_auth(token_admin),
        json={"venue_id": sede[0], "sport": "Futbol", "kind": "F5", "covered": True, "lit": True,
              "price_per_hour": 38000, "number": 1},
    )  # fmt: skip
    assert (taken.status_code, set(taken.json())) == (409, {"errors", "name", "number"})
    assert set(taken.json()["errors"]) == {"name"}

    assert _book(api, token_usuario, space["id"]).status_code == 201
    outside = api.put(
        f"/venues/{sede[0]}",
        headers=_auth(token_admin),
        json={"name": "Sede Haedo", "address": "Av. Vergara 1850", "opens_at": "08:00", "closes_at": "20:00",
              "open_days": [1, 2, 3, 4, 5, 6, 7]},
    )  # fmt: skip
    assert (outside.status_code, outside.json()) == (409, {"bookings_outside": 1})
    not_removable = api.delete(f"/venues/{sede[0]}", headers=_auth(token_admin))
    assert (not_removable.status_code, set(not_removable.json()["errors"])) == (409, {"venue"})
    space_kept = api.delete(f"/spaces/{space['id']}", headers=_auth(token_admin))
    assert (space_kept.status_code, set(space_kept.json()["errors"])) == (409, {"space"})

    first = _register(api, unico())
    again = api.post("/register", json=first)
    assert again.status_code == 409
    assert set(again.json()) == {"message", "fields", "errors"}
    assert set(again.json()["fields"]) == {"email", "dni"} == set(again.json()["errors"])

    second = _register(api, unico())
    token = iniciar_sesion(second["email"], PASSWORD)
    assert token is not None
    own_dni = api.put(
        "/me",
        headers=_auth(token),
        json={"first_name": "Lucía", "last_name": "Gómez", "dni": first["dni"], "birth_date": "1998-11-02"},
    )
    assert (own_dni.status_code, set(own_dni.json()["errors"])) == (409, {"dni"})
    slot = _book(api, token, space["id"])
    assert (slot.status_code, set(slot.json()["errors"])) == (409, {"slot"})


def _api_routes(routes: Sequence[Any]) -> list[APIRoute]:
    """FastAPI 0.141 wraps each included router: its routes live in `original_router`, nested."""
    found: list[APIRoute] = []
    for route in routes:
        if isinstance(route, APIRoute) and route.include_in_schema:
            found.append(route)
        inner = getattr(route, "original_router", None)
        if inner is not None:
            found.extend(_api_routes(inner.routes))
    return found


def test_every_operation_id_is_fastapis_default_over_the_english_handler() -> None:
    """every operationId is FastAPI's default over the English handler @ENG-18-S4 @assumption:ENG-18-ASM-03"""
    from app.main import create_app

    app = create_app()
    routes = _api_routes(app.routes)
    assert routes
    assert all(r.operation_id is None for r in routes)
    published = app.openapi()["paths"]
    ids = {op["operationId"] for methods in published.values() for op in methods.values()}
    assert ids == {generate_unique_id(r) for r in routes}
    assert published["/venues"]["get"]["operationId"] == "list_venues_venues_get"
    assert not {i for i in ids if re.search(r"sede|espacio|reserva|yo_|vivo|dispositivo", i)}


def test_the_testing_support_lives_under_testing_with_english_names(
    motor: Engine, token_admin: str, token_usuario: str, unico: Callable[[], str], sede: tuple[str, str]
) -> None:
    """the testing support lives under /_testing with English names @assumption:ENG-18-ASM-09"""
    from app import e2e_support

    app = FastAPI()
    http_errors.install(app)
    app.include_router(e2e_support.router)
    with TestClient(app) as support:
        assert support.get("/_pruebas/correos", params={"para": "x@y.com"}).status_code == 404
        sent = support.get("/_testing/emails", params={"to": "nadie@correo.com"})
        assert (sent.status_code, sent.json()) == (200, {"emails": []})
        devices = support.get("/_testing/devices", params={"email": "nadie@correo.com"})
        assert devices.json() == {"devices": []}
        assert support.post("/_testing/bookings/clear").status_code == 204
        assert support.post("/_testing/venues/deactivate", json={"name": "Sede inexistente"}).status_code == 204
        assert support.post("/_testing/spaces/deactivate", json={"space": "Espacio inexistente"}).status_code == 204
        assert support.post("/_testing/bookings/start", json={"space": "Espacio inexistente"}).status_code == 204
        assert support.post("/_testing/bookings/void", json={"space": "Espacio inexistente"}).status_code == 204
        assert support.post("/_testing/password-recovery/x/expire").status_code == 204
        reminders = support.post("/_testing/reminders", json={"email": "nadie@correo.com"})
        assert reminders.json() == {"registered": 0}
        occupy = support.post(
            "/_testing/bookings",
            json={"space": "Espacio inexistente", "date": "2030-01-01", "hour": 10, "hours": 1,
                  "email": None, "status": "active", "reason": None},
        )  # fmt: skip
        assert occupy.status_code == 404
