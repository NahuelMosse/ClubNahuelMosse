"""La anticipación del recordatorio ya es una por clase de aviso (NOT-05), no una sola constante."""

# ruff: noqa: E501  (los títulos de las pruebas llevan su etiqueta y no se parten)
from datetime import timedelta
from uuid import UUID

import pytest
from sqlalchemy import Connection, Engine

from app.modules.notifications import repository
from app.modules.notifications.repository import NotificationsSql
from tests.escenarios.test_repositorios_propios import _hora, _mundo, _reserva


def test_el_recordatorio_sale_una_hora_antes(
    motor: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """el recordatorio sale una hora antes del inicio, con la anticipación de dominio @REV-06-S9 @assumption:REV-06-ASM-08"""
    mundo = _mundo(motor)
    base = _hora(dias=9)
    ahora = base - timedelta(minutes=50)
    creada = base - timedelta(days=30)
    cerca = _reserva(motor, mundo, base, creada=creada)
    lejos = _reserva(motor, mundo, base + timedelta(hours=1), creada=creada)

    def ids(conn: Connection) -> list[UUID]:
        return [r.booking_id for r in NotificationsSql(conn).due(ahora, mundo["usuario"])]

    with motor.connect() as conn:
        assert ids(conn) == [cerca]
    monkeypatch.setitem(repository.LEAD_TIME_BY_KIND, "recordatorio", timedelta(hours=2))
    with motor.connect() as conn:
        assert ids(conn) == [cerca, lejos]
