"""La cancelación y su confirmación se confirman juntas o no se confirman."""

from collections.abc import Callable, Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from test_recordatorio import CanalDePrueba, app_de, un_socio

from app.modules.notifications.push import push_channel


@pytest.fixture
def canal(api: TestClient) -> Iterator[CanalDePrueba]:
    canal = CanalDePrueba()
    app_de(api).dependency_overrides[push_channel] = lambda: canal
    yield canal
    app_de(api).dependency_overrides.pop(push_channel, None)


@pytest.fixture
def aviso_que_falla(motor: Engine) -> Iterator[None]:
    """Hace fallar el INSERT de la confirmación, que corre después del UPDATE de la reserva."""
    with motor.begin() as conn:
        conn.execute(
            text(
                "CREATE FUNCTION falla_la_confirmacion() RETURNS trigger LANGUAGE plpgsql AS"
                " $$ BEGIN RAISE EXCEPTION 'falla el aviso'; END $$"
            )
        )
        conn.execute(
            text(
                "CREATE TRIGGER falla_la_confirmacion BEFORE INSERT ON notification"
                " FOR EACH ROW WHEN (NEW.kind = 'user_cancellation')"
                " EXECUTE FUNCTION falla_la_confirmacion()"
            )
        )
    yield
    with motor.begin() as conn:
        conn.execute(text("DROP TRIGGER falla_la_confirmacion ON notification"))
        conn.execute(text("DROP FUNCTION falla_la_confirmacion()"))


def test_si_falla_el_aviso_la_reserva_sigue_activa_y_no_queda_ningun_aviso(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    canal: CanalDePrueba,
    aviso_que_falla: None,
) -> None:
    """una cancelación cuyo aviso no se registra no se confirma @supuesto:CU-24.3-SUP-04"""
    socio = un_socio(api, motor, iniciar_sesion, unico)
    reserva = socio.reservar("21:00")

    try:
        respuesta = api.post(f"/bookings/{reserva['id']}/cancel", headers=socio.sesion)
        assert respuesta.status_code >= 500
    except Exception as e:
        # El cliente de pruebas propaga el error del servidor en vez de responder 500.
        assert "falla el aviso" in str(e)

    with motor.connect() as conn:
        estado: Any = conn.execute(
            text("SELECT status FROM booking WHERE id = :id"), {"id": reserva["id"]}
        ).scalar_one()
        avisos: Any = conn.execute(
            text("SELECT count(*) FROM notification WHERE user_id = :u"),
            {"u": socio.usuario_id},
        ).scalar_one()
    assert (estado, avisos) == ("active", 0)
    assert canal.enviados == []
