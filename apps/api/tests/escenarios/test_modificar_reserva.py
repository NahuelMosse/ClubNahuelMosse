from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")


def test_el_backend_rechaza_un_horario_nuevo_en_el_pasado_o_que_termina_despues_del_cierre(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """el backend rechaza un horario nuevo en el pasado o que termina después del cierre @CU-11-H01-03"""
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
    sesion = {"Authorization": f"Bearer {token}"}
    manana = datetime.now(ZONA).date() + timedelta(days=1)
    reserva = api.post(
        "/reservas",
        headers=sesion,
        json={"espacio_id": str(espacio), "fecha": manana.isoformat(), "desde": "21:00", "horas": 1},
    ).json()

    ayer = api.post(
        f"/reservas/{reserva['id']}/modificar",
        headers=sesion,
        json={
            "espacio_id": str(espacio),
            "fecha": (manana - timedelta(days=2)).isoformat(),
            "desde": "10:00",
        },
    )
    tarde = api.post(
        f"/reservas/{reserva['id']}/modificar",
        headers=sesion,
        json={"espacio_id": str(espacio), "fecha": manana.isoformat(), "desde": "23:00"},
    )

    # Verifica: los dos cambios se rechazan por su regla.
    assert ayer.status_code == 422
    assert ayer.json()["errores"]["fecha"] == "La fecha tiene que ser futura"
    assert tarde.status_code == 422
    assert tarde.json()["errores"]["hasta"] == "La sede cierra a las 23:00"
    # Verifica: la reserva sigue en su horario.
    with motor.connect() as conn:
        inicio: Any = conn.execute(
            text("SELECT inicio FROM reserva WHERE id = :id"), {"id": reserva["id"]}
        ).scalar_one()
    assert inicio.astimezone(ZONA).hour == 21
