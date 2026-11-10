"""`POST /reservas/{id}/anular` contra la base y el emulador reales."""

from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta
from threading import Barrier
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

MOTIVO = "mantenimiento de la cancha"


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


def _reservar(api: TestClient, user_token: str, espacio: str, dia: int = 1) -> dict[str, Any]:
    fecha = (date.today() + timedelta(days=dia)).isoformat()
    r = api.post(
        "/bookings",
        headers=_con(user_token),
        json={"space_id": espacio, "date": fecha, "start_hour": "18:00", "hours": 1},
    )
    assert r.status_code == 201
    reserva: dict[str, Any] = r.json()
    return reserva


def _pedido(reserva: dict[str, Any], motivo: str = MOTIVO) -> dict[str, Any]:
    return {"reason": motivo, "space_id": reserva["space_id"], "starts_at": reserva["starts_at"]}


def test_anular_estampa_quien_cuando_y_por_que_libera_el_horario_y_se_puede_repetir(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """anular estampa el rastro y repetir el pedido responde igual @supuesto:CU-15-SUP-07"""
    espacio = _espacio_nuevo(api, admin_token, venue[0])
    reserva = _reservar(api, user_token, espacio)

    r = api.post(
        f"/bookings/{reserva['id']}/void",
        headers=_con(admin_token),
        json=_pedido(reserva, f"  {MOTIVO}  "),
    )
    otra_vez = api.post(
        f"/bookings/{reserva['id']}/void", headers=_con(admin_token), json=_pedido(reserva)
    )
    distinto = api.post(
        f"/bookings/{reserva['id']}/void",
        headers=_con(admin_token),
        json=_pedido(reserva, "otro motivo"),
    )

    assert r.status_code == 200
    assert (r.json()["status"], r.json()["reason"], r.json()["voidable"]) == (
        "voided",
        MOTIVO,
        False,
    )
    assert r.json()["canceled_by_name"] == "Ana Díaz"
    assert r.json()["canceled_at"] is not None
    assert otra_vez.status_code == 200
    # El envío del aviso sale después de responder: lo único que cambia entre las dos.
    envio = {"notice_delivery", "notice_at"}
    assert {k: v for k, v in otra_vez.json().items() if k not in envio} == {
        k: v for k, v in r.json().items() if k not in envio
    }
    assert distinto.status_code == 409
    with engine.connect() as conn:
        fila = conn.execute(
            text("SELECT status, canceled_by IS NOT NULL FROM booking WHERE id = :id"),
            {"id": reserva["id"]},
        ).one()
    assert tuple(fila) == ("voided", True)
    # El horario vuelve a estar libre y el usuario la ve anulada, con el motivo.
    fecha = (date.today() + timedelta(days=1)).isoformat()
    assert (
        api.post(
            "/bookings",
            headers=_con(user_token),
            json={"space_id": espacio, "date": fecha, "start_hour": "18:00", "hours": 1},
        ).status_code
        == 201
    )
    historial = api.get("/bookings?when=history", headers=_con(user_token)).json()
    assert [(x["status"], x["reason"]) for x in historial["bookings"]] == [("voided", MOTIVO)]


def test_anular_rechaza_lo_que_no_corresponde(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """rechazos por motivo y por reserva cambiada @supuesto:CU-15-SUP-01 @supuesto:CU-15-SUP-05"""
    espacio = _espacio_nuevo(api, admin_token, venue[0])
    otro_espacio = _espacio_nuevo(api, admin_token, venue[0])
    reserva = _reservar(api, user_token, espacio)
    empezada = _reservar(api, user_token, espacio, dia=2)
    cancelada = _reservar(api, user_token, espacio, dia=3)
    assert (
        api.post(f"/bookings/{cancelada['id']}/cancel", headers=_con(user_token)).status_code
        == 200
    )
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE booking SET starts_at = date_trunc('hour', now()), ends_at ="
                " date_trunc('hour', now()) + interval '1 hour' WHERE id = :id"
            ),
            {"id": empezada["id"]},
        )

    def anular(id_: str, pedido: dict[str, Any], token: str = admin_token) -> int:
        return api.post(f"/bookings/{id_}/void", headers=_con(token), json=pedido).status_code

    assert anular(reserva["id"], _pedido(reserva), user_token) == 403
    assert anular("00000000-0000-7000-8000-000000000000", _pedido(reserva)) == 404
    assert anular(reserva["id"], _pedido(reserva, "")) == 422
    assert anular(reserva["id"], _pedido(reserva, "   ")) == 422
    assert anular(reserva["id"], _pedido(reserva, "x" * 501)) == 422
    assert anular(empezada["id"], _pedido(empezada)) == 409
    assert anular(cancelada["id"], _pedido(cancelada)) == 409
    # La reserva se vio en otra cancha o en otro horario: cambió mientras tanto.
    assert anular(reserva["id"], _pedido(reserva) | {"space_id": otro_espacio}) == 409
    assert anular(reserva["id"], _pedido(empezada)) == 409
    assert api.post(f"/bookings/{reserva['id']}/void", json=_pedido(reserva)).status_code == 401
    with engine.connect() as conn:
        estado: Any = conn.execute(
            text("SELECT status FROM booking WHERE id = :id"), {"id": reserva["id"]}
        ).scalar_one()
    assert estado == "active"


