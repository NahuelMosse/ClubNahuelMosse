"""El aviso de 5 minutos contra la base real."""

from collections.abc import Sequence
from datetime import datetime, timedelta
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from sqlalchemy.exc import IntegrityError

from app.modules.notificaciones.casos_de_uso import (
    ResultadoDeEnvio,
    despachar_pendientes,
    enviar_recordatorios,
)
from app.modules.notificaciones.reglas import Aviso
from app.modules.notificaciones.repositorio import NotificacionesSql
from tests.integracion.test_notificaciones_api import (
    _espacio,
    _manana_a_las,
    _registrar,
    _reservar,
    _yo,
)


class _Canal:
    def __init__(self) -> None:
        self.avisos: list[Aviso] = []

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        self.avisos.append(aviso)
        return ResultadoDeEnvio(enviados=len(tokens))


def _barrer(motor: Engine, usuario: UUID, canal: _Canal, ahora: datetime) -> int:
    with motor.connect() as conn:
        return enviar_recordatorios(NotificacionesSql(conn), canal, ahora, usuario)


def _cinco(motor: Engine, usuario: UUID) -> list[tuple[str, str]]:
    with motor.connect() as conn:
        filas = conn.execute(
            text(
                "SELECT titulo, envio FROM notificacion WHERE usuario_id = :u"
                " AND tipo = 'recordatorio_cinco'"
            ),
            {"u": usuario},
        ).all()
    return [(f.titulo, f.envio) for f in filas]


def _montar(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> tuple[UUID, UUID, datetime]:
    assert _registrar(api, token_usuario, f"fcm-{sede[0]}") == 204
    espacio = _espacio(api, token_admin, sede[0])
    reserva = _reservar(api, token_usuario, espacio)
    return _yo(api, motor, token_usuario), UUID(reserva["id"]), _manana_a_las(21)


def test_la_base_acepta_el_tipo_recordatorio_cinco_y_no_deja_dos_para_la_misma_reserva_y_horario(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
) -> None:
    """la base acepta el tipo recordatorio_cinco y no deja dos para la misma reserva y horario @assumption:NOT-05-ASM-01"""
    usuario, reserva, inicio = _montar(api, motor, token_admin, token_usuario, sede)
    insertar = text(
        "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id, reserva_inicio,"
        " envio) VALUES (:u, :t, 'x', 'y', :r, :i, 'pendiente')"
    )
    datos = {"u": usuario, "t": "recordatorio_cinco", "r": reserva, "i": inicio}
    with motor.begin() as conn:
        conn.execute(insertar, datos)
        conn.execute(insertar, datos | {"t": "recordatorio"})
    with pytest.raises(IntegrityError), motor.begin() as conn:
        conn.execute(insertar, datos)
    with pytest.raises(IntegrityError), motor.begin() as conn:
        conn.execute(insertar, datos | {"r": None})


def test_un_aviso_de_5_minutos_de_una_reserva_cancelada_antes_de_despacharlo_no_sale_y_queda_fallida(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
) -> None:
    """un aviso de 5 minutos de una reserva cancelada antes de despacharlo no sale y queda fallida @assumption:NOT-05-ASM-03"""
    usuario, reserva, inicio = _montar(api, motor, token_admin, token_usuario, sede)
    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, reserva_id,"
                " reserva_inicio, envio, creado_en) VALUES (:u, 'recordatorio_cinco', 'x', 'y',"
                " :r, :i, 'pendiente', now() - interval '5 minutes')"
            ),
            {"u": usuario, "r": reserva, "i": inicio},
        )
        conn.execute(text("UPDATE reserva SET estado = 'cancelada' WHERE id = :r"), {"r": reserva})
    canal = _Canal()
    with motor.connect() as conn:
        despachar_pendientes(NotificacionesSql(conn), canal, usuario)
    assert canal.avisos == []
    assert [e for _, e in _cinco(motor, usuario)] == ["fallida"]


def test_una_reserva_que_ya_empezo_o_creada_dentro_de_los_5_minutos_no_recibe_el_aviso_de_5_minutos(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
) -> None:
    """una reserva que ya empezó, o creada dentro de los 5 minutos, no recibe el aviso de 5 minutos @assumption:NOT-05-ASM-02"""
    usuario, reserva, inicio = _montar(api, motor, token_admin, token_usuario, sede)
    canal = _Canal()
    assert _barrer(motor, usuario, canal, inicio + timedelta(minutes=1)) == 0
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE reserva SET creado_en = :c WHERE id = :r"),
            {"c": inicio - timedelta(minutes=2), "r": reserva},
        )
    assert _barrer(motor, usuario, canal, inicio - timedelta(minutes=1)) == 0
    assert _cinco(motor, usuario) == []
    with motor.begin() as conn:
        conn.execute(text("UPDATE reserva SET creado_en = now() WHERE id = :r"), {"r": reserva})
    assert _barrer(motor, usuario, canal, inicio - timedelta(minutes=4)) == 1
    assert _barrer(motor, usuario, canal, inicio - timedelta(minutes=3)) == 0
    assert [t for t, _ in _cinco(motor, usuario)] == ["Tu reserva empieza en 5 minutos"]
