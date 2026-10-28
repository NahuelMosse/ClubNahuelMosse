import json
import logging
from collections.abc import Sequence
from contextlib import contextmanager
from datetime import UTC, date, datetime, timedelta
from typing import Any, cast
from uuid import UUID

import pytest
from fastapi import BackgroundTasks

from app.modules.bookings import routes
from app.modules.bookings.rules import Booking
from app.modules.notifications.rules import Notice, Reminder
from app.modules.notifications.use_cases import DeliveryResult, send_reminders
from app.modules.password_recovery.rules import Message, Recipient
from app.modules.password_recovery.use_cases import request_link
from app.modules.session import Profile
from app.shared import email
from app.shared.config import config
from app.shared.email_template import html_email

BASE_LINK = "https://club.example"
ADDRESS = "ana@correo.com"


def _id(number: int) -> UUID:
    return UUID(int=number)


class _Links:
    def __init__(self, name: str = "Ana") -> None:
        self.name = name

    def recipient(self, email: str) -> Recipient:
        return Recipient(_id(1), self.name, ADDRESS)

    def issue(
        self, user_id: UUID, code_hash: str, validity_minutes: int, max_per_hour: int
    ) -> bool:
        return True


def _recovery(name: str = "Ana") -> Message:
    message = request_link(ADDRESS, BASE_LINK, cast(Any, _Links(name)))
    assert message is not None
    return message


def test_el_correo_de_recuperacion_sale_en_html_con_la_plantilla_el_saludo_el_boton_al_enlace_y_el_vencimiento() -> (
    None
):
    """el correo de recuperación sale en HTML con la plantilla, el saludo, el botón al enlace y el vencimiento
    @MAIL-02-S1 @assumption:MAIL-02-ASM-03"""
    html = _recovery().html

    assert html is not None
    for mark in ("#0A0A0B", "#141416", "#D4FF3D", "#A1A1AA", "CLUB NAHUEL MOSSE", "<table"):
        assert mark in html
    assert "<script" not in html
    assert "<img" not in html
    assert "Hola Ana" in html
    assert "Crear contraseña nueva" in html
    assert f'href="{BASE_LINK}/enlace/recuperar#codigo=' in html
    assert "30 minutos" in html
    assert "una sola vez" in html
    assert "ignorá" in html


def _booking(**changes: Any) -> Booking:
    starts_at = datetime(2026, 10, 28, 23, 0, tzinfo=UTC)  # 20:00 en el club
    data: dict[str, Any] = {
        "id": _id(9),
        "space_id": _id(2),
        "venue_id": _id(3),
        "space": "Cancha 1",
        "sport": "Futbol",
        "kind": "F5",
        "venue": "Sede Morón",
        "address": "Calle 1",
        "starts_at": starts_at,
        "ends_at": starts_at + timedelta(hours=1),
        "price_per_hour": 12000,
        "total": 12000,
        "status": "activa",
        "reason": None,
        "cancelable": True,
    }
    return Booking(**(data | changes))


def _profile(name: str = "Ana") -> Profile:
    return Profile(_id(1), "uid", name, "Pérez", ADDRESS, "usuario", "30111222", date(1990, 1, 1))


def _reminder(venue: str = "Sede Morón") -> Reminder:
    starts_at = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)
    return Reminder(
        _id(7),
        _id(1),
        starts_at,
        starts_at + timedelta(hours=1),
        "Futbol",
        "F5",
        venue,
        ADDRESS,
        "Ana",
    )


def test_cada_correo_sigue_llevando_su_texto_y_el_html_repite_el_enlace_del_boton() -> None:
    """cada correo sigue llevando su texto y el HTML repite el enlace del botón
    @MAIL-02-S2"""
    recovery = _recovery()
    link = recovery.body.split("\n")[3]
    assert link.startswith(BASE_LINK)
    assert recovery.html is not None
    assert recovery.html.count(link) >= 2
    assert "Crear contraseña nueva" not in recovery.body or link in recovery.body

    sent: list[Message] = []
    patch = pytest.MonkeyPatch()
    try:
        patch.setattr(routes, "send", sent.append)
        tasks = BackgroundTasks()
        patch.setattr(routes, "book", lambda *a, **k: _booking())
        routes.create_booking(
            routes.BookingRequest(
                espacio_id=cast(Any, _id(2)), fecha=date(2026, 10, 28), desde="20:00", horas=1
            ),
            _profile(),
            cast(Any, None),
            tasks,
        )
        _run(tasks)
    finally:
        patch.undo()
    from app.modules.notifications.rules import reminder_email

    for message in (*sent, reminder_email(_reminder())):
        assert message.body.strip()
        assert message.html is not None


