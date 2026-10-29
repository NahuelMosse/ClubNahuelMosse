"""`DELETE /yo` contra la base y el emulador reales."""

import os
from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.users.seed_admin import main as sembrar

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
CONTRASENA = "ClubNahuel1"


def _registrar(api: TestClient, s: str) -> tuple[str, str]:
    correo = f"socia.{s}@correo.com"
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    pedido = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": dni,
        "birth_date": "1998-11-02",
        "email": correo,
        "password": CONTRASENA,
    }
    assert api.post("/register", json=pedido).status_code == 201
    return correo, dni


def _espacio(motor: Engine, s: str) -> UUID:
    with motor.begin() as conn:
        sede: Any = conn.execute(
            text(
                "INSERT INTO venue (name, street, street_number, opens_at, closes_at, open_days)"
                " VALUES (:n, 'Belgrano', 1240, '00:00', '00:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede {s}"},
        ).scalar_one()
        return UUID(
            str(
                conn.execute(
                    text(
                        "INSERT INTO space (venue_id, sport, kind, number, name,"
                        " price_per_hour, covered, lit)"
                        " VALUES (:venue, 'Voley', 'IND', 1, :n, 33000, true, true) RETURNING id"
                    ),
                    {"venue": sede, "n": f"RamosMejia_Belgrano_1240_Voley_IND_1_{s}"},
                ).scalar_one()
            )
        )


def _reservar(motor: Engine, correo: str, espacio: UUID, inicio: datetime) -> UUID:
    with motor.begin() as conn:
        return UUID(
            str(
                conn.execute(
                    text(
                        "INSERT INTO booking (user_id, space_id, starts_at, ends_at,"
                        " price_per_hour, total)"
                        " SELECT id, :e, :i, :f, 33000, 33000 FROM app_user"
                        " WHERE email = :c AND active RETURNING id"
                    ),
                    {"c": correo, "e": espacio, "i": inicio, "f": inicio + timedelta(hours=1)},
                ).scalar_one()
            )
        )


def test_la_baja_es_logica_conserva_el_historial_y_libera_el_correo(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    s = unico()
    correo, dni = _registrar(api, s)
    espacio = _espacio(motor, s)
    hora = datetime.now(ZONA).replace(minute=0, second=0, microsecond=0)
    pasada = _reservar(motor, correo, espacio, hora - timedelta(days=3))
    en_curso = _reservar(motor, correo, espacio, hora)
    futura = _reservar(motor, correo, espacio, hora + timedelta(days=1))
    token = iniciar_sesion(correo, CONTRASENA)

    assert api.delete("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 204

    with motor.connect() as conn:
        estados: dict[UUID, str] = dict(
            conn.execute(
                text("SELECT id, status FROM booking WHERE id IN (:a, :b, :c)"),
                {"a": pasada, "b": en_curso, "c": futura},
            ).all()
        )
        activo: Any = conn.execute(
            text("SELECT active FROM app_user WHERE email = :c"), {"c": correo}
        ).scalar_one()
    # Verifica CU-07-SUP-04: la futura se cancela; la pasada y la que está en curso quedan.
    assert estados == {pasada: "active", en_curso: "active", futura: "canceled"}
    assert activo is False
    # La sesión ya no vale y con esa contraseña no se entra.
    assert api.get("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401
    assert iniciar_sesion(correo, CONTRASENA) is None
    # Verifica CU-07-SUP-01: el correo y el DNI quedan libres para una cuenta nueva.
    otra = {
        "first_name": "Lucía",
        "last_name": "Gómez",
        "dni": dni,
        "birth_date": "1998-11-02",
        "email": correo,
        "password": CONTRASENA,
    }
    assert api.post("/register", json=otra).status_code == 201


def test_un_administrador_no_se_da_de_baja(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    s = unico()
    correo = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", correo, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(correo, CONTRASENA)
    assert api.delete("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 403
    assert api.get("/me", headers={"Authorization": f"Bearer {token}"}).status_code == 200
    os.environ.pop("ADMIN_CONTRASENA", None)


def test_sin_sesion_no_hay_baja(api: TestClient) -> None:
    assert api.delete("/me").status_code == 401


def test_dos_bajas_a_la_vez_dan_de_baja_una_sola_vez(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    from concurrent.futures import ThreadPoolExecutor

    correo, _ = _registrar(api, unico())
    token = iniciar_sesion(correo, CONTRASENA)
    with ThreadPoolExecutor(max_workers=2) as pool:
        codigos = sorted(
            pool.map(
                lambda _: (
                    api.delete("/me", headers={"Authorization": f"Bearer {token}"}).status_code
                ),
                range(2),
            )
        )
    # Una hace la baja; la otra ya la encuentra hecha (204) o la sesión vencida (401).
    assert codigos[0] == 204 and codigos[1] in (204, 401)
    with motor.connect() as conn:
        activo: Any = conn.execute(
            text("SELECT active FROM app_user WHERE email = :c"), {"c": correo}
        ).scalar_one()
    assert activo is False
