from collections.abc import Sequence
from datetime import UTC, datetime, timedelta
from uuid import UUID

import pytest

from app.modules.notifications import push
from app.modules.notifications.rules import (
    Delivery,
    Notice,
    Notification,
    Reminder,
    reminder_message,
    short_kind,
)
from app.modules.notifications.use_cases import (
    ChannelNotConfigured,
    DeliveryResult,
    PendingNotice,
    send_reminders,
)

AHORA = datetime(2026, 10, 1, 23, 0, tzinfo=UTC)


def _id(numero: int) -> UUID:
    return UUID(int=numero)


def _recordatorio(deporte: str = "Futbol", tipo: str = "F5", reserva_id: int = 7) -> Reminder:
    # 21:00 – 22:00 en la hora del club (UTC−3).
    inicio = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)
    return Reminder(
        _id(reserva_id), _id(3), inicio, inicio + timedelta(hours=1), deporte, tipo, "Sede Morón"
    )


class RepositorioEnMemoria:
    def __init__(self, pendientes: list[Reminder], tokens: list[str]) -> None:
        self.pendientes = pendientes
        self.tokens = tokens
        self.hay_dispositivos = True
        self.registrados: dict[UUID, Reminder] = {}
        self.envios: dict[UUID, Delivery] = {}
        self.bajas: list[str] = []

    def due(self, ahora: datetime, usuario_id: UUID | None) -> list[Reminder]:
        return list(self.pendientes)

    def register(self, reminder: Reminder, notice: Notice) -> UUID | None:
        if any(r.booking_id == reminder.booking_id for r in self.registrados.values()):
            return None
        nuevo = _id(len(self.registrados) + 1)
        self.registrados[nuevo] = reminder
        return nuevo

    def tokens_with_permission(self, usuario_id: UUID) -> list[str]:
        return list(self.tokens)

    def has_devices(self, usuario_id: UUID) -> bool:
        return self.hay_dispositivos

    def mark_delivery(self, notification_id: UUID, envio: Delivery) -> None:
        self.envios[notification_id] = envio

    def deactivate_tokens(self, tokens: Sequence[str]) -> None:
        self.bajas.extend(tokens)

    def take_next(self, usuario_id: UUID | None) -> PendingNotice | None:
        raise NotImplementedError

    def register_device(self, usuario_id: UUID, token: str, plataforma: str, permiso: bool) -> bool:
        raise NotImplementedError

    def unregister_device(self, usuario_id: UUID, token: str) -> None:
        raise NotImplementedError

    def of_user(self, usuario_id: UUID) -> tuple[list[Notification], int]:
        raise NotImplementedError

    def read(self, usuario_id: UUID, notification_id: UUID) -> bool:
        raise NotImplementedError

    def read_all(self, usuario_id: UUID) -> None:
        raise NotImplementedError


class CanalQueFalla:
    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        raise ConnectionError("el servicio no contesta")


class CanalQueRechaza:
    def __init__(self, invalidos: tuple[str, ...], enviados: int) -> None:
        self.invalidos = invalidos
        self.enviados = enviados

    def send(self, tokens: Sequence[str], notice: Notice) -> DeliveryResult:
        return DeliveryResult(sent=self.enviados, invalid=self.invalidos)


def test_el_mensaje_lleva_deporte_sede_y_horario_del_club() -> None:
    notice = reminder_message(_recordatorio())

    assert notice.title == "Tu reserva es en 1 hora"
    assert notice.body == "Fútbol 5 · Sede Morón · 21:00 – 22:00"
    assert notice.data == {"tipo": "recordatorio", "reserva_id": str(_id(7))}


@pytest.mark.parametrize(
    ("deporte", "tipo", "esperado"),
    [
        ("Futbol", "F11", "Fútbol 11"),
        ("Tenis", "PDL", "Tenis"),
        ("Hockey", "H7", "Hockey 7"),
        ("Padel", "PAD", "Pádel"),
        ("Rugby", "R15", "Rugby"),
    ],
)
def test_el_deporte_se_nombra_con_el_tipo_corto(deporte: str, tipo: str, esperado: str) -> None:
    """el aviso nombra el deporte con el tipo corto del catálogo @supuesto:CU-24.1-SUP-14"""
    assert short_kind(deporte, tipo) == esperado


def test_un_envio_que_falla_queda_fallido_sin_reintento_y_no_corta_el_barrido() -> None:
    """el backend no reintenta un envío fallido @supuesto:CU-24.1-SUP-02"""
    repo = RepositorioEnMemoria([_recordatorio(reserva_id=1), _recordatorio(reserva_id=2)], ["t"])

    registrados = send_reminders(repo, CanalQueFalla(), AHORA)

    assert registrados == 2
    assert repo.envios == {_id(1): "fallida", _id(2): "fallida"}


def test_un_token_que_el_servicio_rechaza_se_da_de_baja() -> None:
    """un token inválido se da de baja @supuesto:CU-24.1-SUP-02"""
    repo = RepositorioEnMemoria([_recordatorio()], ["bueno", "viejo"])

    send_reminders(repo, CanalQueRechaza(("viejo",), enviados=1), AHORA)

    assert repo.bajas == ["viejo"]
    assert repo.envios == {_id(1): "enviada"}


def test_si_el_servicio_no_acepta_ningun_dispositivo_el_envio_es_fallido() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], ["viejo"])

    send_reminders(repo, CanalQueRechaza(("viejo",), enviados=0), AHORA)

    assert repo.envios == {_id(1): "fallida"}


def test_sin_dispositivos_con_permiso_el_aviso_queda_sin_permiso() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], [])

    assert send_reminders(repo, CanalQueFalla(), AHORA) == 1
    assert repo.envios == {_id(1): "sin_permiso"}


def test_sin_ningun_dispositivo_registrado_el_aviso_queda_sin_canal() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], [])
    repo.hay_dispositivos = False

    assert send_reminders(repo, CanalQueFalla(), AHORA) == 1
    assert repo.envios == {_id(1): "sin_canal"}


def test_un_aviso_que_otro_barrido_ya_registro_no_se_envia_de_nuevo() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], ["t"])
    repo.register(_recordatorio(), reminder_message(_recordatorio()))

    assert send_reminders(repo, CanalQueFalla(), AHORA) == 0
    assert repo.envios == {}


def test_sin_credenciales_de_firebase_el_canal_no_sale_a_ninguna_red(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el push real va detrás de un puerto que por defecto no envía @supuesto:CU-24.1-SUP-06"""
    monkeypatch.delenv("GOOGLE_APPLICATION_CREDENTIALS", raising=False)
    push.push_channel.cache_clear()

    canal = push.push_channel()

    assert isinstance(canal, push.NullChannel)
    with pytest.raises(ChannelNotConfigured):
        canal.send(["t"], reminder_message(_recordatorio()))
    push.push_channel.cache_clear()


def test_sin_canal_configurado_el_aviso_no_figura_como_enviado() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], ["t"])

    assert send_reminders(repo, push.NullChannel(), AHORA) == 1
    assert repo.envios == {_id(1): "sin_canal"}
