"""El aviso de 5 minutos contra la base real."""

from collections.abc import Sequence
from datetime import datetime, timedelta
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from sqlalchemy.exc import IntegrityError

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import Notice
from app.modules.notifications.use_cases import (
    DeliveryResult,
    dispatch_pending,
    send_reminders,
)
from tests.integration.test_notifications_api import (
    _book,
    _me,
    _register,
    _space,
    _tomorrow_at,
)


class _Canal:
    def __init__(self) -> None:
        self.avisos: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.avisos.append(notice)
        return DeliveryResult(sent=len(tokens))


def _barrer(engine: Engine, usuario: UUID, canal: _Canal, ahora: datetime) -> int:
    with engine.connect() as conn:
        return send_reminders(NotificationsSql(conn), canal, ahora, usuario)


def _cinco(engine: Engine, usuario: UUID) -> list[tuple[str, str]]:
    with engine.connect() as conn:
        filas = conn.execute(
            text(
                "SELECT title, delivery FROM notification WHERE user_id = :u"
                " AND kind = 'five_minute_reminder'"
            ),
            {"u": usuario},
        ).all()
    return [(f.title, f.delivery) for f in filas]


def _montar(
    api: TestClient, engine: Engine, admin_token: str, user_token: str, venue: tuple[str, str]
) -> tuple[UUID, UUID, datetime]:
    assert _register(api, user_token, f"fcm-{venue[0]}") == 204
    espacio = _space(api, admin_token, venue[0])
    reserva = _book(api, user_token, espacio)
    return _me(api, engine, user_token), UUID(reserva["id"]), _tomorrow_at(21)


def test_la_base_acepta_el_tipo_recordatorio_cinco_y_no_deja_dos_para_la_misma_reserva_y_horario(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """la base acepta el tipo recordatorio_cinco y no deja dos para la misma reserva y horario @assumption:NOT-05-ASM-01"""
    usuario, reserva, inicio = _montar(api, engine, admin_token, user_token, venue)
    insertar = text(
        "INSERT INTO notification (user_id, kind, title, body, booking_id, booking_starts_at,"
        " delivery) VALUES (:u, :t, 'x', 'y', :r, :i, 'pending')"
    )
    datos = {"u": usuario, "t": "five_minute_reminder", "r": reserva, "i": inicio}
    with engine.begin() as conn:
        conn.execute(insertar, datos)
        conn.execute(insertar, datos | {"t": "reminder"})
    with pytest.raises(IntegrityError), engine.begin() as conn:
        conn.execute(insertar, datos)
    with pytest.raises(IntegrityError), engine.begin() as conn:
        conn.execute(insertar, datos | {"r": None})


def test_un_aviso_de_5_minutos_de_una_reserva_cancelada_antes_de_despacharlo_no_sale_y_queda_fallida(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """un aviso de 5 minutos de una reserva cancelada antes de despacharlo no sale y queda fallida @assumption:NOT-05-ASM-03"""
    usuario, reserva, inicio = _montar(api, engine, admin_token, user_token, venue)
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notification (user_id, kind, title, body, booking_id,"
                " booking_starts_at, delivery, created_at) VALUES (:u, 'five_minute_reminder', 'x', 'y',"
                " :r, :i, 'pending', now() - interval '5 minutes')"
            ),
            {"u": usuario, "r": reserva, "i": inicio},
        )
        conn.execute(text("UPDATE booking SET status = 'canceled' WHERE id = :r"), {"r": reserva})
    canal = _Canal()
    with engine.connect() as conn:
        dispatch_pending(NotificationsSql(conn), canal, usuario)
    assert canal.avisos == []
    assert [e for _, e in _cinco(engine, usuario)] == ["failed"]


def test_una_reserva_que_ya_empezo_o_creada_dentro_de_los_5_minutos_no_recibe_el_aviso_de_5_minutos(
    api: TestClient,
    engine: Engine,
    admin_token: str,
    user_token: str,
    venue: tuple[str, str],
) -> None:
    """una reserva que ya empezó, o creada dentro de los 5 minutos, no recibe el aviso de 5 minutos @assumption:NOT-05-ASM-02"""
    usuario, reserva, inicio = _montar(api, engine, admin_token, user_token, venue)
    canal = _Canal()
    assert _barrer(engine, usuario, canal, inicio + timedelta(minutes=1)) == 0
    with engine.begin() as conn:
        # El disparador de auditoría pisa las fechas: se apaga sólo para fingir la reserva tardía.
        conn.execute(text("ALTER TABLE booking DISABLE TRIGGER booking_updated"))
        conn.execute(
            text("UPDATE booking SET created_at = :c, updated_at = :c WHERE id = :r"),
            {"c": inicio - timedelta(minutes=2), "r": reserva},
        )
        conn.execute(text("ALTER TABLE booking ENABLE TRIGGER booking_updated"))
    assert _barrer(engine, usuario, canal, inicio - timedelta(minutes=1)) == 0
    assert _cinco(engine, usuario) == []
    with engine.begin() as conn:
        conn.execute(text("ALTER TABLE booking DISABLE TRIGGER booking_updated"))
        conn.execute(
            text("UPDATE booking SET created_at = now(), updated_at = now() WHERE id = :r"),
            {"r": reserva},
        )
        conn.execute(text("ALTER TABLE booking ENABLE TRIGGER booking_updated"))
    # Con tiempo de sobra salen los dos avisos, el de una hora y el de 5 minutos, y ninguno repite.
    assert _barrer(engine, usuario, canal, inicio - timedelta(minutes=4)) == 2
    assert _barrer(engine, usuario, canal, inicio - timedelta(minutes=3)) == 0
    assert [t for t, _ in _cinco(engine, usuario)] == ["Your booking starts in 5 minutes"]
