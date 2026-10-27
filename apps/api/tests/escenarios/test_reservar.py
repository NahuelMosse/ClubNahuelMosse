from collections.abc import Callable
from datetime import date, datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")


@pytest.fixture
def cancha(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> tuple[dict[str, str], str]:
    """Una cuenta de usuario y un Fútbol 5 en una sede de 08:00 a 23:00 todos los días."""
    s = unico()
    correo = f"socio.{s}@correo.com"
    alta = api.post(
        "/registro",
        json={
            "nombre": "Martín",
            "apellido": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1994-07-21",
            "correo": correo,
            "contrasena": "ClubNahuel1",
        },
    )
    assert alta.status_code == 201
    with motor.begin() as conn:
        espacio: Any = conn.execute(
            text(
                "WITH s AS (INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id)"
                " INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id"
            ),
            {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1"},
        ).scalar_one()
    token = iniciar_sesion(correo, "ClubNahuel1")
    assert token is not None
    return {"Authorization": f"Bearer {token}"}, str(espacio)


def _manana() -> date:
    return datetime.now(ZONA).date() + timedelta(days=1)


def _reservas(motor: Engine, espacio: str) -> int:
    with motor.connect() as conn:
        return int(
            conn.execute(
                text("SELECT count(*) FROM reserva WHERE espacio_id = :e"), {"e": espacio}
            ).scalar_one()
        )


def test_el_backend_rechaza_una_reserva_en_un_horario_pasado(
    api: TestClient, motor: Engine, cancha: tuple[dict[str, str], str]
) -> None:
    """el backend rechaza una reserva en un horario pasado @CU-09-H01-04"""
    sesion, espacio = cancha
    ayer = datetime.now(ZONA).date() - timedelta(days=1)

    r = api.post(
        "/reservas",
        headers=sesion,
        json={"espacio_id": espacio, "fecha": ayer.isoformat(), "desde": "10:00", "horas": 1},
    )

    # Verifica: la rechaza por la fecha y no guarda nada.
    assert r.status_code == 422
    assert r.json()["errores"]["fecha"] == "La fecha tiene que ser futura"
    assert _reservas(motor, espacio) == 0


def test_el_backend_rechaza_una_reserva_que_termina_despues_del_cierre_de_la_sede(
    api: TestClient, motor: Engine, cancha: tuple[dict[str, str], str]
) -> None:
    """el backend rechaza una reserva que termina después del cierre de la sede @CU-09-H01-05"""
    sesion, espacio = cancha

    r = api.post(
        "/reservas",
        headers=sesion,
        json={
            "espacio_id": espacio,
            "fecha": _manana().isoformat(),
            "desde": "22:00",
            "horas": 2,
        },
    )

    # Verifica: la rechaza por el cierre y no guarda nada.
    assert r.status_code == 422
    assert r.json()["errores"]["hasta"] == "La sede cierra a las 23:00"
    assert _reservas(motor, espacio) == 0


def test_el_backend_rechaza_una_reserva_que_no_empieza_o_no_termina_en_hora_completa(
    api: TestClient, motor: Engine, cancha: tuple[dict[str, str], str]
) -> None:
    """el backend rechaza una reserva que no empieza o no termina en hora completa @CU-09-H01-06"""
    sesion, espacio = cancha

    r = api.post(
        "/reservas",
        headers=sesion,
        json={
            "espacio_id": espacio,
            "fecha": _manana().isoformat(),
            "desde": "18:30",
            "horas": 1,
        },
    )

    # Verifica: la rechaza por la hora y no guarda nada.
    assert r.status_code == 422
    assert r.json()["errores"]["desde"] == "Elegí una hora en punto"
    assert _reservas(motor, espacio) == 0


def test_el_backend_rechaza_una_reserva_de_menos_de_una_hora(
    api: TestClient, motor: Engine, cancha: tuple[dict[str, str], str]
) -> None:
    """el backend rechaza una reserva de menos de una hora @CU-09-H01-08"""
    sesion, espacio = cancha

    r = api.post(
        "/reservas",
        headers=sesion,
        json={
            "espacio_id": espacio,
            "fecha": _manana().isoformat(),
            "desde": "18:00",
            "horas": 0,
        },
    )

    # Verifica: la rechaza por la duración y no guarda nada.
    assert r.status_code == 422
    assert r.json()["errores"]["hasta"] == "La duración mínima es de una hora"
    assert _reservas(motor, espacio) == 0


def test_el_backend_rechaza_una_reserva_que_se_superpone_en_parte_con_otra_del_mismo_espacio(
    api: TestClient, motor: Engine, cancha: tuple[dict[str, str], str]
) -> None:
    """el backend rechaza una reserva que se superpone en parte con otra del mismo espacio @CU-09-H02-02"""
    sesion, espacio = cancha
    manana = _manana().isoformat()
    primera = api.post(
        "/reservas",
        headers=sesion,
        json={"espacio_id": espacio, "fecha": manana, "desde": "18:00", "horas": 2},
    )
    assert primera.status_code == 201

    r = api.post(
        "/reservas",
        headers=sesion,
        json={"espacio_id": espacio, "fecha": manana, "desde": "19:00", "horas": 2},
    )

    # Verifica: la segunda choca con la primera y sólo queda una.
    assert r.status_code == 409
    assert r.json()["errores"]["horario"] == "Ese horario se ocupó"
    assert _reservas(motor, espacio) == 1
