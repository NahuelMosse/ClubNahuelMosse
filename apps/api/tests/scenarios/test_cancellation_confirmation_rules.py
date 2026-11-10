"""Las reglas de la confirmación de cancelación que ningún escenario de la card ejercita."""

from collections.abc import Callable, Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, app_of, a_member

from app.modules.notifications.use_cases import dispatch_pending
from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.push import push_channel


class CanalCaido:
    def send(self, tokens: list[str], aviso: Any) -> Any:
        raise ConnectionError("el servicio no contesta")


@pytest.fixture
def canal(api: TestClient) -> Iterator[FakeChannel]:
    canal = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: canal
    yield canal
    app_of(api).dependency_overrides.pop(push_channel, None)


def _cancelar(socio: Member, reserva_id: str) -> int:
    return socio.api.post(f"/bookings/{reserva_id}/cancel", headers=socio.session).status_code


def _envios(socio: Member) -> list[str]:
    with socio.engine.connect() as conn:
        return [
            f.delivery
            for f in conn.execute(
                text("SELECT delivery FROM notification WHERE user_id = :u ORDER BY id"),
                {"u": socio.user_id},
            )
        ]


def test_repetir_la_cancelacion_no_repite_la_confirmacion(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """un reintento de la cancelación no duplica el aviso @supuesto:CU-24.3-SUP-02"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")

    assert _cancelar(socio, reserva["id"]) == 200
    assert _cancelar(socio, reserva["id"]) == 200

    assert len(canal.sent) == 1
    assert len(socio.center()["notifications"]) == 1


def test_cada_reserva_cancelada_tiene_su_confirmacion(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """varias cancelaciones seguidas dan una confirmación cada una @supuesto:CU-24.3-SUP-02"""
    socio = a_member(api, engine, sign_in, unique)
    primera = socio.book("20:00")
    segunda = socio.book("21:00")

    assert _cancelar(socio, primera["id"]) == 200
    assert _cancelar(socio, segunda["id"]) == 200

    assert len(canal.sent) == 2
    center = socio.center()
    assert center["unread"] == 2
    assert {n["booking_id"] for n in center["notifications"]} == {primera["id"], segunda["id"]}


def test_si_el_servicio_push_cae_la_confirmacion_queda_en_el_centro_como_fallida(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
) -> None:
    """el envío fallido no se reintenta y la cancelación sigue hecha @supuesto:CU-24.3-SUP-01"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    app_of(api).dependency_overrides[push_channel] = CanalCaido
    try:
        assert _cancelar(socio, reserva["id"]) == 200
    finally:
        app_of(api).dependency_overrides.pop(push_channel, None)

    assert _envios(socio) == ["failed"]
    assert len(socio.center()["notifications"]) == 1


def test_lo_que_quedo_pendiente_se_despacha_una_sola_vez(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """el barrido retoma lo que no salió y nadie lo manda dos veces @supuesto:CU-24.3-SUP-04"""
    socio = a_member(api, engine, sign_in, unique)
    reserva = socio.book("21:00")
    assert _cancelar(socio, reserva["id"]) == 200
    canal.sent.clear()
    # Como si el servidor se hubiera caído antes de despachar.
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE notification SET delivery = 'pending' WHERE user_id = :u"),
            {"u": socio.user_id},
        )

    with engine.connect() as conn:
        primero = dispatch_pending(NotificationsSql(conn), canal, socio.user_id)
    with engine.connect() as conn:
        segundo = dispatch_pending(NotificationsSql(conn), canal, socio.user_id)

    assert (primero, segundo) == (1, 0)
    assert len(canal.sent) == 1
    assert _envios(socio) == ["sent"]
