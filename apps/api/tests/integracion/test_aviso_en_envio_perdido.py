"""Un aviso que quedó `enviando` por una API caída pasa a fallida en el barrido."""

from collections.abc import Sequence
from uuid import UUID

from sqlalchemy import Engine, text

from app.modules.notifications.repository import NotificationsSql
from app.modules.notifications.rules import DeliveryResult, Notice
from app.modules.notifications.use_cases import dispatch_pending


class _CanalQueCuenta:
    def __init__(self) -> None:
        self.llamadas = 0

    def send(self, tokens: Sequence[str], aviso: Notice) -> DeliveryResult:
        self.llamadas += 1
        return DeliveryResult(sent=1, invalid=())


def _enviando(motor: Engine, minutos: int) -> UUID:
    with motor.begin() as conn:
        id_: UUID = conn.execute(
            text(
                "INSERT INTO notification (user_id, kind, title, body, delivery, sending_since)"
                " SELECT id, 'forced_cancellation', 'Cancelaron', 'Fútbol 5', 'sending',"
                " now() - make_interval(mins => :m) FROM app_user WHERE active LIMIT 1"
                " RETURNING id"
            ),
            {"m": minutos},
        ).scalar_one()
    return id_


def _envio(motor: Engine, id_: UUID) -> str:
    with motor.connect() as conn:
        envio: str = conn.execute(
            text("SELECT delivery FROM notification WHERE id = :id"), {"id": id_}
        ).scalar_one()
    return envio


def test_un_aviso_con_mas_de_10_minutos_en_enviando_pasa_a_fallida_y_no_se_reenvia(
    motor: Engine, token_usuario: str
) -> None:
    """un aviso con más de 10 minutos en enviando pasa a fallida en el barrido y no se reenvía @SIM-01-S2 @assumption:SIM-01-ASM-10"""
    viejo = _enviando(motor, 11)
    reciente = _enviando(motor, 1)
    canal = _CanalQueCuenta()
    with motor.connect() as conn:
        dispatch_pending(NotificationsSql(conn), canal)
    assert _envio(motor, viejo) == "failed"
    assert _envio(motor, reciente) == "sending"
    assert canal.llamadas == 0
