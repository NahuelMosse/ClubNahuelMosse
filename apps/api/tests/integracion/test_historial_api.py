"""`GET /reservas/todas`: los cortes de fecha y la búsqueda contra la base y el emulador reales."""

from datetime import date, timedelta
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _espacio_nuevo(api: TestClient, token_admin: str, sede_id: int) -> int:
    r = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede_id,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    )
    return int(r.json()["id"])


def _reservar(api: TestClient, token_usuario: str, espacio: int, dia: int) -> dict[str, Any]:
    fecha = (date.today() + timedelta(days=dia)).isoformat()
    r = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={"espacio_id": espacio, "fecha": fecha, "desde": "18:00", "horas": 1},
    )
    assert r.status_code == 201
    reserva: dict[str, Any] = r.json()
    return reserva


def _mover_a(motor: Engine, id_: int, dia: str, hora: int) -> None:
    """Deja la reserva en [dia] a las [hora] del club."""
    with motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE reserva SET inicio = x.inicio, fin = x.inicio + interval '1 hour'"
                " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :hora))"
                "       AT TIME ZONE 'America/Argentina/Buenos_Aires' AS inicio) x"
                " WHERE id = :id"
            ),
            {"id": id_, "dia": dia, "hora": hora},
        )


def _ids(api: TestClient, token: str, consulta: str) -> set[int]:
    r = api.get(f"/reservas/todas?{consulta}", headers=_con(token))
    assert r.status_code == 200
    cuerpo: dict[str, Any] = r.json()
    return {x["id"] for x in cuerpo["reservas"]}


def test_los_dias_del_filtro_se_cortan_en_la_hora_del_club(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """a las 21:00 y a las 23:00 del club la reserva cae en su día, no en el siguiente en UTC"""
    espacio = _espacio_nuevo(api, token_admin, sede[0])
    a_las_21 = _reservar(api, token_usuario, espacio, dia=1)["id"]
    a_las_23 = _reservar(api, token_usuario, espacio, dia=2)["id"]
    _mover_a(motor, a_las_21, "2031-09-10", 21)
    _mover_a(motor, a_las_23, "2031-09-10", 23)
    base = f"q={sede[1]}"

    assert _ids(api, token_admin, f"{base}&desde=2031-09-10&hasta=2031-09-10") == {
        a_las_21,
        a_las_23,
    }
    assert _ids(api, token_admin, f"{base}&desde=2031-09-11&hasta=2031-09-11") == set()
    assert _ids(api, token_admin, f"{base}&desde=2031-09-09&hasta=2031-09-09") == set()
    assert _ids(api, token_admin, f"{base}&hasta=2031-09-10") == {a_las_21, a_las_23}


def test_la_busqueda_toma_los_comodines_como_texto(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """% y _ no son comodines en la búsqueda @supuesto:CU-14-SUP-02"""
    espacio = _espacio_nuevo(api, token_admin, sede[0])
    reserva = _reservar(api, token_usuario, espacio, dia=1)["id"]
    nombre = sede[1]

    assert reserva in _ids(api, token_admin, f"q={nombre}")
    assert _ids(api, token_admin, "q=%25") == set()
    assert _ids(api, token_admin, f"q={nombre[:5]}%25") == set()
    assert _ids(api, token_admin, f"q={nombre[:4]}_{nombre[5:]}") == set()
    assert _ids(api, token_admin, "q=%5C") == set()


