from collections.abc import Sequence
from datetime import UTC, datetime, timedelta

import pytest

from app.modules.notificaciones.casos_de_uso import CanalNoConfigurado, Pendiente, ResultadoDeEnvio, enviar_recordatorios
from app.modules.notificaciones.reglas import Aviso, Envio, Notificacion, Recordatorio, mensaje_recordatorio, tipo_corto
from app.modules.notificaciones import push

AHORA = datetime(2026, 10, 1, 23, 0, tzinfo=UTC)


def _recordatorio(deporte: str = "Futbol", tipo: str = "F5", reserva_id: int = 7) -> Recordatorio:
    # 21:00 – 22:00 en la hora del club (UTC−3).
    inicio = datetime(2026, 10, 2, 0, 0, tzinfo=UTC)
    return Recordatorio(
        reserva_id, 3, inicio, inicio + timedelta(hours=1), deporte, tipo, "Sede Morón"
    )


class RepositorioEnMemoria:
    def __init__(self, pendientes: list[Recordatorio], tokens: list[str]) -> None:
        self.pendientes = pendientes
        self.tokens = tokens
        self.hay_dispositivos = True
        self.registrados: dict[int, Recordatorio] = {}
        self.envios: dict[int, Envio] = {}
        self.bajas: list[str] = []

    def vencidos(self, ahora: datetime, usuario_id: int | None) -> list[Recordatorio]:
        return list(self.pendientes)

    def registrar(self, recordatorio: Recordatorio, aviso: Aviso) -> int | None:
        if any(r.reserva_id == recordatorio.reserva_id for r in self.registrados.values()):
            return None
        nuevo = len(self.registrados) + 1
        self.registrados[nuevo] = recordatorio
        return nuevo

    def tokens_con_permiso(self, usuario_id: int) -> list[str]:
        return list(self.tokens)

    def tiene_dispositivos(self, usuario_id: int) -> bool:
        return self.hay_dispositivos

    def marcar_envio(self, notificacion_id: int, envio: Envio) -> None:
        self.envios[notificacion_id] = envio

    def dar_de_baja_tokens(self, tokens: Sequence[str]) -> None:
        self.bajas.extend(tokens)

    def tomar_siguiente(self, usuario_id: int | None) -> Pendiente | None:
        raise NotImplementedError

    def registrar_dispositivo(
        self, usuario_id: int, token: str, plataforma: str, permiso: bool
    ) -> bool:
        raise NotImplementedError

    def baja_dispositivo(self, usuario_id: int, token: str) -> None:
        raise NotImplementedError

    def de_usuario(self, usuario_id: int) -> tuple[list[Notificacion], int]:
        raise NotImplementedError

    def leer(self, usuario_id: int, notificacion_id: int) -> bool:
        raise NotImplementedError

    def leer_todas(self, usuario_id: int) -> None:
        raise NotImplementedError


class CanalQueFalla:
    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        raise ConnectionError("el servicio no contesta")


class CanalQueRechaza:
    def __init__(self, invalidos: tuple[str, ...], enviados: int) -> None:
        self.invalidos = invalidos
        self.enviados = enviados

    def enviar(self, tokens: Sequence[str], aviso: Aviso) -> ResultadoDeEnvio:
        return ResultadoDeEnvio(enviados=self.enviados, invalidos=self.invalidos)


def test_el_mensaje_lleva_deporte_sede_y_horario_del_club() -> None:
    aviso = mensaje_recordatorio(_recordatorio())

    assert aviso.titulo == "Tu reserva es en 1 hora"
    assert aviso.cuerpo == "Fútbol 5 · Sede Morón · 21:00 – 22:00"
    assert aviso.datos == {"tipo": "recordatorio", "reserva_id": "7"}


@pytest.mark.parametrize(
    ("deporte", "tipo", "esperado"),
    [
        ("Futbol", "F11", "Fútbol 11"),
        ("Tenis", "PDL", "Tenis"),
        ("Hockey", "H7", "Hockey 7"),
        ("Padel", "PAD", "Pádel"),
        ("Rugby", "R15", "Rugby"),
    ],
)
def test_el_deporte_se_nombra_con_el_tipo_corto(deporte: str, tipo: str, esperado: str) -> None:
    """el aviso nombra el deporte con el tipo corto del catálogo @supuesto:CU-24.1-SUP-14"""
    assert tipo_corto(deporte, tipo) == esperado


def test_un_envio_que_falla_queda_fallido_sin_reintento_y_no_corta_el_barrido() -> None:
    """el backend no reintenta un envío fallido @supuesto:CU-24.1-SUP-02"""
    repo = RepositorioEnMemoria([_recordatorio(reserva_id=1), _recordatorio(reserva_id=2)], ["t"])

    registrados = enviar_recordatorios(repo, CanalQueFalla(), AHORA)

    assert registrados == 2
    assert repo.envios == {1: "fallida", 2: "fallida"}


def test_un_token_que_el_servicio_rechaza_se_da_de_baja() -> None:
    """un token inválido se da de baja @supuesto:CU-24.1-SUP-02"""
    repo = RepositorioEnMemoria([_recordatorio()], ["bueno", "viejo"])

    enviar_recordatorios(repo, CanalQueRechaza(("viejo",), enviados=1), AHORA)

    assert repo.bajas == ["viejo"]
    assert repo.envios == {1: "enviada"}


def test_si_el_servicio_no_acepta_ningun_dispositivo_el_envio_es_fallido() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], ["viejo"])

    enviar_recordatorios(repo, CanalQueRechaza(("viejo",), enviados=0), AHORA)

    assert repo.envios == {1: "fallida"}


def test_sin_dispositivos_con_permiso_el_aviso_queda_sin_permiso() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], [])

    assert enviar_recordatorios(repo, CanalQueFalla(), AHORA) == 1
    assert repo.envios == {1: "sin_permiso"}


def test_sin_ningun_dispositivo_registrado_el_aviso_queda_sin_canal() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], [])
    repo.hay_dispositivos = False

    assert enviar_recordatorios(repo, CanalQueFalla(), AHORA) == 1
    assert repo.envios == {1: "sin_canal"}


def test_un_aviso_que_otro_barrido_ya_registro_no_se_envia_de_nuevo() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], ["t"])
    repo.registrar(_recordatorio(), mensaje_recordatorio(_recordatorio()))

    assert enviar_recordatorios(repo, CanalQueFalla(), AHORA) == 0
    assert repo.envios == {}


def test_sin_credenciales_de_firebase_el_canal_no_sale_a_ninguna_red(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """el push real va detrás de un puerto que por defecto no envía @supuesto:CU-24.1-SUP-06"""
    monkeypatch.delenv("GOOGLE_APPLICATION_CREDENTIALS", raising=False)
    push.canal_push.cache_clear()

    canal = push.canal_push()

    assert isinstance(canal, push.CanalNulo)
    with pytest.raises(CanalNoConfigurado):
        canal.enviar(["t"], mensaje_recordatorio(_recordatorio()))
    push.canal_push.cache_clear()


def test_sin_canal_configurado_el_aviso_no_figura_como_enviado() -> None:
    repo = RepositorioEnMemoria([_recordatorio()], ["t"])

    assert enviar_recordatorios(repo, push.CanalNulo(), AHORA) == 1
    assert repo.envios == {1: "sin_canal"}
