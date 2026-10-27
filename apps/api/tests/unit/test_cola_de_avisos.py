from datetime import timedelta

from app.dominio.notificaciones import ESPERA_DEL_RECORDATORIO


def test_un_recordatorio_recien_registrado_espera_un_minuto_antes_de_despacharse() -> None:
    assert timedelta(minutes=1) == ESPERA_DEL_RECORDATORIO
