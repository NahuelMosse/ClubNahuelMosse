from datetime import timedelta

import pytest

from app.dominio.notificaciones import (
    ESPERA_DEL_RECORDATORIO,
    INTENTOS_MAXIMOS,
    TOMA_VENCIDA,
    TipoDeAviso,
    que_hacer_con_varado,
)


def test_los_plazos_de_la_cola_son_los_que_se_acordaron() -> None:
    plazos = (TOMA_VENCIDA, ESPERA_DEL_RECORDATORIO, INTENTOS_MAXIMOS)

    assert plazos == (timedelta(minutes=5), timedelta(minutes=1), 3)


@pytest.mark.parametrize("tipo", ["cancelacion_forzosa", "cancelacion_usuario"])
@pytest.mark.parametrize("intentos", [0, 1, 2])
def test_un_aviso_de_cancelacion_varado_con_intentos_de_sobra_se_reintenta(
    tipo: TipoDeAviso, intentos: int
) -> None:
    assert que_hacer_con_varado(tipo, intentos) == "reintentar"


@pytest.mark.parametrize("tipo", ["cancelacion_forzosa", "cancelacion_usuario"])
@pytest.mark.parametrize("intentos", [3, 4, 10])
def test_un_aviso_de_cancelacion_que_agoto_sus_intentos_se_da_por_fallido(
    tipo: TipoDeAviso, intentos: int
) -> None:
    assert que_hacer_con_varado(tipo, intentos) == "dar_por_fallido"


@pytest.mark.parametrize("intentos", [0, 1, 2, 3])
def test_un_recordatorio_varado_nunca_se_repite(intentos: int) -> None:
    """CU-24.1: «Se envía una sola vez»: no se sabe si el primer envío salió."""
    assert que_hacer_con_varado("recordatorio", intentos) == "dar_por_fallido"
