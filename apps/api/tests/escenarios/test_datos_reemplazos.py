"""Datos: reemplazos de cuatro tests de test_datos_tandas_y_cola.py.

Los helpers y los fixtures son los de test_datos.py.
"""

from fastapi.testclient import TestClient
from sqlalchemy import text
from test_datos import (  # noqa: F401 — los fixtures se importan para que pytest los vea
    _barrer,
    _cancelar,
    _despachar,
    _empate,
    _envios,
    _pasadas,
    _recordatorio,
    canal,
    socio,
    token_admin,
)
from test_recordatorio import CanalDePrueba, Socio


def test_con_el_mismo_inicio_el_historial_global_pone_primero_el_id_mas_alto(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """con el mismo inicio va primero el id más alto @REV-03-S3 @assumption:REV-03-ASM-07"""
    _pasadas(socio, 20)
    _empate(socio)
    admin = {"Authorization": f"Bearer {token_admin}"}

    primera = api.get("/reservas/todas", headers=admin, params={"q": socio.sede}).json()
    segunda = api.get(
        "/reservas/todas",
        headers=admin,
        params={"q": socio.sede, "despues": primera["siguiente"]},
    ).json()

    claves = [(x["inicio"], x["id"]) for x in primera["reservas"] + segunda["reservas"]]
    assert len(claves) == 21
    assert claves == sorted(claves, reverse=True)
    assert len({inicio for inicio, _ in claves}) == 20


def test_de_cada_intento_quedan_tomada_en_e_intentos_y_el_error_va_al_log(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """de cada intento quedan tomada_en e intentos y el error va al log, no a la base
    @REV-03-S5 @assumption:REV-03-ASM-09
    """
    _cancelar(socio, "20:00")
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET envio = 'pendiente', enviada_en = NULL,"
                " tomada_en = NULL, intentos = 0 WHERE usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        )

    _despachar(socio, canal)

    with socio.motor.connect() as conn:
        [(tomada_en, intentos)] = conn.execute(
            text("SELECT tomada_en, intentos FROM notificacion WHERE usuario_id = :u"),
            {"u": socio.usuario_id},
        ).all()
        columnas = {
            str(f.column_name)
            for f in conn.execute(
                text(
                    "SELECT column_name FROM information_schema.columns"
                    " WHERE table_name = 'notificacion'"
                )
            )
        }
    assert tomada_en is not None
    assert intentos == 1
    assert not {c for c in columnas if "error" in c}


def test_el_recordatorio_de_una_reserva_que_ya_empezo_no_se_reintenta(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """el recordatorio de una reserva que ya empezó no se reintenta y queda fallido
    @REV-03-S6 @assumption:REV-03-ASM-14
    """
    _recordatorio(socio, "pendiente", "10 minutes")
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE reserva SET"
                " inicio = date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
                " - interval '1 hour',"
                " fin = date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
                " + interval '1 hour', total = precio_por_hora * 2 WHERE id = :r"
            ),
            {"r": socio.reservas[-1]["id"]},
        )
        conn.execute(
            text(
                "UPDATE notificacion SET reserva_inicio = r.inicio FROM reserva r"
                " WHERE r.id = notificacion.reserva_id AND notificacion.usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        )
    canal.enviados.clear()

    _barrer(socio, canal)

    assert _envios(socio) == ["fallida"]
    assert canal.enviados == []


def test_la_trazabilidad_del_admin_muestra_el_aviso_fallido_como_fallido(
    api: TestClient, socio: Socio, token_admin: str, canal: CanalDePrueba
) -> None:
    """la trazabilidad del admin muestra el aviso fallido como fallido, no como pendiente
    @REV-03-S5 @assumption:REV-03-ASM-17
    """
    reserva = socio.reservar("20:00")
    admin = {"Authorization": f"Bearer {token_admin}"}
    anulada = api.post(
        f"/reservas/{reserva['id']}/anular",
        headers=admin,
        json={
            "motivo": "mantenimiento de la cancha",
            "espacio_id": reserva["espacio_id"],
            "inicio": reserva["inicio"],
        },
    )
    assert anulada.status_code == 200
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET envio = 'enviando', enviada_en = NULL,"
                " tomada_en = now() - interval '10 minutes', intentos = 3"
                " WHERE usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        )
    _despachar(socio, canal)

    r = api.get("/reservas/todas", headers=admin, params={"q": socio.sede}).json()["reservas"]

    assert [x["aviso_envio"] for x in r if x["id"] == reserva["id"]] == ["fallida"]
