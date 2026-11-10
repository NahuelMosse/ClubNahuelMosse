from collections.abc import Callable, Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, app_of, tomorrow, a_member

from app.modules.notifications.push import push_channel

DIAS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


@pytest.fixture
def canal(api: TestClient) -> Iterator[FakeChannel]:
    """El servicio de notificaciones del teléfono, que anota lo que la API le pide enviar."""
    canal = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: canal
    yield canal
    app_of(api).dependency_overrides.pop(push_channel, None)


def cancelar(socio: Member, reserva_id: str) -> int:
    return socio.api.post(f"/bookings/{reserva_id}/cancel", headers=socio.session).status_code


def cuerpo_esperado(venue: str, hora: str) -> str:
    dia = tomorrow()
    return (
        f"Football 5 · {venue} · {DIAS[dia.weekday()]} {dia.day}, {hora}. The slot was freed."
    )


def test_al_cancelar_una_reserva_se_envia_la_confirmacion_con_la_reserva_y_el_horario_liberado(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """cancela una reserva y recibe la confirmación con la reserva y el horario liberado @CU-24.3-H01-01"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")

    # Verifica: nada sale antes de cancelar.
    assert canal.sent == []

    assert cancelar(socio, reserva["id"]) == 200

    # Verifica: sale una sola confirmación, al dispositivo del socio, con lo que dice el CU.
    assert len(canal.sent) == 1
    tokens, aviso = canal.sent[0]
    assert tokens == [socio.device]
    assert aviso.title == "Booking cancelled"
    assert aviso.body == cuerpo_esperado(socio.venue, "21:00")
    assert aviso.data["booking_id"] == str(reserva["id"])
    assert aviso.data["kind"] == "user_cancellation"


def test_al_tocar_la_confirmacion_la_app_sabe_que_reserva_abrir(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """al tocar la confirmación la app abre el historial con la reserva cancelada @CU-24.3-H01-02"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    assert cancelar(socio, reserva["id"]) == 200

    # Verifica: el push y el centro llevan el número de la reserva, que el historial lista
    # como cancelada.
    [(_, aviso)] = canal.sent
    assert aviso.data["booking_id"] == str(reserva["id"])
    [entrada] = socio.center()["notifications"]
    assert entrada["booking_id"] == reserva["id"]
    historial = socio.api.get("/bookings?when=history", headers=socio.session).json()
    assert [(r["id"], r["status"]) for r in historial["bookings"]] == [(reserva["id"], "canceled")]


def test_la_confirmacion_queda_en_el_centro_de_notificaciones(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """la confirmación queda en el centro de notificaciones @CU-24.3-H01-03"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    assert socio.center() == {"notifications": [], "unread": 0}

    assert cancelar(socio, reserva["id"]) == 200

    # Verifica: queda una entrada sin leer, de confirmación, con el texto del CU.
    center = socio.center()
    assert center["unread"] == 1
    [entrada] = center["notifications"]
    assert entrada["kind"] == "user_cancellation"
    assert entrada["title"] == "Booking cancelled"
    assert entrada["body"] == cuerpo_esperado(socio.venue, "21:00")
    assert entrada["read"] is False


def test_sin_permiso_de_notificaciones_no_se_envia_pero_la_confirmacion_queda_en_el_centro(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """sin permiso de notificaciones no llega el push pero la confirmación está en el centro @CU-24.3-H03-01"""
    socio = a_member(api, engine, sign_in, unique, permission=False)
    reserva = socio.book("21:00")

    assert cancelar(socio, reserva["id"]) == 200

    # Verifica: nada sale hacia el teléfono y la confirmación está en el centro.
    assert canal.sent == []
    [entrada] = socio.center()["notifications"]
    assert entrada["title"] == "Booking cancelled"


def test_si_la_cancelacion_falla_no_se_confirma_nada(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """si la cancelación falló, no recibe ninguna confirmación @CU-24.3-H04-01"""
    socio = a_member(api, engine, sign_in, unique)
    ajeno = a_member(api, engine, sign_in, unique)
    de_otro = ajeno.book("21:00")
    anulada = socio.book("20:00")
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE booking SET status = 'voided', reason = 'mantenimiento',"
                " canceled_at = now(), canceled_by = :u WHERE id = :id"
            ),
            {"u": socio.user_id, "id": anulada["id"]},
        )

    # Verifica: cancelar la de otra persona (404) o una que el club ya anuló (409) falla y
    # no deja confirmación para nadie.
    assert cancelar(socio, de_otro["id"]) == 404
    assert cancelar(socio, anulada["id"]) == 409
    assert canal.sent == []
    assert socio.center() == {"notifications": [], "unread": 0}
    assert ajeno.center() == {"notifications": [], "unread": 0}
