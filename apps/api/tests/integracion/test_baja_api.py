"""`DELETE /yo` contra la base y el emulador reales."""

import os
from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.interfaz.sembrar_admin import main as sembrar

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
CONTRASENA = "ClubNahuel1"


def _registrar(api: TestClient, s: str) -> tuple[str, str]:
    correo = f"socia.{s}@correo.com"
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    pedido = {
        "nombre": "Lucía",
        "apellido": "Gómez",
        "dni": dni,
        "fecha_nacimiento": "1998-11-02",
        "correo": correo,
        "contrasena": CONTRASENA,
    }
    assert api.post("/registro", json=pedido).status_code == 201
    return correo, dni


def _espacio(motor: Engine, s: str) -> int:
    with motor.begin() as conn:
        sede: Any = conn.execute(
            text(
                "INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES (:n, 'Belgrano', 1240, '00:00', '00:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id"
            ),
            {"n": f"Sede {s}"},
        ).scalar_one()
        return int(
            conn.execute(
                text(
                    "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre,"
                    " precio_por_hora, techada, iluminada)"
                    " VALUES (:sede, 'Voley', 'IND', 1, :n, 33000, true, true) RETURNING id"
                ),
                {"sede": sede, "n": f"RamosMejia_Belgrano_1240_Voley_IND_1_{s}"},
            ).scalar_one()
        )


def _reservar(motor: Engine, correo: str, espacio: int, inicio: datetime) -> int:
    with motor.begin() as conn:
        return int(
            conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin,"
                    " precio_por_hora, total)"
                    " SELECT id, :e, :i, :f, 33000, 33000 FROM usuario"
                    " WHERE correo = :c AND activo RETURNING id"
                ),
                {"c": correo, "e": espacio, "i": inicio, "f": inicio + timedelta(hours=1)},
            ).scalar_one()
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

    assert api.delete("/yo", headers={"Authorization": f"Bearer {token}"}).status_code == 204

    with motor.connect() as conn:
        estados: dict[int, str] = dict(
            conn.execute(
                text("SELECT id, estado FROM reserva WHERE id IN (:a, :b, :c)"),
                {"a": pasada, "b": en_curso, "c": futura},
            ).all()
        )
        activo: Any = conn.execute(
            text("SELECT activo FROM usuario WHERE correo = :c"), {"c": correo}
        ).scalar_one()
    # Verifica CU-07-SUP-04: la futura se cancela; la pasada y la que está en curso quedan.
    assert estados == {pasada: "activa", en_curso: "activa", futura: "cancelada"}
    assert activo is False
    # La sesión ya no vale y con esa contraseña no se entra.
    assert api.get("/yo", headers={"Authorization": f"Bearer {token}"}).status_code == 401
    assert iniciar_sesion(correo, CONTRASENA) is None
    # Verifica CU-07-SUP-01: el correo y el DNI quedan libres para una cuenta nueva.
    otra = {
        "nombre": "Lucía",
        "apellido": "Gómez",
        "dni": dni,
        "fecha_nacimiento": "1998-11-02",
        "correo": correo,
        "contrasena": CONTRASENA,
    }
    assert api.post("/registro", json=otra).status_code == 201


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
    assert api.delete("/yo", headers={"Authorization": f"Bearer {token}"}).status_code == 403
    assert api.get("/yo", headers={"Authorization": f"Bearer {token}"}).status_code == 200
    os.environ.pop("ADMIN_CONTRASENA", None)


def test_sin_sesion_no_hay_baja(api: TestClient) -> None:
    assert api.delete("/yo").status_code == 401


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
                    api.delete("/yo", headers={"Authorization": f"Bearer {token}"}).status_code
                ),
                range(2),
            )
        )
    # Una hace la baja; la otra ya la encuentra hecha (204) o la sesión vencida (401).
    assert codigos[0] == 204 and codigos[1] in (204, 401)
    with motor.connect() as conn:
        activo: Any = conn.execute(
            text("SELECT activo FROM usuario WHERE correo = :c"), {"c": correo}
        ).scalar_one()
    assert activo is False
