from collections.abc import Callable
from uuid import UUID

import test_forced_cancellation as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, a_member

admin = base.admin
channel = base.channel


def test_un_aviso_que_esta_saliendo_se_agrupa_con_la_anulacion_siguiente(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """el aviso en curso sale igual y la anulación siguiente abre uno con la cantidad total, que es
    el único del centro @supuesto:CU-24.2-SUP-02"""
    socio = a_member(api, engine, sign_in, unique)
    primera = socio.book("20:00")
    segunda = socio.book("21:00")
    assert base.force_cancel(socio, admin, primera) == 200
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE notification SET delivery = 'sending' WHERE user_id = :u"),
            {"u": socio.user_id},
        )

    assert base.force_cancel(socio, admin, segunda) == 200

    center = socio.center()
    assert center["unread"] == 1
    assert [e["title"] for e in center["notifications"]] == ["The club voided 2 of your bookings"]


def test_el_motivo_largo_se_recorta_en_el_aviso_y_el_historial_lo_conserva(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """el motivo del aviso tiene 200 caracteres como máximo @supuesto:CU-24.2-SUP-06"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    motivo = "x" * 300

    assert base.force_cancel(socio, admin, reserva, motivo) == 200

    [(_, aviso)] = channel.sent
    assert aviso.body.endswith(f"Reason: {'x' * 199}….")
    historial = socio.api.get("/bookings?when=history", headers=socio.session).json()
    assert [r["reason"] for r in historial["bookings"]] == [motivo]


def test_una_reserva_con_aviso_no_lo_repite_si_se_encola_de_nuevo(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """encolar dos veces la misma reserva deja un solo aviso @supuesto:CU-24.2-SUP-08"""
    from app.modules.notifications.repository import enqueue_forced_cancellation

    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    assert base.force_cancel(socio, admin, reserva) == 200

    with engine.begin() as conn:
        enqueue_forced_cancellation(conn, socio.user_id, [UUID(reserva["id"])])

    assert len(socio.center()["notifications"]) == 1
