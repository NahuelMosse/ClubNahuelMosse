import logging
from collections.abc import Sequence
from datetime import UTC, datetime
from typing import Any, cast
from uuid import UUID

import pytest

from app.modules.notificaciones import casos_de_uso
from app.modules.notificaciones.casos_de_uso import ResultadoDeEnvio, entregar, enviar_recordatorios
from app.modules.notificaciones.reglas import Aviso, Destinatario, Recordatorio
from app.shared.config import config
from app.shared.mensaje import Mensaje

DIRECCION = "ana@correo.com"
USUARIO = UUID(int=7)
AVISO = Aviso(
    titulo="El club canceló tu reserva",
    cuerpo="Fútbol 5 · Sede Morón · Mié 11, 20:00",
    datos={"tipo": "cancelacion_forzosa"},
)


class _Repositorio:
    def __init__(self, tokens: list[str], dispositivos: bool = False, nuevo: bool = True) -> None:
        self.tokens = tokens
        self.dispositivos = dispositivos
        self.nuevo = nuevo
        self.envios: list[str] = []

    def destinatario(self, usuario_id: UUID) -> Destinatario | None:
        return Destinatario(correo=DIRECCION, nombre="Ana")

    def tokens_con_permiso(self, usuario_id: UUID) -> list[str]:
        return self.tokens

    def tiene_dispositivos(self, usuario_id: UUID) -> bool:
        return self.dispositivos

    def marcar_envio(self, notificacion_id: UUID, envio: str) -> None:
        self.envios.append(envio)

    def dar_de_baja_tokens(self, tokens: Sequence[str]) -> None: ...

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
        return UUID(int=50) if self.nuevo else None


class _Canal:
    def __init__(self) -> None:
        self.avisos: list[Aviso] = []

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        self.avisos.append(aviso)
        return ResultadoDeEnvio(enviados=1)


def _entregar(repo: _Repositorio, canal: _Canal) -> None:
    entregar(cast(Any, repo), canal, UUID(int=1), USUARIO, AVISO)


def test_cada_notificacion_registrada_sale_tambien_por_correo_con_su_titulo_cuerpo_y_la_plantilla_de_la_app(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """cada notificación registrada sale también por correo con su título, cuerpo y la plantilla de la app
    @MAIL-03-S1 @assumption:MAIL-03-ASM-02"""
    enviados: list[Mensaje] = []
    monkeypatch.setattr(casos_de_uso, "enviar", enviados.append)
    monkeypatch.setattr(config, "url_publica", "https://club.example")
    canal = _Canal()

    _entregar(_Repositorio(["token"]), canal)

    assert len(canal.avisos) == 1
    assert len(enviados) == 1
    assert enviados[0].para == DIRECCION
    assert enviados[0].asunto == AVISO.titulo
    assert enviados[0].html is not None
    for texto in (AVISO.titulo, "Fútbol 5", "Abrir la app", 'href="https://club.example"'):
        assert texto in enviados[0].html
    assert AVISO.cuerpo in enviados[0].cuerpo

    enviados.clear()
    monkeypatch.setattr(config, "url_publica", "")
    _entregar(_Repositorio(["token"]), canal)
    assert enviados[0].html is not None
    assert "Abrir la app" not in enviados[0].html


def test_el_correo_sale_aunque_no_haya_push_y_si_falla_el_aviso_queda_como_estaba(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """el correo sale aunque no haya push y si falla el aviso queda como estaba
    @MAIL-03-S2"""
    enviados: list[Mensaje] = []
    monkeypatch.setattr(casos_de_uso, "enviar", enviados.append)
    repo = _Repositorio([])
    _entregar(repo, _Canal())
    assert len(enviados) == 1
    assert repo.envios == ["sin_canal"]

    def roto(mensaje: Mensaje) -> None:
        raise RuntimeError(f"no se pudo enviar a {mensaje.para}")

    monkeypatch.setattr(casos_de_uso, "enviar", roto)
    repo, canal = _Repositorio(["token"]), _Canal()
    with caplog.at_level(logging.WARNING):
        _entregar(repo, canal)
    assert repo.envios == ["enviada"]
    assert len(canal.avisos) == 1
    assert "RuntimeError" in caplog.text
    assert DIRECCION not in caplog.text


def test_el_recordatorio_manda_un_solo_correo(monkeypatch: pytest.MonkeyPatch) -> None:
    """el recordatorio manda un solo correo
    @assumption:MAIL-03-ASM-01"""
    enviados: list[Mensaje] = []
    monkeypatch.setattr(casos_de_uso, "enviar", enviados.append)

    registrados = enviar_recordatorios(
        cast(Any, _Repositorio(["token"])), _Canal(), datetime(2026, 10, 1, 20, 30, tzinfo=UTC)
    )

    assert registrados == 1
    assert len(enviados) == 1
    assert enviados[0].asunto == "Tu reserva es en 1 hora"


def test_un_aviso_que_no_se_registra_no_manda_correo(monkeypatch: pytest.MonkeyPatch) -> None:
    """un aviso que no se registra no manda correo
    @assumption:MAIL-03-ASM-03"""
    enviados: list[Mensaje] = []
    monkeypatch.setattr(casos_de_uso, "enviar", enviados.append)

    registrados = enviar_recordatorios(
        cast(Any, _Repositorio(["token"], nuevo=False)),
        _Canal(),
        datetime(2026, 10, 1, 20, 30, tzinfo=UTC),
    )

    assert registrados == 0
    assert enviados == []