def test_el_listado_ofrece_anular_solo_lo_activo_que_no_empezo(
    api: TestClient, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    espacio = _espacio_nuevo(api, admin_token, venue[0])
    reserva = _reservar(api, user_token, espacio)
    api.post(f"/bookings/{reserva['id']}/void", headers=_con(admin_token), json=_pedido(reserva))
    futura = _reservar(api, user_token, espacio, dia=2)

    lista = api.get("/bookings/all?q=" + venue[1], headers=_con(admin_token)).json()

    por_id = {x["id"]: x["voidable"] for x in lista["bookings"]}
    assert por_id[futura["id"]] is True
    assert por_id[reserva["id"]] is False


def test_anular_y_cancelar_a_la_vez_dejan_una_sola_y_sin_trabarse(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    espacio = _espacio_nuevo(api, admin_token, venue[0])
    for dia in range(1, 6):
        reserva = _reservar(api, user_token, espacio, dia=dia)
        barrera = Barrier(2)

        def anular(reserva: dict[str, Any] = reserva, barrera: Barrier = barrera) -> int:
            barrera.wait()
            return api.post(
                f"/bookings/{reserva['id']}/void",
                headers=_con(admin_token),
                json=_pedido(reserva),
            ).status_code

        def cancelar(reserva: dict[str, Any] = reserva, barrera: Barrier = barrera) -> int:
            barrera.wait()
            return api.post(
                f"/bookings/{reserva['id']}/cancel", headers=_con(user_token)
            ).status_code

        with ThreadPoolExecutor(2) as hilos:
            a, c = (f.result() for f in (hilos.submit(anular), hilos.submit(cancelar)))
        with engine.connect() as conn:
            estado: Any = conn.execute(
                text("SELECT status FROM booking WHERE id = :id"), {"id": reserva["id"]}
            ).scalar_one()
        assert (a, c, estado) in {(200, 409, "voided"), (409, 200, "canceled")}


def test_una_reserva_ya_empezada_se_rechaza_aunque_se_mande_su_horario_vigente(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> None:
    """anular lo que ya empezó se rechaza por empezada, no por un horario desactualizado"""
    espacio = _espacio_nuevo(api, admin_token, venue[0])
    empezada = _reservar(api, user_token, espacio)
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE booking SET starts_at = date_trunc('hour', now()), ends_at ="
                " date_trunc('hour', now()) + interval '1 hour' WHERE id = :id"
            ),
            {"id": empezada["id"]},
        )
    vigente = api.get(f"/bookings/all/{empezada['id']}", headers=_con(admin_token)).json()
    assert vigente["voidable"] is False

    r = api.post(
        f"/bookings/{empezada['id']}/void",
        headers=_con(admin_token),
        json=_pedido(vigente),
    )

    assert r.status_code == 409
    with engine.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT status, starts_at <= now() AS empezo,"
                " starts_at = CAST(:starts_at AS timestamptz) AS coincide"
                " FROM booking WHERE id = :id"
            ),
            {"id": empezada["id"], "starts_at": vigente["starts_at"]},
        ).one()
    assert (fila.status, fila.empezo, fila.coincide) == ("active", True, True)
