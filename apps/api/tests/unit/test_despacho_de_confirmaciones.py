from collections.abc import Sequence
from datetime import UTC, datetime
from uuid import UUID

import pytest

from app.modules.notificaciones.casos_de_uso import (
    Pendiente,
    ResultadoDeEnvio,
    despachar_pendientes,
)
from app.modules.notificaciones.reglas import (
    Aviso,
    AvisoPerdido,
    Envio,
    Notificacion,
    Recordatorio,
    mensaje_cancelacion,
)
from app.modules.reservas.reglas import Reserva


def _id(numero: int) -> UUID:
    return UUID(int=numero)


def _reserva(inicio: datetime) -> Reserva:
    return Reserva(
        id=_id(12),
        espacio_id=_id(1),
        sede_id=_id(1),
        espacio="Cancha 1",
        deporte="Futbol",
        tipo="F5",
        sede="Sede Ramos Mejía",
        direccion="Av. de Mayo 100",
        inicio=inicio,
        fin=inicio,
        precio_por_hora=38000,
        total=38000,
        estado="cancelada",
        motivo=None,
    )


class RepositorioEnMemoria:
    def __init__(self, pendientes: list[Pendiente], tokens: list[str]) -> None:
        self.pendientes = pendientes
        self.tokens = tokens
        self.hay_dispositivos = True
        self.envios: dict[UUID, Envio] = {}
        self.bajas: list[str] = []
        self.falla_en: UUID | None = None
        self.no_puede_marcar = False
        self.perdidos: list[AvisoPerdido] = []
        self.orden: list[str] = []

    def marcar_varados_fallidos(self, usuario_id: UUID | None) -> list[AvisoPerdido]:
        self.orden.append("marcar_varados_fallidos")
        return self.perdidos

    def tomar_siguiente(self, usuario_id: UUID | None) -> Pendiente | None:
        self.orden.append("tomar_siguiente")
        if not self.pendientes:
            return None
        siguiente = self.pendientes.pop(0)
        self.envios[siguiente.notificacion_id] = "enviando"
        return siguiente

    def tokens_con_permiso(self, usuario_id: UUID) -> list[str]:
        if self.falla_en == usuario_id:
            raise OSError("la base no contesta")
        return list(self.tokens)

    def tiene_dispositivos(self, usuario_id: UUID) -> bool:
        return self.hay_dispositivos

    def marcar_envio(self, notificacion_id: UUID, envio: Envio) -> None:
        if self.no_puede_marcar:
            raise OSError("la base no contesta")
        self.envios[notificacion_id] = envio

    def dar_de_baja_tokens(self, tokens: Sequence[str]) -> None:
        self.bajas.extend(tokens)

    def vencidos(self, ahora: datetime, usuario_id: UUID | None) -> list[Recordatorio]:
        raise NotImplementedError

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> UUID | None:
        raise NotImplementedError

    def registrar_dispositivo(
        self, usuario_id: UUID, token: str, plataforma: str, permiso: bool
    ) -> bool:
        raise NotImplementedError

    def baja_dispositivo(self, usuario_id: UUID, token: str) -> None:
        raise NotImplementedError

    def de_usuario(self, usuario_id: UUID) -> tuple[list[Notificacion], int]:
        raise NotImplementedError

    def leer(self, usuario_id: UUID, notificacion_id: UUID) -> bool:
        raise NotImplementedError

    def leer_todas(self, usuario_id: UUID) -> None:
        raise NotImplementedError


class CanalQueFalla:
    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        raise ConnectionError("el servicio no contesta")


class CanalQueAcepta:
    def __init__(self, invalidos: tuple[str, ...] = ()) -> None:
        self.invalidos = invalidos
        self.enviados: list[Aviso] = []

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        self.enviados.append(aviso)
        return ResultadoDeEnvio(
            enviados=len(tokens) - len(self.invalidos), invalidos=self.invalidos
        )


def _pendiente(numero: int) -> Pendiente:
    return Pendiente(
        _id(numero), _id(3), Aviso("Reserva cancelada", "cuerpo", {"tipo": "cancelacion_usuario"})
    )


def test_el_mensaje_nombra_la_reserva_con_el_dia_y_la_hora_del_club() -> None:
    """el día sale abreviado como en el prototipo @supuesto:CU-24.3-SUP-05"""
    aviso = mensaje_cancelacion(_reserva(datetime(2026, 11, 11, 23, 0, tzinfo=UTC)))

    assert aviso.titulo == "Reserva cancelada"
    assert aviso.cuerpo == (
        "Fútbol 5 · Sede Ramos Mejía · Mié 11, 20:00. El horario quedó liberado."
    )
    assert aviso.datos == {"tipo": "cancelacion_usuario", "reserva_id": str(_id(12))}


