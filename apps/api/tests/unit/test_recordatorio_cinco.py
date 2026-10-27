from collections.abc import Sequence
from datetime import UTC, datetime, timedelta
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notificaciones import casos_de_uso
from app.modules.notificaciones.casos_de_uso import ResultadoDeEnvio, enviar_recordatorios
from app.modules.notificaciones.reglas import (
    ANTICIPACION_CINCO,
    Aviso,
    Destinatario,
    Recordatorio,
    mensaje_recordatorio,
)
from app.shared.mensaje import Mensaje

AHORA = datetime(2026, 10, 1, 23, 56, tzinfo=UTC)
INICIO = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)


def _cinco() -> Recordatorio:
    return Recordatorio(
        UUID(int=7),
        UUID(int=3),
        INICIO,
        INICIO + timedelta(hours=1),
        "Futbol",
        "F5",
        "Sede Morón",
        correo="ana@correo.com",
        nombre="Ana",
        clase="recordatorio_cinco",
    )


class _Repositorio:
    def __init__(self) -> None:
        self.registrados: list[Recordatorio] = []
        self.envios: list[str] = []

    def vencidos(self, ahora: datetime, usuario_id: UUID | None) -> list[Recordatorio]:
        return [_cinco(), _cinco()]

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> UUID | None:
        if self.registrados:
            return None
        self.registrados.append(recordatorio)
        return UUID(int=50)

    def destinatario(self, usuario_id: UUID) -> Destinatario | None:
        return None

    def tokens_con_permiso(self, usuario_id: UUID) -> list[str]:
        return ["token"]

    def marcar_envio(self, notificacion_id: UUID, envio: str) -> None:
        self.envios.append(envio)

    def dar_de_baja_tokens(self, tokens: Sequence[str]) -> None: ...


class _Canal:
    def __init__(self) -> None:
        self.avisos: list[Aviso] = []

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        self.avisos.append(aviso)
        return ResultadoDeEnvio(enviados=len(tokens))


def test_a_5_minutos_de_la_reserva_sale_un_aviso_por_push_y_por_correo_una_sola_vez(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """a 5 minutos de la reserva sale un aviso por push y por correo, una sola vez @NOT-05-S1"""
    correos: list[Mensaje] = []
    monkeypatch.setattr(casos_de_uso, "enviar", correos.append)
    repo, canal = _Repositorio(), _Canal()

    registrados = enviar_recordatorios(cast(Any, repo), canal, AHORA)

    assert registrados == 1
    assert [a.titulo for a in canal.avisos] == ["Tu reserva empieza en 5 minutos"]
    assert canal.avisos[0].cuerpo == "Fútbol 5 · Sede Morón · 21:00 – 22:00"
    assert canal.avisos[0].datos == {"tipo": "recordatorio_cinco", "reserva_id": str(UUID(int=7))}
    assert [c.asunto for c in correos] == ["Tu reserva empieza en 5 minutos"]
    assert repo.envios == ["enviada"]
    assert ANTICIPACION_CINCO == timedelta(minutes=5)


def test_el_aviso_de_una_hora_sigue_igual() -> None:
    una_hora = Recordatorio(UUID(int=7), UUID(int=3), INICIO, INICIO, "Futbol", "F5", "Sede")
    assert mensaje_recordatorio(una_hora).titulo == "Tu reserva es en 1 hora"
