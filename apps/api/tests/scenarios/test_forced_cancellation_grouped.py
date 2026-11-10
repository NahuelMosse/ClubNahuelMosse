"""El agrupado de avisos de anulación: trazabilidad por reserva, id nuevo y concurrencia."""

import threading
import time
from collections.abc import Callable, Sequence
from typing import Any
from uuid import UUID

import pytest
import test_forced_cancellation as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, a_member

from app.modules.notifications.repository import NotificationsSql, enqueue_forced_cancellation

admin = base.admin
channel = base.channel


def _anular_en_la_base(engine: Engine, socio: Member, reservas: Sequence[dict[str, Any]]) -> None:
    with engine.begin() as conn:
        for r in reservas:
            conn.execute(
                text(
                    "UPDATE booking SET status = 'voided', reason = 'Baja de la sede',"
                    " canceled_at = now(), canceled_by = :u WHERE id = :id"
                ),
                {"u": socio.user_id, "id": r["id"]},
            )


def _avisos(engine: Engine, socio: Member) -> list[Any]:
    with engine.connect() as conn:
        return list(
            conn.execute(
                text(
                    "SELECT id, title, count, replaced_by, delivery, sent_at"
                    " FROM notification WHERE user_id = :u ORDER BY id"
                ),
                {"u": socio.user_id},
            )
        )


def _en_paralelo(engine: Engine, user_id: UUID, lotes: Sequence[Sequence[UUID]]) -> None:
    """Encola el primer lote y, con su transacción todavía abierta, el segundo, que tiene que
    quedar esperando a que la primera termine."""
    primera_dentro, soltar = threading.Event(), threading.Event()
    errores: list[BaseException] = []

    def primera() -> None:
        try:
            with engine.begin() as conn:
                enqueue_forced_cancellation(conn, user_id, lotes[0])
                primera_dentro.set()
                soltar.wait(10)
        except BaseException as e:
            errores.append(e)
            primera_dentro.set()

    def segunda() -> None:
        try:
            primera_dentro.wait(10)
            with engine.begin() as conn:
                enqueue_forced_cancellation(conn, user_id, lotes[1])
        except BaseException as e:
            errores.append(e)

    hilos = [threading.Thread(target=primera), threading.Thread(target=segunda)]
    for h in hilos:
        h.start()
    primera_dentro.wait(10)
    time.sleep(0.5)
    esperando = hilos[1].is_alive()
    soltar.set()
    for h in hilos:
        h.join(10)
    assert errores == []
    assert esperando, "la segunda anulación no esperó a la primera"


