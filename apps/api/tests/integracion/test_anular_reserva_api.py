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


def _reservar(api: TestClient, token_usuario: str, espacio: int, dia: int = 1) -> dict[str, Any]:
    fecha = (date.today() + timedelta(days=dia)).isoformat()
    r = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={"espacio_id": espacio, "fecha": fecha, "desde": "18:00", "horas": 1},
    )
    assert r.status_code == 201
    reserva: dict[str, Any] = r.json()
    return reserva


def _pedido(reserva: dict[str, Any], motivo: str = MOTIVO) -> dict[str, Any]:
    return {"motivo": motivo, "espacio_id": reserva["espacio_id"], "inicio": reserva["inicio"]}


def test_anular_estampa_quien_cuando_y_por_que_libera_el_horario_y_se_puede_repetir(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    """anular estampa el rastro y repetir el pedido responde igual @supuesto:CU-15-SUP-07"""
    espacio = _espacio_nuevo(api, token_admin, sede[0])
    reserva = _reservar(api, token_usuario, espacio)

    r = api.post(
        f"/reservas/{reserva['id']}/anular",
        headers=_con(token_admin),
        json=_pedido(reserva, f"  {MOTIVO}  "),
    )
    otra_vez = api.post(
        f"/reservas/{reserva['id']}/anular", headers=_con(token_admin), json=_pedido(reserva)
    )
    distinto = api.post(
        f"/reservas/{reserva['id']}/anular",
        headers=_con(token_admin),
        json=_pedido(reserva, "otro motivo"),
    )

    assert r.status_code == 200
    assert (r.json()["estado"], r.json()["motivo"], r.json()["anulable"]) == (
        "anulada",
        MOTIVO,
        False,
    )
    assert r.json()["cancelada_por_nombre"] == "Ana Díaz"
    assert r.json()["cancelada_en"] is not None
    assert otra_vez.status_code == 200
    # El envío del aviso sale después de responder: lo único que cambia entre las dos.
    envio = {"aviso_envio", "aviso_en"}
    assert {k: v for k, v in otra_vez.json().items() if k not in envio} == {
        k: v for k, v in r.json().items() if k not in envio
    }
    assert distinto.status_code == 409
    with motor.connect() as conn:
        fila = conn.execute(
            text("SELECT estado, cancelada_por IS NOT NULL FROM reserva WHERE id = :id"),
            {"id": reserva["id"]},
        ).one()
    assert tuple(fila) == ("anulada", True)
    # El horario vuelve a estar libre y el usuario la ve anulada, con el motivo.
    fecha = (date.today() + timedelta(days=1)).isoformat()
    assert (
        api.post(
            "/reservas",
            headers=_con(token_usuario),
            json={"espacio_id": espacio, "fecha": fecha, "desde": "18:00", "horas": 1},
        ).status_code
        == 201
    )
    historial = api.get("/reservas?cuando=historial", headers=_con(token_usuario)).json()
    assert [(x["estado"], x["motivo"]) for x in historial["reservas"]] == [("anulada", MOTIVO)]


def test_anular_rechaza_lo_que_no_corresponde(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    """rechazos por motivo y por reserva cambiada @supuesto:CU-15-SUP-01 @supuesto:CU-15-SUP-05"""
    espacio = _espacio_nuevo(api, token_admin, sede[0])
    otro_espacio = _espacio_nuevo(api, token_admin, sede[0])
    reserva = _reservar(api, token_usuario, espacio)
    empezada = _reservar(api, token_usuario, espacio, dia=2)
    cancelada = _reservar(api, token_usuario, espacio, dia=3)
    assert (
        api.post(f"/reservas/{cancelada['id']}/cancelar", headers=_con(token_usuario)).status_code
        == 200
    )
    with motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE reserva SET inicio = date_trunc('hour', now()), fin ="
                " date_trunc('hour', now()) + interval '1 hour' WHERE id = :id"
            ),
            {"id": empezada["id"]},
        )

    def anular(id_: int, pedido: dict[str, Any], token: str = token_admin) -> int:
        return api.post(f"/reservas/{id_}/anular", headers=_con(token), json=pedido).status_code

    assert anular(reserva["id"], _pedido(reserva), token_usuario) == 403
    assert anular(reserva["id"] + 10**6, _pedido(reserva)) == 404
    assert anular(reserva["id"], _pedido(reserva, "")) == 422
    assert anular(reserva["id"], _pedido(reserva, "   ")) == 422
    assert anular(reserva["id"], _pedido(reserva, "x" * 501)) == 422
    assert anular(empezada["id"], _pedido(empezada)) == 409
    assert anular(cancelada["id"], _pedido(cancelada)) == 409
    # La reserva se vio en otra cancha o en otro horario: cambió mientras tanto.
    assert anular(reserva["id"], _pedido(reserva) | {"espacio_id": otro_espacio}) == 409
    assert anular(reserva["id"], _pedido(empezada)) == 409
    assert api.post(f"/reservas/{reserva['id']}/anular", json=_pedido(reserva)).status_code == 401
    with motor.connect() as conn:
        estado = conn.execute(
            text("SELECT estado FROM reserva WHERE id = :id"), {"id": reserva["id"]}
        ).scalar_one()
    assert estado == "activa"


def test_el_listado_ofrece_anular_solo_lo_activo_que_no_empezo(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    espacio = _espacio_nuevo(api, token_admin, sede[0])
    reserva = _reservar(api, token_usuario, espacio)
    api.post(f"/reservas/{reserva['id']}/anular", headers=_con(token_admin), json=_pedido(reserva))
    futura = _reservar(api, token_usuario, espacio, dia=2)

    lista = api.get("/reservas/todas?q=" + sede[1], headers=_con(token_admin)).json()

    por_id = {x["id"]: x["anulable"] for x in lista["reservas"]}
    assert por_id[futura["id"]] is True
    assert por_id[reserva["id"]] is False


def test_anular_y_cancelar_a_la_vez_dejan_una_sola_y_sin_trabarse(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    espacio = _espacio_nuevo(api, token_admin, sede[0])
    for dia in range(1, 6):
        reserva = _reservar(api, token_usuario, espacio, dia=dia)
        barrera = Barrier(2)

        def anular(reserva: dict[str, Any] = reserva, barrera: Barrier = barrera) -> int:
            barrera.wait()
            return api.post(
                f"/reservas/{reserva['id']}/anular",
                headers=_con(token_admin),
                json=_pedido(reserva),
            ).status_code

        def cancelar(reserva: dict[str, Any] = reserva, barrera: Barrier = barrera) -> int:
            barrera.wait()
            return api.post(
                f"/reservas/{reserva['id']}/cancelar", headers=_con(token_usuario)
            ).status_code

        with ThreadPoolExecutor(2) as hilos:
            a, c = (f.result() for f in (hilos.submit(anular), hilos.submit(cancelar)))
        with motor.connect() as conn:
            estado = conn.execute(
                text("SELECT estado FROM reserva WHERE id = :id"), {"id": reserva["id"]}
            ).scalar_one()
        assert (a, c, estado) in {(200, 409, "anulada"), (409, 200, "cancelada")}
