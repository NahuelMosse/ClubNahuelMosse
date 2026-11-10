"""Un aviso que falla al despacharse no traba a los otros ni corta el barrido."""

from collections.abc import Callable, Iterator
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_reminder import FakeChannel, Member, app_of, a_member

from app.modules.notifications.use_cases import dispatch_pending
from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.push import push_channel
from app.modules.notifications import sweep


@pytest.fixture
def canal(api: TestClient) -> Iterator[FakeChannel]:
    canal = FakeChannel()
    app_of(api).dependency_overrides[push_channel] = lambda: canal
    yield canal
    app_of(api).dependency_overrides.pop(push_channel, None)


class FallaLaPrimeraVez(NotificationsSql):
    """La base se cae justo al buscar los dispositivos del primer aviso."""

    llamadas = 0

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        FallaLaPrimeraVez.llamadas += 1
        if FallaLaPrimeraVez.llamadas == 1:
            raise OSError("la base no contesta")
        return super().tokens_with_permission(user_id)


def _tres_cancelaciones_pendientes(socio: Member) -> None:
    for desde in ("20:00", "21:00", "22:00"):
        reserva = socio.book(desde)
        r = socio.api.post(f"/bookings/{reserva['id']}/cancel", headers=socio.session)
        assert r.status_code == 200
    with socio.engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE notification SET delivery = 'pending', sent_at = NULL"
                " WHERE user_id = :u"
            ),
            {"u": socio.user_id},
        )


def _envios(socio: Member) -> list[str]:
    with socio.engine.connect() as conn:
        return [
            f.delivery
            for f in conn.execute(
                text("SELECT delivery FROM notification WHERE user_id = :u ORDER BY id"),
                {"u": socio.user_id},
            )
        ]


def test_un_fallo_en_el_primer_aviso_no_deja_el_resto_en_enviando(
    api: TestClient,
    engine: Engine,
    sign_in: Callable[[str, str], str | None],
    unique: Callable[[], str],
    canal: FakeChannel,
) -> None:
    """el aviso que falla queda fallido y los demás salen @supuesto:CU-24.3-SUP-04"""
    socio = a_member(api, engine, sign_in, unique)
    _tres_cancelaciones_pendientes(socio)
    canal.sent.clear()
    FallaLaPrimeraVez.llamadas = 0

    with engine.connect() as conn:
        despachados = dispatch_pending(FallaLaPrimeraVez(conn), canal, socio.user_id)

    assert despachados == 3
    assert _envios(socio) == ["failed", "sent", "sent"]
    assert len(canal.sent) == 2


def test_si_el_despacho_de_pendientes_falla_los_recordatorios_salen_igual(
    monkeypatch: pytest.MonkeyPatch, engine: Engine
) -> None:
    """el barrido no corta los recordatorios por un aviso pendiente que falla"""
    corridos: list[str] = []

    def cae(*_: object, **__: object) -> int:
        raise OSError("la base no contesta")

    def recordatorios(*_: object, **__: object) -> int:
        corridos.append("recordatorios")
        return 0

    monkeypatch.setattr(sweep, "dispatch_pending", cae)
    monkeypatch.setattr(sweep, "send_reminders", recordatorios)

    assert sweep.sweep_once() == 0
    assert corridos == ["recordatorios"]
