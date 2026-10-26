"""Un aviso que quedó `enviando` por una API caída pasa a fallida en el barrido."""

from collections.abc import Sequence

from sqlalchemy import Engine, text

from app.aplicacion.notificaciones import despachar_pendientes
from app.dominio.notificaciones import Aviso, ResultadoDeEnvio
from app.infraestructura.notificaciones import NotificacionesSql


class _CanalQueCuenta:
    def __init__(self) -> None:
        self.llamadas = 0

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        self.llamadas += 1
        return ResultadoDeEnvio(enviados=1, invalidos=[])


def _enviando(motor: Engine, minutos: int) -> int:
    with motor.begin() as conn:
        id_: int = conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio, enviando_desde)"
                " SELECT id, 'cancelacion_forzosa', 'Cancelaron', 'Fútbol 5', 'enviando',"
                " now() - make_interval(mins => :m) FROM usuario WHERE activo LIMIT 1"
                " RETURNING id"
            ),
            {"m": minutos},
        ).scalar_one()
    return id_


def _envio(motor: Engine, id_: int) -> str:
    with motor.connect() as conn:
        envio: str = conn.execute(
            text("SELECT envio FROM notificacion WHERE id = :id"), {"id": id_}
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
        despachar_pendientes(NotificacionesSql(conn), canal)
    assert _envio(motor, viejo) == "fallida"
    assert _envio(motor, reciente) == "enviando"
    assert canal.llamadas == 0
