"""Las reglas de la confirmación de cancelación que ningún escenario de la card ejercita."""

from collections.abc import Callable, Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_recordatorio import CanalDePrueba, Socio, app_de, un_socio

from app.modules.notificaciones.casos_de_uso import despachar_pendientes
from app.modules.notificaciones.repositorio import NotificacionesSql
from app.modules.notificaciones.push import canal_push


class CanalCaido:
    def enviar(self, tokens: list[str], aviso: Any) -> Any:
        raise ConnectionError("el servicio no contesta")


@pytest.fixture
def canal(api: TestClient) -> Iterator[CanalDePrueba]:
    canal = CanalDePrueba()
    app_de(api).dependency_overrides[canal_push] = lambda: canal
    yield canal
    app_de(api).dependency_overrides.pop(canal_push, None)


def _cancelar(socio: Socio, reserva_id: int) -> int:
    return socio.api.post(f"/reservas/{reserva_id}/cancelar", headers=socio.sesion).status_code


def _envios(socio: Socio) -> list[str]:
    with socio.motor.connect() as conn:
        return [
            f.envio
            for f in conn.execute(
                text("SELECT envio FROM notificacion WHERE usuario_id = :u ORDER BY id"),
                {"u": socio.usuario_id},
            )
        ]


def test_repetir_la_cancelacion_no_repite_la_confirmacion(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """un reintento de la cancelación no duplica el aviso @supuesto:CU-24.3-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")

    assert _cancelar(socio, reserva["id"]) == 200
    assert _cancelar(socio, reserva["id"]) == 200

    assert len(canal.enviados) == 1
    assert len(socio.centro()["notificaciones"]) == 1


def test_cada_reserva_cancelada_tiene_su_confirmacion(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """varias cancelaciones seguidas dan una confirmación cada una @supuesto:CU-24.3-SUP-02"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    primera = socio.reservar("20:00")
    segunda = socio.reservar("21:00")

    assert _cancelar(socio, primera["id"]) == 200
    assert _cancelar(socio, segunda["id"]) == 200

    assert len(canal.enviados) == 2
    centro = socio.centro()
    assert centro["no_leidas"] == 2
    assert {n["reserva_id"] for n in centro["notificaciones"]} == {primera["id"], segunda["id"]}


def test_si_el_servicio_push_cae_la_confirmacion_queda_en_el_centro_como_fallida(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """el envío fallido no se reintenta y la cancelación sigue hecha @supuesto:CU-24.3-SUP-01"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    app_de(api).dependency_overrides[canal_push] = CanalCaido
    try:
        assert _cancelar(socio, reserva["id"]) == 200
    finally:
        app_de(api).dependency_overrides.pop(canal_push, None)

    assert _envios(socio) == ["fallida"]
    assert len(socio.centro()["notificaciones"]) == 1


def test_lo_que_quedo_pendiente_se_despacha_una_sola_vez(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """el barrido retoma lo que no salió y nadie lo manda dos veces @supuesto:CU-24.3-SUP-04"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")
    assert _cancelar(socio, reserva["id"]) == 200
    canal.enviados.clear()
    # Como si el servidor se hubiera caído antes de despachar.
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE notificacion SET envio = 'pendiente' WHERE usuario_id = :u"),
            {"u": socio.usuario_id},
        )

    with motor.connect() as conn:
        primero = despachar_pendientes(NotificacionesSql(conn), canal, socio.usuario_id)
    with motor.connect() as conn:
        segundo = despachar_pendientes(NotificacionesSql(conn), canal, socio.usuario_id)

    assert (primero, segundo) == (1, 0)
    assert len(canal.enviados) == 1
    assert _envios(socio) == ["enviada"]
