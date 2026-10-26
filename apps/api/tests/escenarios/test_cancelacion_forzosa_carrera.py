import threading
from collections.abc import Callable, Iterator, Sequence

import pytest
import test_cancelacion_forzosa as base
from fastapi.testclient import TestClient
from sqlalchemy import Engine
from test_recordatorio import CanalDePrueba, app_de, un_socio

from app.modules.notificaciones.reglas import Aviso, ResultadoDeEnvio
from app.modules.notificaciones.push import canal_push

admin = base.admin


class CanalQueRetieneElPrimero(CanalDePrueba):
    """El primer envío queda en curso hasta que se lo suelta, como un push lento."""

    def __init__(self) -> None:
        super().__init__()
        self.saliendo = threading.Event()
        self.soltar = threading.Event()

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        primero = not self.enviados
        resultado = super().enviar(tokens, aviso)
        if primero:
            self.saliendo.set()
            assert self.soltar.wait(timeout=30)
        return resultado


@pytest.fixture
def canal_lento(api: TestClient) -> Iterator[CanalQueRetieneElPrimero]:
    canal = CanalQueRetieneElPrimero()
    app_de(api).dependency_overrides[canal_push] = lambda: canal
    yield canal
    canal.soltar.set()
    app_de(api).dependency_overrides.pop(canal_push, None)


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
    assert centro["no_leidas"] == 1
    assert [e["titulo"] for e in centro["notificaciones"]] == ["El club anuló 2 de tus reservas"]
