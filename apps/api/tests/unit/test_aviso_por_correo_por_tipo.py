"""Cada tipo de aviso sale por correo por su camino real, una vez."""

from collections.abc import Sequence
from datetime import UTC, datetime
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notificaciones import casos_de_uso
from app.modules.notificaciones.casos_de_uso import (
    ResultadoDeEnvio,
    despachar_pendientes,
    enviar_recordatorios,
)
from app.modules.notificaciones.reglas import (
    Aviso,
    Destinatario,
    Pendiente,
    Recordatorio,
    datos_del_aviso,
)
from app.shared.mensaje import Mensaje

USUARIO = UUID(int=7)
DIRECCION = "ana@correo.com"


class _Repositorio:
    def __init__(self, pendientes: list[Pendiente]) -> None:
        self.pendientes = pendientes

    def marcar_varados_fallidos(self, usuario_id: UUID | None) -> list[Any]:
        return []

    def tomar_siguiente(self, usuario_id: UUID | None) -> Pendiente | None:
        return self.pendientes.pop(0) if self.pendientes else None

    def destinatario(self, usuario_id: UUID) -> Destinatario | None:
        return Destinatario(correo=DIRECCION, nombre="Ana")

    def tokens_con_permiso(self, usuario_id: UUID) -> list[str]:
        return []

    def tiene_dispositivos(self, usuario_id: UUID) -> bool:
        return False

    def marcar_envio(self, notificacion_id: UUID, envio: str) -> None: ...

    def vencidos(self, ahora: datetime, usuario_id: UUID | None) -> list[Recordatorio]:
        inicio = datetime(2026, 10, 1, 21, 0, tzinfo=UTC)
        return [
            Recordatorio(
                reserva_id=UUID(int=3),
                usuario_id=USUARIO,
                inicio=inicio,
                fin=inicio.replace(hour=22),
                deporte="Futbol",
                tipo="F5",
                sede="Sede Morón",
                correo=DIRECCION,
                nombre="Ana",
            )
        ]

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> UUID | None:
        return UUID(int=50)


class _Canal:
    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        return ResultadoDeEnvio(enviados=len(tokens))


def _pendiente(numero: int, tipo: Any, titulo: str, reserva: UUID | None) -> Pendiente:
    aviso = Aviso(titulo=titulo, cuerpo="cuerpo " + titulo, datos=datos_del_aviso(tipo, reserva))
    return Pendiente(notificacion_id=UUID(int=numero), usuario_id=USUARIO, aviso=aviso)


def test_el_recordatorio_la_cancelacion_del_club_la_agrupada_y_la_propia_salen_por_correo(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el recordatorio, la cancelación del club, la agrupada y la propia salen cada una por
    correo @MAIL-03-S1"""
    enviados: list[Mensaje] = []
    monkeypatch.setattr(casos_de_uso, "enviar", enviados.append)

    ahora = datetime(2026, 10, 1, 20, 30, tzinfo=UTC)
    enviar_recordatorios(cast(Any, _Repositorio([])), _Canal(), ahora)
    pendientes = [
        _pendiente(1, "cancelacion_forzosa", "El club anuló tu reserva", UUID(int=3)),
        _pendiente(2, "cancelacion_forzosa", "El club anuló 3 reservas", None),
        _pendiente(3, "cancelacion_usuario", "Cancelaste tu reserva", UUID(int=4)),
    ]
    despachados = despachar_pendientes(cast(Any, _Repositorio(pendientes)), _Canal())

    assert despachados == 3
    assert [m.asunto for m in enviados] == [
        "Tu reserva es en 1 hora",
        "El club anuló tu reserva",
        "El club anuló 3 reservas",
        "Cancelaste tu reserva",
    ]
    assert {m.para for m in enviados} == {DIRECCION}
