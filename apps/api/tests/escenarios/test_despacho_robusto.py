"""Un aviso que falla al despacharse no traba a los otros ni corta el barrido."""

from collections.abc import Callable, Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_recordatorio import CanalDePrueba, Socio, un_socio

from app.aplicacion.notificaciones import despachar_pendientes
from app.infraestructura.notificaciones import NotificacionesSql
from app.infraestructura.push import canal_push
from app.interfaz import barrido


@pytest.fixture
def canal(api: TestClient) -> Iterator[CanalDePrueba]:
    canal = CanalDePrueba()
    api.app.dependency_overrides[canal_push] = lambda: canal
    yield canal
    api.app.dependency_overrides.pop(canal_push, None)


class FallaLaPrimeraVez(NotificacionesSql):
    """La base se cae justo al buscar los dispositivos del primer aviso."""

    llamadas = 0

    def tokens_con_permiso(self, usuario_id: int) -> list[str]:
        FallaLaPrimeraVez.llamadas += 1
        if FallaLaPrimeraVez.llamadas == 1:
            raise OSError("la base no contesta")
        return super().tokens_con_permiso(usuario_id)


def _tres_cancelaciones_pendientes(socio: Socio) -> None:
    for desde in ("20:00", "21:00", "22:00"):
        reserva = socio.reservar(desde)
        r = socio.api.post(f"/reservas/{reserva['id']}/cancelar", headers=socio.sesion)
        assert r.status_code == 200
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET envio = 'pendiente', enviada_en = NULL"
                " WHERE usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        )


def _envios(socio: Socio) -> list[str]:
    with socio.motor.connect() as conn:
        return [
            f.envio
            for f in conn.execute(
                text("SELECT envio FROM notificacion WHERE usuario_id = :u ORDER BY id"),
                {"u": socio.usuario_id},
            )
        ]


def test_un_fallo_en_el_primer_aviso_no_deja_el_resto_en_enviando(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
) -> None:
    """el aviso que falla queda fallido y los demás salen @supuesto:CU-24.3-SUP-04"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    _tres_cancelaciones_pendientes(socio)
    canal.enviados.clear()
    FallaLaPrimeraVez.llamadas = 0

    with motor.connect() as conn:
        despachados = despachar_pendientes(FallaLaPrimeraVez(conn), canal, socio.usuario_id)

    assert despachados == 3
    assert _envios(socio) == ["fallida", "enviada", "enviada"]
    assert len(canal.enviados) == 2


def test_si_el_despacho_de_pendientes_falla_los_recordatorios_salen_igual(
    monkeypatch: pytest.MonkeyPatch, motor: Engine
) -> None:
    """el barrido no corta los recordatorios por un aviso pendiente que falla"""
    corridos: list[str] = []

    def cae(*_: object, **__: object) -> int:
        raise OSError("la base no contesta")

    def recordatorios(*_: object, **__: object) -> int:
        corridos.append("recordatorios")
        return 0

    monkeypatch.setattr(barrido, "despachar_pendientes", cae)
    monkeypatch.setattr(barrido, "enviar_recordatorios", recordatorios)

    assert barrido.barrer_una_vez() == 0
    assert corridos == ["recordatorios"]
