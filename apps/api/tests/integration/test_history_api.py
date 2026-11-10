"""`GET /reservas/todas`: los cortes de fecha y la búsqueda contra la base y el emulador reales."""

from datetime import date, timedelta
from typing import Any
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _espacio_nuevo(api: TestClient, admin_token: str, sede_id: str) -> str:
    r = api.post(
        "/spaces",
        headers=_con(admin_token),
        json={
            "venue_id": sede_id,
            "sport": "Futbol",
            "kind": "F5",
            "covered": False,
            "lit": True,
            "price_per_hour": 38000,
        },
    )
    return str(r.json()["id"])


def _reservar(api: TestClient, user_token: str, espacio: str, dia: int) -> dict[str, Any]:
    fecha = (date.today() + timedelta(days=dia)).isoformat()
    r = api.post(
        "/bookings",
        headers=_con(user_token),
        json={"space_id": espacio, "date": fecha, "start_hour": "18:00", "hours": 1},
    )
    assert r.status_code == 201
    reserva: dict[str, Any] = r.json()
    return reserva


def _mover_a(engine: Engine, id_: UUID, dia: str, hora: int) -> None:
    """Deja la reserva en [dia] a las [hora] del club."""
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE booking"
                " SET starts_at = x.starts_at, ends_at = x.starts_at + interval '1 hour'"
                " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :hora))"
                "       AT TIME ZONE 'America/Argentina/Buenos_Aires' AS starts_at) x"
                " WHERE id = :id"
            ),
            {"id": id_, "dia": dia, "hora": hora},
        )


def _ids(api: TestClient, token: str, consulta: str) -> set[str]:
    r = api.get(f"/bookings/all?{consulta}", headers=_con(token))
    assert r.status_code == 200
    cuerpo: dict[str, Any] = r.json()
    return {x["id"] for x in cuerpo["bookings"]}


def test_los_dias_del_filtro_se_cortan_en_la_hora_del_club(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """a las 21:00 y a las 23:00 del club la reserva cae en su día, no en el siguiente en UTC"""
    espacio = _espacio_nuevo(api, admin_token, venue[0])
    a_las_21 = _reservar(api, user_token, espacio, dia=1)["id"]
    a_las_23 = _reservar(api, user_token, espacio, dia=2)["id"]
    _mover_a(engine, UUID(a_las_21), "2031-09-10", 21)
    _mover_a(engine, UUID(a_las_23), "2031-09-10", 23)
    base = f"q={venue[1]}"

    assert _ids(api, admin_token, f"{base}&since=2031-09-10&until=2031-09-10") == {
        a_las_21,
        a_las_23,
    }
    assert _ids(api, admin_token, f"{base}&since=2031-09-11&until=2031-09-11") == set()
    assert _ids(api, admin_token, f"{base}&since=2031-09-09&until=2031-09-09") == set()
    assert _ids(api, admin_token, f"{base}&until=2031-09-10") == {a_las_21, a_las_23}


def test_la_busqueda_toma_los_comodines_como_texto(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """% y _ no son comodines en la búsqueda @supuesto:CU-14-SUP-02"""
    espacio = _espacio_nuevo(api, admin_token, venue[0])
    reserva = _reservar(api, user_token, espacio, dia=1)["id"]
    nombre = venue[1]

    assert reserva in _ids(api, admin_token, f"q={nombre}")
    assert _ids(api, admin_token, "q=%25") == set()
    assert _ids(api, admin_token, f"q={nombre[:5]}%25") == set()
    assert _ids(api, admin_token, f"q={nombre[:4]}_{nombre[5:]}") == set()
    assert _ids(api, admin_token, "q=%5C") == set()