def test_agrupar_abre_un_aviso_nuevo_y_cada_reserva_conserva_el_envio_del_suyo(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """el aviso agrupado tiene id nuevo y la trazabilidad de cada reserva no cambia @supuesto:CU-24.2-SUP-02"""
    socio = a_member(api, engine, sign_in, unique)
    primera = socio.book("20:00")
    segunda = socio.book("21:00")
    assert base.force_cancel(socio, admin, primera) == 200
    [antes] = socio.center()["notifications"]
    trazabilidad = base.for_admin(socio, admin, primera["id"])

    assert base.force_cancel(socio, admin, segunda) == 200

    [despues] = socio.center()["notifications"]
    assert despues["id"] != antes["id"]
    assert despues["title"] == "The club voided 2 of your bookings"
    assert base.for_admin(socio, admin, primera["id"])["notice_at"] == trazabilidad["notice_at"]
    assert base.for_admin(socio, admin, segunda["id"])["notice_delivery"] == "sent"
    anterior, nuevo = _avisos(engine, socio)
    assert anterior.replaced_by == nuevo.id
    assert anterior.sent_at < nuevo.sent_at


def test_un_aviso_que_no_salio_pasa_sus_reservas_al_que_lo_reemplaza(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
) -> None:
    """lo que se agrupa antes de salir se informa en el aviso que sale @supuesto:CU-24.2-SUP-02"""
    socio = a_member(api, engine, sign_in, unique)
    reservas = [socio.book("20:00"), socio.book("21:00")]
    _anular_en_la_base(engine, socio, reservas)
    with engine.begin() as conn:
        enqueue_forced_cancellation(conn, socio.user_id, [UUID(reservas[0]["id"])])
    with engine.begin() as conn:
        enqueue_forced_cancellation(conn, socio.user_id, [UUID(reservas[1]["id"])])

    with engine.connect() as conn:
        vinculos = conn.execute(
            text("SELECT notification_id FROM notification_booking WHERE booking_id = ANY(:ids)"),
            {"ids": [UUID(r["id"]) for r in reservas]},
        ).all()
    *_, nuevo = _avisos(engine, socio)
    assert {v.notification_id for v in vinculos} == {nuevo.id}


@pytest.mark.parametrize("con_aviso_previo", [False, True])
def test_dos_anulaciones_simultaneas_dejan_la_cantidad_y_un_solo_aviso_visible(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
    con_aviso_previo: bool,
) -> None:
    """las anulaciones de una misma persona se serializan @supuesto:CU-24.2-SUP-02"""
    socio = a_member(api, engine, sign_in, unique)
    reservas = [socio.book("20:00"), socio.book("21:00"), socio.book("22:00")]
    if con_aviso_previo:
        assert base.force_cancel(socio, admin, reservas[0]) == 200
        simultaneas = reservas[1:]
    else:
        simultaneas = reservas[:2]
        _anular_en_la_base(engine, socio, simultaneas)
    total = len(simultaneas) + int(con_aviso_previo)
    if con_aviso_previo:
        _anular_en_la_base(engine, socio, simultaneas)

    _en_paralelo(
        engine, socio.user_id, [[UUID(simultaneas[0]["id"])], [UUID(simultaneas[1]["id"])]]
    )

    [visible] = socio.center()["notifications"]
    assert visible["title"] == f"The club voided {total} of your bookings"
    sin_reemplazar = [a for a in _avisos(engine, socio) if a.replaced_by is None]
    assert [a.count for a in sin_reemplazar] == [total]
    with engine.connect() as conn:
        vinculadas: Any = conn.execute(
            text(
                "SELECT count(*) FROM notification_booking nr JOIN notification n"
                " ON n.id = nr.notification_id WHERE n.user_id = :u"
            ),
            {"u": socio.user_id},
        ).scalar_one()
    assert vinculadas == total


def test_un_aviso_leido_mientras_se_agrupa_no_se_traga_la_anulacion_nueva(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    channel: FakeChannel,
    admin: dict[str, str],
) -> None:
    """leer el aviso anterior en medio del agrupado deja el nuevo sin leer @supuesto:CU-24.2-SUP-02"""
    socio = a_member(api, engine, sign_in, unique)
    primera = socio.book("20:00")
    segunda = socio.book("21:00")
    assert base.force_cancel(socio, admin, primera) == 200
    [leido] = socio.center()["notifications"]
    _anular_en_la_base(engine, socio, [segunda])

    def leyendo() -> None:
        with engine.connect() as conn:
            NotificationsSql(conn).read(socio.user_id, UUID(leido["id"]))

    lectura = threading.Thread(target=leyendo)

    primera_dentro, soltar = threading.Event(), threading.Event()

    def encolando() -> None:
        with engine.begin() as conn:
            enqueue_forced_cancellation(conn, socio.user_id, [UUID(segunda["id"])])
            primera_dentro.set()
            soltar.wait(10)

    hilo = threading.Thread(target=encolando)
    hilo.start()
    primera_dentro.wait(10)
    lectura.start()
    time.sleep(0.5)
    soltar.set()
    hilo.join(10)
    lectura.join(10)

    center = socio.center()
    assert center["unread"] == 1
    [entrada] = center["notifications"]
    assert entrada["title"] == "The club voided 2 of your bookings"
    assert entrada["read"] is False


def test_el_despacho_toma_los_pendientes_por_un_indice_parcial(engine: Engine) -> None:
    """la consulta del despacho tiene su índice"""
    with engine.connect() as conn:
        definicion: Any = conn.execute(
            text("SELECT indexdef FROM pg_indexes WHERE indexname = 'notification_to_dispatch'")
        ).scalar_one()
    assert "delivery = 'pending'" in definicion
    assert "kind <> 'reminder'" in definicion
