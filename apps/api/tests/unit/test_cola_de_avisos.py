from datetime import timedelta

from app.modules.notifications.rules import REMINDER_GRACE


def test_un_recordatorio_recien_registrado_espera_un_minuto_antes_de_despacharse() -> None:
    assert timedelta(minutes=1) == REMINDER_GRACE
