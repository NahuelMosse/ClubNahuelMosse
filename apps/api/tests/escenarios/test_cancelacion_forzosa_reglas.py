from collections.abc import Callable
from uuid import UUID

import test_cancelacion_forzosa as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_recordatorio import CanalDePrueba, un_socio

admin = base.admin
canal = base.canal


def test_un_aviso_que_esta_saliendo_se_agrupa_con_la_anulacion_siguiente(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """el aviso en curso sale igual y la anulación siguiente abre uno con la cantidad total, que es
    el único del centro @supuesto:CU-24.2-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    primera = socio.reservar("20:00")
    segunda = socio.reservar("21:00")
    assert base.anular(socio, admin, primera) == 200
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE notification SET delivery = 'sending' WHERE user_id = :u"),
            {"u": socio.usuario_id},
        )

    assert base.anular(socio, admin, segunda) == 200

    centro = socio.centro()
    assert centro["no_leidas"] == 1
    assert [e["titulo"] for e in centro["notificaciones"]] == ["El club anuló 2 de tus reservas"]


def test_el_motivo_largo_se_recorta_en_el_aviso_y_el_historial_lo_conserva(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """el motivo del aviso tiene 200 caracteres como máximo @supuesto:CU-24.2-SUP-06"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    motivo = "x" * 300

    assert base.anular(socio, admin, reserva, motivo) == 200

    [(_, aviso)] = canal.enviados
    assert aviso.body.endswith(f"Motivo: {'x' * 199}….")
    historial = socio.api.get("/reservas?cuando=historial", headers=socio.sesion).json()
    assert [r["motivo"] for r in historial["reservas"]] == [motivo]


def test_una_reserva_con_aviso_no_lo_repite_si_se_encola_de_nuevo(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    admin: dict[str, str],
) -> None:
    """encolar dos veces la misma reserva deja un solo aviso @supuesto:CU-24.2-SUP-08"""
    from app.modules.notifications.repository import enqueue_forced_cancellation

    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    assert base.anular(socio, admin, reserva) == 200

    with motor.begin() as conn:
        enqueue_forced_cancellation(conn, socio.usuario_id, [UUID(reserva["id"])])

    assert len(socio.centro()["notificaciones"]) == 1
