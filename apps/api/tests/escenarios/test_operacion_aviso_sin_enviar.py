"""Un aviso que no salió queda a la vista de quien opera."""

import logging
from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


class _CanalQueFalla:
    def send(self, tokens: list[str], aviso: object) -> object:
        raise ConnectionError("FCM no responde")


def test_un_aviso_que_no_salio_queda_a_la_vista(
    api: TestClient,
    motor: Engine,
    unico: Callable[[], str],
    caplog: pytest.LogCaptureFixture,
) -> None:
    """un recordatorio que no salió queda a la vista de quien opera @REV-02-S4"""
    from app.modules.notifications.use_cases import dispatch_pending
    from app.modules.notifications.repository import NotificationsSql

    s = unico()
    api.post(
        "/registro",
        json={
            "nombre": "Martín",
            "apellido": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1994-07-21",
            "correo": f"socio.{s}@correo.com",
            "contrasena": "ClubNahuel1",
        },
    )
    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio)"
                " SELECT id, 'cancelacion_forzosa', 'Cancelaron tu reserva', 'Fútbol 5',"
                " 'pendiente' FROM usuario WHERE correo = :c AND activo"
            ),
            {"c": f"socio.{s}@correo.com"},
        )
        conn.execute(
            text(
                "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
                " SELECT usuario_id, 'fcm-' || id, 'android', true FROM notificacion"
                " WHERE envio = 'pendiente' ON CONFLICT DO NOTHING"
            )
        )

    with caplog.at_level(logging.INFO), motor.connect() as conn:
        dispatch_pending(NotificationsSql(conn), _CanalQueFalla())

    errores = [r for r in caplog.records if r.levelno >= logging.ERROR]
    assert any("aviso_sin_enviar" in r.getMessage() for r in errores)
    assert not any("fcm-" in r.getMessage() for r in caplog.records)
