"""Un aviso que no salió queda a la vista de quien opera."""

import logging

import pytest
from sqlalchemy import Engine, text


class _CanalQueFalla:
    def send(self, tokens: list[str], aviso: object) -> object:
        raise ConnectionError("FCM no responde")


def test_un_aviso_que_no_salio_queda_a_la_vista(
    motor: Engine, caplog: pytest.LogCaptureFixture
) -> None:
    """un recordatorio que no salió queda a la vista de quien opera @REV-02-S4"""
    from app.modules.notifications.use_cases import dispatch_pending
    from app.modules.notifications.repository import NotificationsSql

    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio)"
                " SELECT id, 'cancelacion_forzosa', 'Cancelaron tu reserva', 'Fútbol 5',"
                " 'pendiente' FROM usuario WHERE activo LIMIT 1"
            )
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