def test_sin_dispositivos_con_permiso_el_aviso_queda_sin_permiso() -> None:
    repo = RepositorioEnMemoria([_pendiente(1)], [])
    canal = CanalQueAcepta()

    assert despachar_pendientes(repo, canal) == 1

    assert repo.envios == {_id(1): "sin_permiso"}
    assert canal.enviados == []


def test_sin_ningun_dispositivo_registrado_el_aviso_queda_sin_canal() -> None:
    repo = RepositorioEnMemoria([_pendiente(1)], [])
    repo.hay_dispositivos = False

    assert despachar_pendientes(repo, CanalQueAcepta()) == 1

    assert repo.envios == {_id(1): "sin_canal"}


def test_un_envio_que_falla_queda_fallido_sin_reintento_y_no_corta_el_despacho() -> None:
    """el backend no reintenta un envío fallido @supuesto:CU-24.3-SUP-01"""
    repo = RepositorioEnMemoria([_pendiente(1), _pendiente(2)], ["t"])

    assert despachar_pendientes(repo, CanalQueFalla()) == 2

    assert repo.envios == {_id(1): "fallida", _id(2): "fallida"}


def test_un_token_rechazado_se_da_de_baja_y_el_aviso_sale_enviado() -> None:
    """un token inválido se da de baja @supuesto:CU-24.3-SUP-01"""
    repo = RepositorioEnMemoria([_pendiente(1)], ["bueno", "viejo"])

    despachar_pendientes(repo, CanalQueAcepta(invalidos=("viejo",)))

    assert repo.bajas == ["viejo"]
    assert repo.envios == {_id(1): "enviada"}


def test_un_despacho_no_repite_lo_que_otro_ya_tomó() -> None:
    """lo tomado queda reservado @supuesto:CU-24.3-SUP-04"""
    repo = RepositorioEnMemoria([_pendiente(1)], ["t"])
    canal = CanalQueAcepta()

    assert despachar_pendientes(repo, canal) == 1
    assert despachar_pendientes(repo, canal) == 0

    assert len(canal.enviados) == 1


def test_un_fallo_en_el_primer_aviso_lo_deja_fallido_y_no_traba_el_resto() -> None:
    """el aviso en curso pasa a fallido y los siguientes salen @supuesto:CU-24.3-SUP-04"""
    repo = RepositorioEnMemoria(
        [
            Pendiente(_id(1), _id(7), Aviso("t", "c", {"tipo": "cancelacion_usuario"})),
            _pendiente(2),
            _pendiente(3),
        ],
        ["t"],
    )
    repo.falla_en = _id(7)
    canal = CanalQueAcepta()

    assert despachar_pendientes(repo, canal) == 3

    assert repo.envios == {_id(1): "fallida", _id(2): "enviada", _id(3): "enviada"}
    assert len(canal.enviados) == 2


def test_cada_aviso_dado_por_fallido_queda_en_el_log_con_su_numero_y_su_tipo(
    caplog: pytest.LogCaptureFixture,
) -> None:
    """el aviso perdido se ve en el log como `aviso_sin_enviar` @REV-03-S5"""
    repo = RepositorioEnMemoria([], ["t"])
    repo.perdidos = [
        AvisoPerdido(_id(8), "cancelacion_forzosa"),
        AvisoPerdido(_id(9), "recordatorio"),
    ]

    with caplog.at_level("ERROR"):
        despachar_pendientes(repo, CanalQueAcepta())

    assert [(r.levelname, r.getMessage()) for r in caplog.records] == [
        ("ERROR", f"aviso_sin_enviar notificacion_id={_id(8)} tipo=cancelacion_forzosa"),
        ("ERROR", f"aviso_sin_enviar notificacion_id={_id(9)} tipo=recordatorio"),
    ]


def test_los_varados_se_dan_por_fallidos_antes_de_tomar_el_siguiente() -> None:
    repo = RepositorioEnMemoria([_pendiente(1)], ["t"])

    despachar_pendientes(repo, CanalQueAcepta())

    assert repo.orden[:2] == ["marcar_varados_fallidos", "tomar_siguiente"]


def test_lo_que_no_se_intento_sigue_pendiente_si_el_despacho_se_corta() -> None:
    """un despacho que se corta no deja avisos en `enviando` más allá del que estaba en curso"""
    repo = RepositorioEnMemoria([_pendiente(1), _pendiente(2)], ["t"])
    repo.falla_en = _id(3)
    repo.no_puede_marcar = True

    with pytest.raises(OSError):
        despachar_pendientes(repo, CanalQueAcepta())

    assert [p.notificacion_id for p in repo.pendientes] == [_id(2)]