def _run(tasks: BackgroundTasks) -> None:
    for task in tasks.tasks:
        task.func(*task.args, **task.kwargs)


def test_brevo_recibe_htmlcontent_solo_si_hay_html_smtp_la_alternativa_y_el_buzon_solo_el_texto(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Brevo recibe htmlContent sólo si hay HTML, SMTP la alternativa y el buzón sólo el texto
    @assumption:MAIL-02-ASM-01"""
    requests: list[dict[str, Any]] = []

    def fake_urlopen(request: Any, timeout: int) -> Any:
        requests.append(json.loads(request.data))

        @contextmanager
        def response() -> Any:
            yield None

        return response()

    monkeypatch.setattr("urllib.request.urlopen", fake_urlopen)
    monkeypatch.setattr(config, "brevo_api_key", "clave")
    monkeypatch.setattr(config, "email_sender", "club@correo.com")
    email._by_brevo(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    email._by_brevo(Message(ADDRESS, "Asunto", "texto"))
    assert requests[0]["htmlContent"] == "<p>hola</p>"
    assert requests[0]["textContent"] == "texto"
    assert "htmlContent" not in requests[1]

    sent: list[Any] = []

    class FakeSmtp:
        def __init__(self, *a: Any, **k: Any) -> None: ...
        def __enter__(self) -> "FakeSmtp":
            return self

        def __exit__(self, *a: Any) -> None: ...
        def starttls(self, **k: Any) -> None: ...
        def login(self, *a: Any) -> None: ...
        def send_message(self, message: Any) -> None:
            sent.append(message)

    monkeypatch.setattr("smtplib.SMTP", FakeSmtp)
    monkeypatch.setattr(config, "smtp_host", "smtp.example")
    email._by_smtp(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    email._by_smtp(Message(ADDRESS, "Asunto", "texto"))
    assert sent[0].get_body(("html",)).get_content().strip() == "<p>hola</p>"
    assert sent[1].get_body(("html",)) is None

    saved: list[dict[str, Any]] = []

    class FakeConnection:
        def execute(self, sql: Any, params: dict[str, Any]) -> None:
            saved.append(params)

    class FakeEngine:
        @contextmanager
        def begin(self) -> Any:
            yield FakeConnection()

    monkeypatch.setattr(email, "engine", lambda: FakeEngine())
    email._to_outbox(Message(ADDRESS, "Asunto", "texto", "<p>hola</p>"))
    assert saved == [{"p": ADDRESS, "a": "Asunto", "c": "texto"}]


def test_un_nombre_o_una_sede_con_marcado_salen_escapados_en_el_html() -> None:
    """un nombre o una sede con marcado salen escapados en el HTML
    @assumption:MAIL-02-ASM-02"""
    from app.modules.bookings.email import booking_email
    from app.modules.notifications.rules import reminder_email

    bad = "<b>x</b> & <script>"
    htmls = [
        _recovery(bad).html,
        booking_email(_profile(bad), _booking(venue=bad)).html,
        reminder_email(_reminder(bad)).html,
        html_email(bad, [bad], ("Ir", "https://x.test/?a=1&b=2"), bad),
    ]
    for html in htmls:
        assert html is not None
        assert "<b>x</b>" not in html
        assert "<script>" not in html
        assert "&lt;b&gt;x&lt;/b&gt;" in html or "&amp;" in html
    assert "a=1&amp;b=2" in str(htmls[3])


def test_al_hacer_una_reserva_sale_el_correo_de_confirmacion_con_deporte_sede_dia_horario_y_total(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """al hacer una reserva sale el correo de confirmación con deporte, sede, día, horario y total
    @MAIL-02-S3"""
    sent: list[Message] = []
    monkeypatch.setattr(routes, "send", sent.append)
    monkeypatch.setattr(routes, "book", lambda *a, **k: _booking())
    tasks = BackgroundTasks()
    response = routes.create_booking(
        routes.BookingRequest(
            espacio_id=cast(Any, _id(2)), fecha=date(2026, 10, 28), desde="20:00", horas=1
        ),
        _profile(),
        cast(Any, None),
        tasks,
    )
    assert not isinstance(response, type(None))
    assert sent == []  # sale después de responder

    _run(tasks)

    assert len(sent) == 1
    message = sent[0]
    assert message.recipient == ADDRESS
    assert message.subject == "Tu reserva está confirmada"
    for item in ("Fútbol 5", "Sede Morón", "miércoles 28 de octubre", "20:00", "21:00", "12.000"):
        assert item in message.body
        assert message.html is not None
        assert item in message.html


def test_si_el_correo_de_confirmacion_falla_la_reserva_responde_igual_y_queda_en_el_log_sin_la_direccion(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """si el correo de confirmación falla la reserva responde igual y queda en el log sin la dirección
    @assumption:MAIL-02-ASM-04"""
    monkeypatch.setattr(config, "email_mode", "brevo")

    def broken(*a: Any, **k: Any) -> None:
        raise ConnectionError(f"sin red hacia {ADDRESS}")

    monkeypatch.setattr("urllib.request.urlopen", broken)
    monkeypatch.setattr(routes, "book", lambda *a, **k: _booking())
    tasks = BackgroundTasks()
    response = routes.create_booking(
        routes.BookingRequest(
            espacio_id=cast(Any, _id(2)), fecha=date(2026, 10, 28), desde="20:00", horas=1
        ),
        _profile(),
        cast(Any, None),
        tasks,
    )
    assert getattr(response, "id", None) == _id(9)

    with caplog.at_level(logging.ERROR, logger="clubnahuelmosse.correo"):
        _run(tasks)

    assert "Tu reserva está confirmada" in caplog.text
    assert "ConnectionError" in caplog.text
    assert ADDRESS not in caplog.text


def test_modificar_cancelar_o_anular_no_mandan_correo(monkeypatch: pytest.MonkeyPatch) -> None:
    """modificar, cancelar o anular no mandan correo
    @assumption:MAIL-02-ASM-05"""
    sent: list[Message] = []
    monkeypatch.setattr(routes, "send", sent.append)
    monkeypatch.setattr(routes, "dispatch_for", lambda *a: None)
    monkeypatch.setattr(routes, "cancel_booking", lambda *a: _booking(status="cancelada"))
    monkeypatch.setattr(routes, "modify_booking", lambda *a: _booking())
    tasks = BackgroundTasks()
    routes.cancel(_profile(), cast(Any, None), _id(9), tasks, cast(Any, None))
    routes.modify(
        routes.BookingChangeRequest(
            espacio_id=cast(Any, _id(2)), fecha=date(2026, 10, 28), desde="20:00"
        ),
        _profile(),
        cast(Any, None),
        _id(9),
    )
    _run(tasks)
    assert sent == []


class _Repository:
    def __init__(self) -> None:
        self.registered: set[UUID] = set()

    def due(self, now: datetime, user_id: UUID | None) -> list[Reminder]:
        return [_reminder()]

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        if reminder.booking_id in self.registered:
            return None
        self.registered.add(reminder.booking_id)
        return _id(50)

    def tokens_with_permission(self, user_id: UUID) -> list[str]:
        return ["token"]

    def mark_delivery(self, notification_id: UUID, delivery: str) -> None: ...

    def deactivate_tokens(self, tokens: Sequence[str]) -> None: ...


class _Channel:
    def __init__(self) -> None:
        self.notices: list[Notice] = []

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        self.notices.append(notice)
        return DeliveryResult(sent=1)


def test_el_recordatorio_de_una_hora_antes_sale_por_push_y_por_correo_una_sola_vez(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el recordatorio de una hora antes sale por push y por correo, una sola vez
    @MAIL-02-S4"""
    from app.modules.notifications import use_cases

    sent: list[Message] = []
    monkeypatch.setattr(use_cases, "send", sent.append)
    repo, channel = _Repository(), _Channel()
    now = datetime(2026, 10, 1, 23, 0, tzinfo=UTC)

    assert send_reminders(cast(Any, repo), channel, now) == 1
    assert send_reminders(cast(Any, repo), channel, now) == 0

    assert len(channel.notices) == 1
    assert len(sent) == 1
    assert sent[0].recipient == ADDRESS
    assert sent[0].subject == "Tu reserva es en 1 hora"
    assert sent[0].html is not None
    for item in ("Fútbol 5", "Sede Morón", "21:00", "22:00"):
        assert item in sent[0].body
        assert item in sent[0].html


def test_si_el_correo_del_recordatorio_falla_el_push_sale_igual(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """si el correo del recordatorio falla el push sale igual
    @assumption:MAIL-02-ASM-04"""
    from app.modules.notifications import use_cases

    def broken(message: Message) -> None:
        raise RuntimeError(f"no se pudo enviar a {message.recipient}")

    monkeypatch.setattr(use_cases, "send", broken)
    channel = _Channel()
    with caplog.at_level(logging.WARNING):
        registered = send_reminders(
            cast(Any, _Repository()), channel, datetime(2026, 10, 1, 23, 0, tzinfo=UTC)
        )

    assert registered == 1
    assert len(channel.notices) == 1
    assert "RuntimeError" in caplog.text
    assert ADDRESS not in caplog.text
