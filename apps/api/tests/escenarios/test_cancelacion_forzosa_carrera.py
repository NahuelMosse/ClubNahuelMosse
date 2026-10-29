import threading
from collections.abc import Callable, Iterator, Sequence

import pytest
import test_cancelacion_forzosa as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine
from test_recordatorio import CanalDePrueba, app_de, un_socio

from app.modules.notifications.rules import Notice, DeliveryResult
from app.modules.notifications.push import push_channel

admin = base.admin


class CanalQueRetieneElPrimero(CanalDePrueba):
    """El primer envío queda en curso hasta que se lo suelta, como un push lento."""

    def __init__(self) -> None:
        super().__init__()
        self.saliendo = threading.Event()
        self.soltar = threading.Event()

    def send(self, tokens: Sequence[str], aviso: Notice) -> DeliveryResult:
        primero = not self.enviados
        resultado = super().send(tokens, aviso)
        if primero:
            self.saliendo.set()
            assert self.soltar.wait(timeout=30)
        return resultado


@pytest.fixture
def canal_lento(api: TestClient) -> Iterator[CanalQueRetieneElPrimero]:
    canal = CanalQueRetieneElPrimero()
    app_de(api).dependency_overrides[push_channel] = lambda: canal
    yield canal
    canal.soltar.set()
    app_de(api).dependency_overrides.pop(push_channel, None)


def test_la_anulacion_que_llega_con_el_aviso_anterior_saliendo_se_agrupa_igual(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal_lento: CanalQueRetieneElPrimero,
    admin: dict[str, str],
) -> None:
    """el despacho del primer aviso va lento y la segunda anulación igual llega en un solo
    aviso con la cantidad @supuesto:CU-24.2-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    primera = socio.reservar("20:00")
    segunda = socio.reservar("21:00")
    estados: list[int] = []
    hilo = threading.Thread(target=lambda: estados.append(base.anular(socio, admin, primera)))
    hilo.start()
    try:
        assert canal_lento.saliendo.wait(timeout=30)

        estados.append(base.anular(socio, admin, segunda))
    finally:
        canal_lento.soltar.set()
        hilo.join(timeout=30)

    assert estados == [200, 200]
    centro = socio.centro()
    assert centro["unread"] == 1
    assert [e["title"] for e in centro["notifications"]] == ["El club anuló 2 de tus reservas"]
